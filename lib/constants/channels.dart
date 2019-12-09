/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// This is a file to all event and method channel constants

abstract class AudioFocusChannel {
  static const String CHANNEL_NAME = 'AUDIO_FOCUS_CHANNEL';

  static const String METHOD_REQUEST_FOCUS = "AUDIOFOCUS_METHOD_REQUEST_FOCUS";
  static const String METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_FAILED =
      "AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_FAILED";
  static const String METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_GRANTED =
      "AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_GRANTED";
  static const String METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_DELAYED =
      "AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_DELAYED";
  static const String METHOD_FOCUS_CHANGE = "AUDIOFOCUS_METHOD_FOCUS_CHANGE";
  static const String METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN =
      "AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN";
  static const String METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS =
      "AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS";
  static const String METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT =
      "AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT";
  static const String
      METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK =
      "AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

  static const String METHOD_ABANDON_FOCUS = "AUDIOFOCUS_METHOD_ABANDON_FOCUS";
}

abstract class EventChannel {
  static const String CHANNEL_NAME = 'EVENT_CHANNEL_STREAM';

  /// Event when user disconnects headset
  static const String eventBecomeNoisy =
      'com.nt4f04uNd.player.EVENT_BECAME_NOISY';
  // Events for notification clicks
  static const String eventPlay =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PLAY';
  static const String eventPause =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PAUSE';
  static const String eventNext =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_NEXT';
  static const String eventPrev =
      'com.nt4f04uNd.player.EVENT_NOTIFICATION_PREV';
}

abstract class GeneralChannel {
  static const String CHANNEL_NAME = 'GENERAL_CHANNEL_STREAM';

  static const String METHOD_INTENT_ACTION_VIEW =
      "GENERAL_METHOD_INTENT_ACTION_VIEW";

  static const String KILL_ACTIVITY =
      "GENERAL_METHOD_KILL_ACTIVITY";
}

abstract class MediaButtonChannel {
  static const String CHANNEL_NAME = 'MEDIABUTTON_CHANNEL_STREAM';

  static const String MEDIABUTTON_METHOD_CLICK = "MEDIABUTTON_METHOD_CLICK";
  // see
  // https://developer.android.com/reference/android/view/KeyEvent.html#KEYCODE_MEDIA_AUDIO_TRACK
  // for keycodes docs
  static const String METHOD_CLICK_ARG_AUDIO_TRACK =
      "MEDIABUTTON_METHOD_CLICK_ARG_AUDIO_TRACK";
  static const String METHOD_CLICK_ARG_FAST_FORWARD =
      "MEDIABUTTON_METHOD_CLICK_ARG_FAST_FORWARD";
  static const String METHOD_CLICK_ARG_REWIND =
      "MEDIABUTTON_METHOD_CLICK_ARG_REWIND";
  static const String METHOD_CLICK_ARG_NEXT =
      "MEDIABUTTON_METHOD_CLICK_ARG_NEXT";
  static const String METHOD_CLICK_ARG_PREVIOUS =
      "MEDIABUTTON_METHOD_CLICK_ARG_PREVIOUS";
  static const String METHOD_CLICK_ARG_PLAY_PAUSE =
      "MEDIABUTTON_METHOD_CLICK_ARG_PLAY_PAUSE";
  static const String METHOD_CLICK_ARG_PLAY =
      "MEDIABUTTON_METHOD_CLICK_ARG_PLAY";
  static const String METHOD_CLICK_ARG_STOP =
      "MEDIABUTTON_METHOD_CLICK_ARG_STOP";
  static const String METHOD_CLICK_ARG_HOOK =
      "MEDIABUTTON_METHOD_CLICK_ARG_HOOK";
}

abstract class NotificationChannel {
  static const String CHANNEL_NAME = 'NOTIFICATION_CHANNEL_STREAM';

  static final String METHOD_SHOW = "NOTIFICATION_METHOD_SHOW";
  static final String METHOD_SHOW_ARG_TITLE =
      "NOTIFICATION_METHOD_SHOW_ARG_TITLE";
  static final String METHOD_SHOW_ARG_ARTIST =
      "NOTIFICATION_METHOD_SHOW_ARG_ARTIST";
  static final String METHOD_SHOW_ARG_ALBUM_ART_BYTES =
      "NOTIFICATION_METHOD_SHOW_ARG_ALBUM_ART_BYTES";
  static final String METHOD_SHOW_ARG_IS_PLAYING =
      "NOTIFICATION_METHOD_SHOW_ARG_IS_PLAYING";

  static final String NOTIFICATION_METHOD_CLOSE = "NOTIFICATION_METHOD_CLOSE";
}

abstract class PlayerChannel {
  static const String CHANNEL_NAME = 'PLAYER_CHANNEL_STREAM';

}

abstract class SongsChannel {
  static const String channelName = 'SONGS_CHANNEL_STREAM';

  /// Retrieve songs method
  static final String SONGS_METHOD_METHOD_RETRIEVE_SONGS =
      "SONGS_METHOD_METHOD_RETRIEVE_SONGS";

  /// Method that sends found songs from native code to flutter code
   static final String SONGS_METHOD_METHOD_SEND_SONGS =
      "SONGS_METHOD_METHOD_SEND_SONGS";
}
