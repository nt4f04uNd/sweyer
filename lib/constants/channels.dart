/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// This is a file to all event and method channel constants

/// Android package prefix
const String _prefix = "com.nt4f04und.sweyer.";

//****************PLAYER***************************************************************************************
abstract class PlayerChannel {
  static const String CHANNEL_NAME = _prefix + 'PLAYER_CHANNEL';
}

//****************EVENTS***************************************************************************************
abstract class EventChannel {
  static const String CHANNEL_NAME = _prefix + 'EVENT_CHANNEL';

  /// Event when user disconnects headset
  static const String BECOME_NOISY = _prefix + 'EVENT_BECAME_NOISY';
  // Events for notification clicks
  static const String NOTIFICATION_PLAY = _prefix + 'EVENT_NOTIFICATION_PLAY';
  static const String NOTIFICATION_PAUSE = _prefix + 'EVENT_NOTIFICATION_PAUSE';
  static const String NOTIFICATION_NEXT = _prefix + 'EVENT_NOTIFICATION_NEXT';
  static const String NOTIFICATION_PREV = _prefix + 'EVENT_NOTIFICATION_PREV';
  static const String NOTIFICATION_KILL_SERVICE = _prefix + 'EVENT_NOTIFICATION_KILL_SERVICE';
  static const String NOTIFICATION_LOOP = _prefix + 'EVENT_NOTIFICATION_LOOP';
  static const String NOTIFICATION_LOOP_ON = _prefix + "EVENT_NOTIFICATION_LOOP_ON";

  static const String AUDIOFOCUS_GAIN = _prefix + "EVENT_AUDIOFOCUS_GAIN";
  static const String AUDIOFOCUS_LOSS = _prefix + "EVENT_AUDIOFOCUS_LOSS";
  static const String AUDIOFOCUS_LOSS_TRANSIENT =
      _prefix + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
  static const String AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK =
      _prefix + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

  static const String MEDIABUTTON_AUDIO_TRACK =
      _prefix + "EVENT_MEDIABUTTON_AUDIO_TRACK";
  static const String MEDIABUTTON_FAST_FORWARD =
      _prefix + "EVENT_MEDIABUTTON_FAST_FORWARD";
  static const String MEDIABUTTON_REWIND = _prefix + "EVENT_MEDIABUTTON_REWIND";
  static const String MEDIABUTTON_NEXT = _prefix + "EVENT_MEDIABUTTON_NEXT";
  static const String MEDIABUTTON_PREVIOUS =
      _prefix + "EVENT_MEDIABUTTON_PREVIOUS";
  static const String MEDIABUTTON_PLAY_PAUSE =
      _prefix + "EVENT_MEDIABUTTON_PLAY_PAUSE";
  static const String MEDIABUTTON_PLAY = _prefix + "EVENT_MEDIABUTTON_PLAY";
  static const String MEDIABUTTON_STOP = _prefix + "EVENT_MEDIABUTTON_STOP";

  /// Bare button hook event
  static const String MEDIABUTTON_HOOK = _prefix + "EVENT_MEDIABUTTON_HOOK";

// Composed hook events
  /// When pressed hook once
  static const String HOOK_PLAY_PAUSE = _prefix + "EVENT_HOOK_PLAY_PAUSE";

  /// When pressed hook twice
  static const String HOOK_PLAY_NEXT = _prefix + "EVENT_HOOK_PLAY_NEXT";

  /// When pressed hook thrice
  static const String HOOK_PLAY_PREV = _prefix + "EVENT_HOOK_PLAY_PREV";
}

//****************GENERAL***************************************************************************************
abstract class GeneralChannel {
  static const String CHANNEL_NAME = _prefix + 'GENERAL_CHANNEL';

  static const String METHOD_INTENT_ACTION_VIEW =
      _prefix + "GENERAL_METHOD_INTENT_ACTION_VIEW";
}

//****************SERVICE***************************************************************************************
abstract class ServiceChannel {
  static const String CHANNEL_NAME = _prefix + 'SERVICE_CHANNEL';

  static const String METHOD_STOP_SERVICE =
      _prefix + "SERVICE_METHOD_STOP_SERVICE";
  static const String METHOD_SEND_SONG = _prefix + "SERVICE_METHOD_SEND_SONG";
}

//****************SONGS***************************************************************************************
abstract class SongsChannel {
  static const String CHANNEL_NAME = _prefix + 'SONGS_CHANNEL';

  /// Retrieve songs method
  static const String SONGS_METHOD_RETRIEVE_SONGS =
      _prefix + "SONGS_METHOD_RETRIEVE_SONGS";

  /// Method that sends found songs from native code to flutter code
  static const String SONGS_METHOD_SEND_SONGS =
      _prefix + "SONGS_METHOD_SEND_SONGS";
}
