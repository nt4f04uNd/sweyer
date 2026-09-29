import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:playify/playify.dart' as playify;

import '../sweyer.dart';

/// Controller for native app widgets.
///
/// The Flutter side only publishes widget state (`song` and `playing`) through
/// the `home_widget` shared storage and asks the native widget to refresh.
///
/// Rendering is platform-native: Android builds `RemoteViews`, while iOS builds
/// a WidgetKit/SwiftUI view that reads the same values from the App Group.
///
/// Button handling is platform-specific as well.
/// - Android buttons are wired directly to `audio_service`
/// media-button intents in the native widget.
/// - iOS interactive widgets use `AppIntent` + `HomeWidgetBackgroundWorker`, so
/// `registerInteractivityCallback` is registered here to give that worker a
/// Dart entry point for play/pause/next/previous actions.
@pragma('vm:entry-point')
Future<void> appWidgetBackgroundCallback(Uri? uri) {
  return AppWidgetControl.handleBackgroundAction(uri);
}

class AppWidgetControl extends Control with WidgetsBindingObserver {
  static AppWidgetControl instance = AppWidgetControl();
  @visibleForTesting
  static const appWidgetName = 'MusicPlayerAppWidget';
  static const _appGroupId = 'group.com.nt4f04und.sweyer';
  static const _songUriKey = 'song';
  static const _playingKey = 'playing';
  static const _queueKey = 'queue';
  static const _queueIndexKey = 'queueIndex';
  static const _pendingSongIdKey = 'pendingSongId';
  static const _pendingSourceIdKey = 'pendingSourceId';

  StreamSubscription<Song>? _currentSongListener;
  StreamSubscription<bool>? _playingStateListener;
  StreamSubscription<void>? _queueListener;

  /// The last song content uri sent to the widget.
  String? _lastSongContentUri;

  /// The last playing state sent to the widget.
  bool? _lastPlayingState;

  @override
  Future<void> init() async {
    super.init();
    await _configureHomeWidget();
    await HomeWidget.registerInteractivityCallback(appWidgetBackgroundCallback);
    await _synchronizePendingSong();
    _lastSongContentUri = null;
    _lastPlayingState = null;
    _currentSongListener =
        PlaybackControl.instance.onSongChange.listen((song) => update(song, PlayerManager.instance.playing));
    _playingStateListener =
        PlayerManager.instance.playingStream.listen((playing) => update(PlaybackControl.instance.currentSong, playing));
    _queueListener = QueueControl.instance.onQueueChanged
        .listen((_) => update(PlaybackControl.instance.currentSong, PlayerManager.instance.playing));
    WidgetsBinding.instance.addObserver(this);
    await update(PlaybackControl.instance.currentSong, PlayerManager.instance.playing);
  }

  static Future<void> _configureHomeWidget() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  /// Handles an action in the headless isolate started by home_widget.
  static Future<void> handleBackgroundAction(Uri? uri) async {
    if (!Platform.isIOS || uri == null || uri.host != 'widget' || uri.pathSegments.isEmpty) {
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
        await HomeWidget.saveWidgetData(_playingKey, playing);
      }
      await HomeWidget.updateWidget(name: appWidgetName);
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

    // Sweyer intentionally gives the system player one item at a time. This
    // keeps all queue transitions under Sweyer's control instead of allowing
    // the Apple Music notification to advance independently from app state.
    await player.setQueue(
      songIDs: [target.sourceId],
      startID: target.sourceId,
    );
    await Future.wait([
      HomeWidget.saveWidgetData(_queueIndexKey, targetIndex),
      HomeWidget.saveWidgetData(_pendingSongIdKey, target.id),
      HomeWidget.saveWidgetData(_pendingSourceIdKey, target.sourceId),
      HomeWidget.saveWidgetData(_songUriKey, target.contentUri),
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

  Future<void> _synchronizePendingSong() async {
    final pendingSongId = await HomeWidget.getWidgetData<int>(_pendingSongIdKey);
    final pendingSourceId = await HomeWidget.getWidgetData<String>(_pendingSourceIdKey);
    if (pendingSongId == null && pendingSourceId == null) {
      return;
    }

    Song? song;
    if (pendingSongId != null) {
      song = QueueControl.instance.state.current.byId.get(pendingSongId);
    }
    if (song == null && pendingSourceId != null) {
      final sourceId = int.tryParse(pendingSourceId);
      if (sourceId != null) {
        for (final candidate in ContentControl.instance.state.allSongs.songs) {
          if (candidate.sourceId == sourceId) {
            song = candidate;
            break;
          }
        }
      }
    }
    if (song != null) {
      PlayerManager.instance.synchronizeExternalSong(song);
    }
    await Future.wait([
      HomeWidget.saveWidgetData<int>(_pendingSongIdKey, null),
      HomeWidget.saveWidgetData<String>(_pendingSourceIdKey, null),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_synchronizePendingSong());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentSongListener?.cancel();
    _playingStateListener?.cancel();
    _queueListener?.cancel();
    super.dispose();
  }

  /// Update the widgets with the current [song] and [playing] state.
  Future<void> update(Song song, bool playing) async {
    try {
      if (Platform.isIOS) {
        await _saveQueueSnapshot(song);
      }
      if (playing == _lastPlayingState && song.contentUri == _lastSongContentUri) {
        return;
      }
      _lastSongContentUri = song.contentUri;
      _lastPlayingState = playing;

      await HomeWidget.saveWidgetData(_songUriKey, song.contentUri);
      await HomeWidget.saveWidgetData(_playingKey, playing);
      await HomeWidget.updateWidget(
        name: appWidgetName,
      );
    } catch (error, stack) {
      await reportErrorToFirebase(error, stack, reason: 'updating app widget');
      debugPrint('Failed to update the HomeWidget: $error');
    }
  }

  Future<void> _saveQueueSnapshot(Song currentSong) async {
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
