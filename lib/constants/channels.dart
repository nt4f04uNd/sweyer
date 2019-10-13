// This is a file to all event and method channel constants

abstract class EventChannel {
  static const String channelName = 'EVENT_CHANNEL_STREAM';

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

abstract class PlayerChannel {
  static const String channelName = 'PLAYER_CHANNEL_STREAM';

  /// Focus change method
  static const String methodFocusChange = 'PLAYER_METHOD_FOCUS_CHANGE';
  // Arguments for focus change method
  static const String argFocusGain =
      "PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN";
  static const String argFocusLoss =
      "PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS";

  /// Focus lost but will be returned soon
  static const String argFocusLossTrans =
      "PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT";

  /// Focus lost but will be returned soon (possible not to stop audio and just reduce sound)
  static const String argFocusLossTransCanDuck =
      "PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

  /// Request focus method
  static const String methodRequestFocus = "PLAYER_METHOD_REQUEST_FOCUS";
  // Possible returns for request method
  static const String returnRequestFail =
      "PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_FAILED";

  static const String returnRequestGrant =
      "PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_GRANTED";

  static const String returnRequestDelay =
      "PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_DELAYED";

  /// Abandon focus method
  static const String methodAbandonFocus = "PLAYER_METHOD_ABANDON_FOCUS";

  // Notifications methods
  static const String methodShowNotification =
      "PLAYER_METHOD_NOTIFICATION_SHOW";
  static String argTitle = "PLAYER_METHOD_NOTIFICATION_SHOW_ARG_TITLE";
  static String argArtist = "PLAYER_METHOD_NOTIFICATION_SHOW_ARG_ARTIST";
  static String argAlbumArtBytes =
      "PLAYER_METHOD_NOTIFICATION_SHOW_ARG_ALBUM_ART_BYTES";
  static String argIsPlaying = "PLAYER_METHOD_NOTIFICATION_SHOW_ARG_IS_PLAYING";

  static const String methodCloseNotification =
      "PLAYER_METHOD_NOTIFICATION_CLOSE";

  /// Method to check if intent action is view (when user opens audio file with that app)
  static const String methodIntentActionView =
      "PLAYER_METHOD_INTENT_ACTION_VIEW";

  /// Click on headset hook button
  static const String methodHookButtonClick = "PLAYER_METHOD_HOOK_BUTTON_CLICK";
}

abstract class SongsChannel {
  static const String channelName = 'SONGS_CHANNEL_STREAM';

  /// Retrieve songs method
  static const String methodRetrieveSongs =
      "SONGS_METHOD_METHOD_RETRIEVE_SONGS";

  /// Method that sends found songs from native code to flutter code
  static const String methodSendSongs = "SONGS_METHOD_METHOD_SEND_SONGS";
}
