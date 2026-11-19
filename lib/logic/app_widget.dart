import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';

import '../sweyer.dart';
import 'app_widget_config.dart';
import 'app_widget_ios.dart';

/// Controller for native app widgets.
///
/// The Flutter side only publishes widget state (`song` and `playing`) through
/// the `home_widget` shared storage and asks the native widget to refresh.
///
/// Rendering is platform-native: Android builds `RemoteViews`, while iOS builds
/// a WidgetKit/SwiftUI view that reads the same values from the App Group.
///
/// Platform-specific button handling lives in the native widget integration.
/// Android uses `audio_service` media-button intents, while iOS delegates to
/// [IosAppWidgetBridge].
class AppWidgetControl extends Control {
  static AppWidgetControl instance = AppWidgetControl();
  @visibleForTesting
  static const appWidgetName = appWidgetKind;

  StreamSubscription<Song>? _currentSongListener;
  StreamSubscription<bool>? _playingStateListener;
  IosAppWidgetBridge? _iosBridge;

  /// The last song content uri sent to the widget.
  String? _lastSongContentUri;

  /// The last playing state sent to the widget.
  bool? _lastPlayingState;

  @override
  Future<void> init() async {
    super.init();
    if (Platform.isIOS) {
      _iosBridge = IosAppWidgetBridge();
      await _iosBridge!.init();
    }
    _lastSongContentUri = null;
    _lastPlayingState = null;
    _currentSongListener =
        PlaybackControl.instance.onSongChange.listen((song) => update(song, PlayerManager.instance.playing));
    _playingStateListener =
        PlayerManager.instance.playingStream.listen((playing) => update(PlaybackControl.instance.currentSong, playing));
    await update(PlaybackControl.instance.currentSong, PlayerManager.instance.playing);
  }

  @override
  void dispose() {
    _currentSongListener?.cancel();
    _playingStateListener?.cancel();
    _iosBridge?.dispose();
    super.dispose();
  }

  /// Update the widgets with the current [song] and [playing] state.
  Future<void> update(Song song, bool playing) async {
    try {
      await _iosBridge?.saveQueueSnapshot(song);
      if (playing == _lastPlayingState && song.contentUri == _lastSongContentUri) {
        return;
      }
      _lastSongContentUri = song.contentUri;
      _lastPlayingState = playing;

      await HomeWidget.saveWidgetData(appWidgetSongUriKey, song.contentUri);
      await HomeWidget.saveWidgetData(appWidgetPlayingKey, playing);
      await HomeWidget.updateWidget(
        name: appWidgetName,
      );
    } catch (error, stack) {
      await reportErrorToFirebase(error, stack, reason: 'updating app widget');
      debugPrint('Failed to update the HomeWidget: $error');
    }
  }
}
