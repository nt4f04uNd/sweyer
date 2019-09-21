// This is a file to all event and method channel constants

abstract class EventChannel {
  static const String channelName = 'eventChannelStream';

  /// Event when user disconnects headset
  static const String eventBecomeNoisy = 'com.nt4f04uNd.player.BECAME_NOISY';
  // Events for notification clicks
  static const String eventPlay = 'com.nt4f04uNd.player.NOTIFICATION_PLAY';
  static const String eventPause = 'com.nt4f04uNd.player.NOTIFICATION_PAUSE';
  static const String eventNext = 'com.nt4f04uNd.player.NOTIFICATION_NEXT';
  static const String eventPrev = 'com.nt4f04uNd.player.NOTIFICATION_PREV';
}

abstract class MethodChannel {
  static const String channelName = 'methodChannelStream';

  /// Focus change method
  static const String methodFocusChange = 'FOCUS_CHANGE';
  // Arguments for focus change method
  static const String argFocusGain = 'AUDIOFOCUS_GAIN';
  static const String argFocusLoss = 'AUDIOFOCUS_LOSS';

  /// Focus lost but will be returned soon
  static const String argFocusLossTrans = 'AUDIOFOCUS_LOSS_TRANSIENT';

  /// Focus lost but will be returned soon (possible not to stop audio and just reduce sound)
  static const String argFocusLossTransCanDuck =
      'AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK';

  /// Request focus method
  static const String methodRequestFocus = 'REQUEST_FOCUS';
  // Possible returns for request method
  static const String returnRequestFail = 'AUDIOFOCUS_REQUEST_FAILED';

  static const String returnRequestGrant = 'AUDIOFOCUS_REQUEST_GRANTED';

  static const String returnRequestDelay = 'AUDIOFOCUS_REQUEST_DELAYED';

  /// Abandon focus method
  static const String methodAbandonFocus = 'ABANDON_FOCUS';

  /// Retrieve songs method
  static const String methodRetrieveSongs = 'RETRIEVE_SONGS';
  /// Method that sends found songs from native code to flutter code
  static const String methodSendSongs = 'SEND_SONGS';

  // Notifications methods
  static const String methodShowNotification = 'NOTIFICATION_SHOW';
 
  static const String methodCloseNotification = 'NOTIFICATION_CLOSE';
 
 /// Method to check if intent action is view (when user opens audio file with that app)
  static const String methodIntentActionView = 'INTENT_ACTION_VIEW';

  /// Click on headset hook button
  static const String methodHookButtonClick = 'HOOK_BUTTON_CLICK';

}
