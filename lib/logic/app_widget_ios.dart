import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:playify/playify.dart' as playify;

import 'app_widget_config.dart';
import 'models/song.dart';
import 'player/content.dart';
import 'player/playback.dart';
import 'player/queue.dart';

@pragma('vm:entry-point')
Future<void> iosAppWidgetBackgroundCallback(Uri? uri) {
  return IosAppWidgetBridge.handleBackgroundAction(uri);
}

/// Owns the iOS-only state and playback bridge used by the interactive widget.
class IosAppWidgetBridge extends WidgetsBindingObserver {
  static const _appGroupId = 'group.com.nt4f04und.sweyer';
  static const _queueKey = 'queue';
  static const _queueIndexKey = 'queueIndex';
  static const _pendingSongIdKey = 'pendingSongId';
  static const _pendingSourceIdKey = 'pendingSourceId';

  StreamSubscription<void>? _queueListener;

  Future<void> init() async {
    await _configureHomeWidget();
    await HomeWidget.registerInteractivityCallback(iosAppWidgetBackgroundCallback);
    await _applyPendingSongSelection();
    _queueListener = QueueControl.instance.onQueueChanged.listen(
      (_) => unawaited(saveQueueSnapshot(PlaybackControl.instance.currentSong)),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueListener?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_applyPendingSongSelection());
    }
  }

  Future<void> saveQueueSnapshot(Song currentSong) async {
    try {
      final queue = QueueControl.instance.state.current;
      final currentIndex = queue.byId.getIndex(currentSong.id);
      if (currentIndex < 0) {
        return;
      }
      final encodedQueue = jsonEncode([
        for (final song in queue.songs)
          _WidgetQueueEntry(
            id: song.id,
            sourceId: song.sourceId.toString(),
            contentUri: song.contentUri,
          ).toJson(),
      ]);
      await Future.wait([
        HomeWidget.saveWidgetData(_queueKey, encodedQueue),
        HomeWidget.saveWidgetData(_queueIndexKey, currentIndex),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Failed to save the iOS widget queue: $error\n$stackTrace');
    }
  }

  Future<void> _applyPendingSongSelection() async {
    final pendingSongId = await HomeWidget.getWidgetData<int>(_pendingSongIdKey);
    final pendingSourceId = await HomeWidget.getWidgetData<String>(_pendingSourceIdKey);
    if (pendingSongId == null && pendingSourceId == null) {
      return;
    }

    final song = _findPendingSong(pendingSongId, pendingSourceId);
    if (song != null) {
      PlaybackControl.instance.changeSong(song);
    }
    await Future.wait([
      HomeWidget.saveWidgetData<int>(_pendingSongIdKey, null),
      HomeWidget.saveWidgetData<String>(_pendingSourceIdKey, null),
    ]);
  }

  Song? _findPendingSong(int? songId, String? sourceIdString) {
    if (songId != null) {
      final song = QueueControl.instance.state.current.byId.get(songId);
      if (song != null) {
        return song;
      }
    }
    final sourceId = sourceIdString == null ? null : int.tryParse(sourceIdString);
    if (sourceId == null) {
      return null;
    }
    for (final song in ContentControl.instance.state.allSongs.songs) {
      if (song.sourceId == sourceId) {
        return song;
      }
    }
    return null;
  }

  static Future<void> _configureHomeWidget() {
    return HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Handles an action in the headless isolate started by home_widget.
  static Future<void> handleBackgroundAction(Uri? uri) async {
    if (uri == null || uri.host != 'widget' || uri.pathSegments.isEmpty) {
      return;
    }
    await _configureHomeWidget();

    try {
      final action = uri.pathSegments.last;
      final player = playify.Playify.instance;
      bool? playing;
      switch (action) {
        case 'playPause':
          final wasPlaying = await player.isPlaying();
          if (wasPlaying) {
            await player.pause();
          } else {
            await player.play();
          }
          playing = !wasPlaying;
          break;
        case 'next':
          playing = await _playAdjacentSong(player, 1) ? true : null;
          break;
        case 'previous':
          playing = await _playAdjacentSong(player, -1) ? true : null;
          break;
        default:
          return;
      }

      if (playing != null) {
        await HomeWidget.saveWidgetData(appWidgetPlayingKey, playing);
      }
      await HomeWidget.updateWidget(name: appWidgetKind);
    } catch (error, stackTrace) {
      debugPrint('Failed to handle an iOS widget action: $error\n$stackTrace');
    }
  }

  static Future<bool> _playAdjacentSong(playify.Playify player, int offset) async {
    final encodedQueue = await HomeWidget.getWidgetData<String>(_queueKey);
    final queue = _decodeQueue(encodedQueue);
    if (queue.isEmpty) {
      return false;
    }

    final savedIndex = await HomeWidget.getWidgetData<int>(_queueIndexKey) ?? 0;
    var currentIndex = savedIndex;
    if (currentIndex < 0) {
      currentIndex = 0;
    } else if (currentIndex >= queue.length) {
      currentIndex = queue.length - 1;
    }
    final targetIndex = (currentIndex + offset) % queue.length;
    final target = queue[targetIndex];

    // Sweyer intentionally gives the system player one item at a time so the
    // Apple Music notification cannot advance independently from app state.
    await player.setQueue(
      songIDs: [target.sourceId],
      startID: target.sourceId,
    );
    await Future.wait([
      HomeWidget.saveWidgetData(_queueIndexKey, targetIndex),
      HomeWidget.saveWidgetData(_pendingSongIdKey, target.id),
      HomeWidget.saveWidgetData(_pendingSourceIdKey, target.sourceId),
      HomeWidget.saveWidgetData(appWidgetSongUriKey, target.contentUri),
    ]);
    return true;
  }

  static List<_WidgetQueueEntry> _decodeQueue(String? value) {
    if (value == null) {
      return const [];
    }
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map((entry) => _WidgetQueueEntry.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }
}

class _WidgetQueueEntry {
  const _WidgetQueueEntry({
    required this.id,
    required this.sourceId,
    required this.contentUri,
  });

  factory _WidgetQueueEntry.fromJson(Map<String, dynamic> json) {
    return _WidgetQueueEntry(
      id: json['id'] as int,
      sourceId: json['sourceId'] as String,
      contentUri: json['contentUri'] as String,
    );
  }

  final int id;
  final String sourceId;
  final String contentUri;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'contentUri': contentUri,
      };
}
