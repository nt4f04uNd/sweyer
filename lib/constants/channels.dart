/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// This is a file to all event and method channel constants

/// Android package prefix
const String DOTTED_PACKAGE_NAME = "com.nt4f04und.sweyer.";

//****************PLAYER***************************************************************************************
abstract class PlayerChannel {
  static const String CHANNEL_NAME = DOTTED_PACKAGE_NAME + 'PLAYER_CHANNEL';
}

//****************EVENTS***************************************************************************************
abstract class EventChannel {
  static const String CHANNEL_NAME = DOTTED_PACKAGE_NAME + 'EVENT_CHANNEL';

  /// Event when user disconnects headset
  static const String BECOME_NOISY = DOTTED_PACKAGE_NAME + 'EVENT_BECAME_NOISY';
  // Events for notification clicks
  static const String NOTIFICATION_PLAY         = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_PLAY';
  static const String NOTIFICATION_PAUSE        = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_PAUSE';
  static const String NOTIFICATION_NEXT         = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_NEXT';
  static const String NOTIFICATION_PREV         = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_PREV';
  static const String NOTIFICATION_KILL_SERVICE = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_KILL_SERVICE';
  static const String NOTIFICATION_LOOP         = DOTTED_PACKAGE_NAME + 'EVENT_NOTIFICATION_LOOP';
  static const String NOTIFICATION_LOOP_ON      = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_LOOP_ON";

  static const String AUDIOFOCUS_GAIN                    = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_GAIN";
  static const String AUDIOFOCUS_LOSS                    = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS";
  static const String AUDIOFOCUS_LOSS_TRANSIENT          = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
  static const String AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

  static const String MEDIABUTTON_AUDIO_TRACK          = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_AUDIO_TRACK";
  static const String MEDIABUTTON_FAST_FORWARD         = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_FAST_FORWARD";
  static const String MEDIABUTTON_REWIND               = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_REWIND";
  static const String MEDIABUTTON_NEXT                 = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_NEXT";
  static const String MEDIABUTTON_PREVIOUS             = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PREVIOUS";
  static const String MEDIABUTTON_PLAY                 = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY";
  static const String MEDIABUTTON_PAUSE                = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PAUSE";
  static const String MEDIABUTTON_PLAY_PAUSE           = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY_PAUSE";
  static const String MEDIABUTTON_STOP                 = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_STOP";

  /// Bare button hook event
  static const String MEDIABUTTON_HOOK = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_HOOK";

// Composed hook events
  /// When pressed hook once
  static const String HOOK_PLAY_PAUSE = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_PAUSE";

  /// When pressed hook twice
  static const String HOOK_PLAY_NEXT = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_NEXT";

  /// When pressed hook thrice
  static const String HOOK_PLAY_PREV = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_PREV";

  // Generalized events - these are e.g. next, prev.
  // They are needed because I can call them from different places, i.e. notification or media session events
  // Though events for notification and media session still exist to have access to them directly in dart side
  static const String GENERALIZED_PLAY_NEXT = DOTTED_PACKAGE_NAME + "EVENT_GENERALIZED_PLAY_NEXT";
  static const String GENERALIZED_PLAY_PREV = DOTTED_PACKAGE_NAME + "EVENT_GENERALIZED_PLAY_PREV";
}

//****************GENERAL***************************************************************************************
abstract class GeneralChannel {
  static const String CHANNEL_NAME              = DOTTED_PACKAGE_NAME + 'GENERAL_CHANNEL';

  static const String METHOD_INTENT_ACTION_VIEW = DOTTED_PACKAGE_NAME + "GENERAL_METHOD_INTENT_ACTION_VIEW";
}

//****************SERVICE***************************************************************************************
abstract class ServiceChannel {
  static const String CHANNEL_NAME             = DOTTED_PACKAGE_NAME + 'SERVICE_CHANNEL';

  static const String METHOD_STOP_SERVICE      = DOTTED_PACKAGE_NAME + "SERVICE_METHOD_STOP_SERVICE";
  static const String METHOD_SEND_CURRENT_SONG = DOTTED_PACKAGE_NAME + "SERVICE_METHOD_SEND_CURRENT_SONG";
}

//****************SONGS***************************************************************************************
abstract class SongsChannel {
  static const String CHANNEL_NAME =             DOTTED_PACKAGE_NAME + 'SONGS_CHANNEL';

  /// Retrieve songs method
  static const String METHOD_RETRIEVE_SONGS =    DOTTED_PACKAGE_NAME + "SONGS_METHOD_RETRIEVE_SONGS";

  /// Method that sends found songs from native code to flutter code
  static const String METHOD_SEND_SONGS =        DOTTED_PACKAGE_NAME + "SONGS_METHOD_SEND_SONGS";

  static const String METHOD_DELETE_SONGS =      DOTTED_PACKAGE_NAME + "SONGS_METHOD_DELETE_SONGS";
}
