/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/constants/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';
import 'package:flutter/services.dart';

/// Type for audio manager focus
enum AudioFocusType { focus, no_focus, focus_delayed }

abstract class EventsHandler {
  /// Event channel for receiving native android events
  static EventChannel _eventChannel =
      const EventChannel(Constants.EventChannel.CHANNEL_NAME);

  static StreamSubscription<dynamic> _eventSubscription;

  static void start() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      print("RECEIVED EVENT IN DART SIDE: $event");
      switch (event) {
        case Constants
            .EventChannel.BECOME_NOISY: // handle headphones disconnect
          // MusicPlayer.pause();
          break;
        //************** NOTIFICATION *********************************************************
        case Constants.EventChannel.NOTIFICATION_PLAY:
          // MusicPlayer.playPause();
          break;
        case Constants.EventChannel.NOTIFICATION_PAUSE:
          // MusicPlayer.playPause();
          break;
        case Constants.EventChannel.NOTIFICATION_NEXT:
          MusicPlayer.playNext();
          break;
        case Constants.EventChannel.NOTIFICATION_PREV:
          MusicPlayer.playPrev();
          break;
        case Constants.EventChannel.NOTIFICATION_KILL_SERVICE:
          // MusicPlayer.playPrev();
          break;
        case Constants.EventChannel.NOTIFICATION_LOOP:
          // MusicPlayer.playPrev();
          break;
        case Constants.EventChannel.NOTIFICATION_LOOP_ON:
          // MusicPlayer.playPrev();
          break;
        //************** AUDIO FOCUS *********************************************************
        case Constants.EventChannel.AUDIOFOCUS_GAIN:
          break;
        case Constants.EventChannel.AUDIOFOCUS_LOSS:
          break;
        case Constants.EventChannel.AUDIOFOCUS_LOSS_TRANSIENT:
          break;
        case Constants.EventChannel.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
          break;

        //************** MEDIA BUTTONS *********************************************************
        case Constants.EventChannel.MEDIABUTTON_AUDIO_TRACK:
          // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_FAST_FORWARD:
         // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_REWIND:
          // MusicPlayer.rewind();
          break;
        case Constants.EventChannel.MEDIABUTTON_NEXT:
         // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_PREVIOUS:
         // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_PLAY_PAUSE:
         // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_PLAY:
         // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_STOP:
        // ...
          break;
        case Constants.EventChannel.MEDIABUTTON_HOOK:
         // ...
          break;

        //****************** HOOK BUTTONS *****************************************************

        case Constants.EventChannel.HOOK_PLAY_PAUSE:
          // ...
          break;
        case Constants.EventChannel.HOOK_PLAY_NEXT:
         MusicPlayer.playNext();
          break;
        case Constants.EventChannel.HOOK_PLAY_PREV:
         MusicPlayer.playPrev();
          break;

        default:
          throw Exception("Invalid event or case to it hasn't been added: $event");
      }
    });
  }

  static void stop() {
    _eventSubscription.cancel();
  }
}
