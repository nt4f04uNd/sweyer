/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:flutter/services.dart';

/// Event channel for receiving native android events.
abstract class EventsChannel {
  static EventChannel _channel = const EventChannel('events_channel');
  static StreamSubscription _subscription;

  /// Starts listening to the events.
  static void init() {
    _subscription = _channel.receiveBroadcastStream().listen((event) {
      // print('RECEIVED EVENT IN DART SIDE: $event');
      switch (event) {
        case 'playNext':
          MusicPlayer.playNext();
          break;
        case 'playPrev':
          MusicPlayer.playPrev();
          break;
        default:
          throw ArgumentError("Invalid event or case to it hasn't been added: $event");
      }
    });
  }

  /// Kills the channel listener.
  static void kill() {
    _subscription.cancel();
  }
}
