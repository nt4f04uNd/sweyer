/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// This is a file to all event and method channel constants

abstract class PlayerChannel {
  static const String CHANNEL_NAME = 'PLAYER_CHANNEL_STREAM';
}

abstract class EventChannel {
  static const String CHANNEL_NAME = 'EVENT_CHANNEL_STREAM';

  /// Event when user disconnects headset
  static const String BECOME_NOISY = 'com.nt4f04uNd.player.EVENT_BECAME_NOISY';
  // Events for notification clicks
  static const String NOTIFICATION_PLAY =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PLAY';
  static const String NOTIFICATION_PAUSE =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PAUSE';
  static const String NOTIFICATION_NEXT =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_NEXT';
  static const String NOTIFICATION_PREV =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PREV';

  static const String AUDIOFOCUS_GAIN = "EVENT_AUDIOFOCUS_GAIN";
  static const String AUDIOFOCUS_LOSS = "EVENT_AUDIOFOCUS_LOSS";
  static const String AUDIOFOCUS_LOSS_TRANSIENT =
      "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
  static const String AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK =
      "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

  static const String MEDIABUTTON_AUDIO_TRACK = "EVENT_MEDIABUTTON_AUDIO_TRACK";
  static const String MEDIABUTTON_FAST_FORWARD =
      "EVENT_MEDIABUTTON_FAST_FORWARD";
  static const String MEDIABUTTON_REWIND = "EVENT_MEDIABUTTON_REWIND";
  static const String MEDIABUTTON_NEXT = "EVENT_MEDIABUTTON_NEXT";
  static const String MEDIABUTTON_PREVIOUS = "EVENT_MEDIABUTTON_PREVIOUS";
  static const String MEDIABUTTON_PLAY_PAUSE = "EVENT_MEDIABUTTON_PLAY_PAUSE";
  static const String MEDIABUTTON_PLAY = "EVENT_MEDIABUTTON_PLAY";
  static const String MEDIABUTTON_STOP = "EVENT_MEDIABUTTON_STOP";
  static const String MEDIABUTTON_HOOK = "EVENT_MEDIABUTTON_HOOK";
}

abstract class GeneralChannel {
  static const String CHANNEL_NAME = 'GENERAL_CHANNEL_STREAM';

  static const String METHOD_INTENT_ACTION_VIEW =
      "GENERAL_METHOD_INTENT_ACTION_VIEW";

  static const String KILL_ACTIVITY = "GENERAL_METHOD_KILL_ACTIVITY";

  static const String METHOD_START_SERVICE = "GENERAL_METHOD_START_SERVICE";
  static const String METHOD_STOP_SERVICE = "GENERAL_METHOD_STOP_SERVICE";
}

abstract class ServiceChannel {
  static const String CHANNEL_NAME = 'SERVICE_CHANNEL_STREAM';

  static const String METHOD_START_SERVICE = "SERVICE_METHOD_START_SERVICE";
  static const String METHOD_STOP_SERVICE = "SERVICE_METHOD_STOP_SERVICE";
  static const String METHOD_IS_SERVICE_RUNNING =
      "SERVICE_METHOD_IS_SERVICE_RUNNING";
}

abstract class SongsChannel {
  static const String channelName = 'SONGS_CHANNEL_STREAM';

  /// Retrieve songs method
  static const String SONGS_METHOD_RETRIEVE_SONGS =
      "SONGS_METHOD_RETRIEVE_SONGS";

  /// Method that sends found songs from native code to flutter code
  static const String SONGS_METHOD_SEND_SONGS = "SONGS_METHOD_SEND_SONGS";
}
