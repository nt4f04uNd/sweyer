import 'package:flutter/material.dart';

import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  testWidgets('tabs - can switch with swipe', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Songs tab
      expect(find.byType(SongTile), findsOneWidget);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Albums tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsOneWidget);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Playlists tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsOneWidget);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Artists tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsOneWidget);
    });
  });

  testWidgets('tabs - can switch with buttons', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Start from songs tab
      expect(find.byType(SongTile), findsOneWidget);

      // Switch to albums tab
      await tester.tap(find.byIcon(Album.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsOneWidget);

      // Switch to playlists tab
      await tester.tap(find.byIcon(Playlist.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsOneWidget);

      // Switch to artists tab
      await tester.tap(find.byIcon(Artist.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<ArtistTile>()), findsOneWidget);

      // Switch back to songs tab
      await tester.tap(find.byIcon(Song.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<SongTile>()), findsOneWidget);
    });
  });

  testWidgets('sort order button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0, dateModified: 2),
      songWith(id: 1, dateModified: 1),
      songWith(id: 2, dateModified: 0),
    ]);
    await tester.runAsync(() async {
      await setUpAppTest(() {
        FakeContentChannel.instance.songs = songs.toList();
      });
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);

      // Change sort order
      await tester.tap(find.byIcon(Icons.south_rounded));
      await tester.pump();
      tester.expectSongTiles(songs.reversed);
    });
  });

  testWidgets('sort feature button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0, dateModified: 2, title: 'c'),
      songWith(id: 1, dateModified: 1, title: 'b'),
      songWith(id: 2, dateModified: 0, title: 'a'),
    ]);
    await tester.runAsync(() async {
      await setUpAppTest(() {
        FakeContentChannel.instance.songs = songs.toList();
      });
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);

      // Change sort feature
      await tester.tap(find.text(l10n.sortFeature<Song>(SongSortFeature.dateModified)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.sortFeature<Song>(SongSortFeature.title).toLowerCase()));
      await tester.pump();
      tester.expectSongTiles(songs.reversed);
    });
  });

  testWidgets('displays correct songs length', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0),
      songWith(id: 1),
      songWith(id: 2),
    ]);
    await tester.runAsync(() async {
      await setUpAppTest(() {
        FakeContentChannel.instance.songs = songs.toList();
      });
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);
      expect(find.text('3 ${l10n.tracksPlural(3).toLowerCase()}'), findsOneWidget);

      // Change songs length
      ContentControl.instance.state.allSongs.songs.removeLast();
      await tester.pump();

      tester.expectSongTiles(songs.toList()..removeLast());
      expect(find.text('2 ${l10n.tracksPlural(2).toLowerCase()}'), findsOneWidget);
    });
  });
}