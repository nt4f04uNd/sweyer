/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:flutter/services.dart';

/// Type for audio manager focus
enum AudioFocusType { focus, no_focus, focus_delayed }

abstract class EventsHandler {
  /// Event channel for receiving native android events
  static EventChannel _eventChannel =
      const EventChannel('eventsChannel');

  static StreamSubscription<dynamic> _eventSubscription;

  /// Starts listening to the events
  static void init() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      // print('RECEIVED EVENT IN DART SIDE: $event');
      switch (event) {
        //****************** GENERALIZED EVENTS *****************************************************
        case 'generalizedPlayNext':
          MusicPlayer.playNext();
          break;
        case 'generalizedPlayPrev':
          MusicPlayer.playPrev();
          break;

        default:
          throw Exception(
              "Invalid event or case to it hasn't been added: $event");
      }
    });
  }

  /// Kills the channel listener
  static void kill() {
    _eventSubscription.cancel();
  }
}
