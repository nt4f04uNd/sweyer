import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sweyer/sweyer.dart';

import '../test.dart';

/// Comparison of JSON serialization vs `sqflite`
///
/// Results - JSON absolutely kills SQL (tested with `sqflite 2.0.0+3`):
/// 
/// ```
/// 00:00 +0: sql
/// 0. 437
/// 1. 282
/// 2. 343
/// 3. 308
/// 4. 231
/// 5. 270
/// 6. 267
/// 7. 266
/// 8. 252
/// 9. 212
/// 00:03 +1: json
/// 0. 80
/// 1. 18
/// 2. 16
/// 3. 12
/// 4. 12
/// 5. 10
/// 6. 10
/// 7. 11
/// 8. 12
/// 9. 11
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final songs = List.generate(1000, (index) => songWith(id: index));

  testWidgets('sql', (_) async {
    final db = SongsDatabase.instance;
    final table = await db.table;
    for (int i = 0; i < 10; i++) {
      final s = Stopwatch();
      s.start();
      await table.insertAll(songs.map((el) => SqlSong.fromSong(el)).toList());
      print('$i. ${s.elapsedMilliseconds}');
    }
  });

  testWidgets('json', (_) async {
    const serializer = QueueSerializer('test.json');
    for (int i = 0; i < 10; i++) {
      final s = Stopwatch();
      s.start();
      await serializer.save(songs);
      print('$i. ${s.elapsedMilliseconds}');
    }
  });
}

class SongsDatabase {
  SongsDatabase._() { _database; }
  static final SongsDatabase instance = SongsDatabase._();

  // Names
  static const _DATABASE = 'TEST.db';
  static const TABLE = 'TEST';

  Completer<Database>? _completer;
  Future<Database> get _database async {
    if (_completer != null)
      return _completer!.future;
    _completer = Completer();
    await openDatabase(
      join(await getDatabasesPath(), _DATABASE),
      onCreate: (database, version) {
        database.execute('CREATE TABLE $TABLE(id INTEGER PRIMARY KEY, origin_type TEXT, origin_id INTEGER)');
      },
      onDowngrade: (database, oldVersion, newVersion) {},
      onUpgrade: (database, oldVersion, newVersion) {},
      onOpen: (database) {
        _completer!.complete(database);
      },
      version: 1,
    );
    return _completer!.future;
  }
  
  /// Table of all songs.
  ///
  /// Named with [TABLE].
  /// Introduced in version `1`.
  Future<Table<SqlSong>> get table async => Table(
    name: TABLE, 
    database: await _database,
    factory: (data) => SqlSong.fromMap(data),
  );
}

class Table<T extends SqlSong> {
  Table({
    required this.name,
    required Database database,
    required this.factory,
  }) : _database = database;

  /// Table name.
  final String name;

  /// Database instance.
  final Database _database;

  /// Recieves map of data and should create an item from it.
  final T Function(Map<String, Object?> data) factory;

  Future<List<T>> queryAll() async {
    return (await _database.query(name))
        .map(factory)
        .toList();
  }

  Future<void> insert(T item, { ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace }) async {
    await _database.insert(
      name,
      item.toMap(),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<void> insertAll(List<T> items) async {
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(name, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<void> update(T item, { ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace }) async {
    await _database.update(
      name,
      item.toMap(),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<void> delete(T item) async {
    await _database.delete(
      name,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}

class SqlSong {
  SqlSong({
    required this.id,
    required this.origin,
  })  : assert(() {
          if (origin is Album) {
            return true;
          }
          throw UnimplementedError();
        }());

  factory SqlSong.fromSong(Song song) {
    return SqlSong(
      id: song.id,
      origin: song.origin,
    );
  }

  final int id;
  final SongOrigin? origin;

  Map<String, dynamic> toMap() {
    return {
      'id':id,
      if (origin != null)
        'origin_type': 'album',
      if (origin != null)
        'origin_id': origin!.id,
    };
  }

  factory SqlSong.fromMap(Map<String, dynamic> map) {
    final originType = map['origin_type'];
    PersistentQueue? origin;
    assert(originType == 'album');
    if (originType == 'album') {
      origin = ContentControl.instance.state.albums[map['origin_id']];
    }
    return SqlSong(
      id: map['id'],
      origin: origin,
    );
  }
}
