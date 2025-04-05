import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';

import '../sweyer.dart';

/// Controller for native app widgets.
class AppWidgetControl extends Control {
  static AppWidgetControl instance = AppWidgetControl();
  @visibleForTesting
  static const appWidgetName = 'MusicPlayerAppWidget';
  static const _songUriKey = 'song';
  static const _playingKey = 'playing';

  StreamSubscription<Song>? _currentSongListener;
  StreamSubscription<bool>? _playingStateListener;

  /// The last song content uri sent to the widget.
  String? _lastSongContentUri;

  /// The last playing state sent to the widget.
  bool? _lastPlayingState;

  @override
  void init() {
    super.init();
    _lastSongContentUri = null;
    _lastPlayingState = null;
    _currentSongListener =
        PlaybackControl.instance.onSongChange.listen((song) => update(song, PlayerManager.instance.playing));
    _playingStateListener =
        PlayerManager.instance.playingStream.listen((playing) => update(PlaybackControl.instance.currentSong, playing));
    
    // Register the interactivity callback for widget interactions
    HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  // Background callback function that will be called when the widget is interacted with
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri == null) return;
    
    // The uri will be in the format: "sweyer://widget/action"
    // For example: "sweyer://widget/playPause"
    if (uri.host == 'widget') {
      final action = uri.pathSegments.last;
      
      // Perform the action directly
      switch (action) {
        case 'playPause':
          await PlayerManager.instance.playPause();
          break;
        case 'next':
          await PlayerManager.instance.playNext();
          break;
        case 'previous':
          await PlayerManager.instance.playPrev();
          break;
      }
      
      // Update the widget to reflect the new state
      if (PlaybackControl.instance.currentSong != null) {
        await HomeWidget.saveWidgetData(_songUriKey, PlaybackControl.instance.currentSong!.contentUri);
        await HomeWidget.saveWidgetData(_playingKey, PlayerManager.instance.playing);
        await HomeWidget.updateWidget(
          name: appWidgetName,
          iOSName: appWidgetName,
        );
      }
    }
  }

  @override
  void dispose() {
    _currentSongListener?.cancel();
    _playingStateListener?.cancel();
    super.dispose();
  }

  /// Update the widgets with the current [song] and [playing] state.
  Future<void> update(Song song, bool playing) async {
    if (playing == _lastPlayingState && song.contentUri == _lastSongContentUri) {
      return;
    }
    _lastSongContentUri = song.contentUri;
    _lastPlayingState = playing;

    try {
      // For iOS, we need to set the App Group ID
      if (Platform.isIOS) {
        // Use a dummy group ID for development/testing
        // This will work in the simulator but not on real devices without a developer account
        // TODO: move to constants?
        await HomeWidget.setAppGroupId("group.com.nt4f04und.sweyer");
      }

      await HomeWidget.saveWidgetData(_songUriKey, song.contentUri);
      await HomeWidget.saveWidgetData(_playingKey, playing);
      await HomeWidget.updateWidget(
        name: appWidgetName,
        iOSName: appWidgetName,
      );
    } catch (e) {
      // Log the error but don't crash the app
      debugPrint('HomeWidget error: $e');
    }
  }
}
