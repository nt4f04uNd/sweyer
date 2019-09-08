/// Class that contains all keys to shared preferences; types of values assigned to keys are represented at the ends of property names
abstract class PrefKeys {
  /// Key to save user search input history
  static const String searchHistoryStringList = 'search_history';
  /// Key to save last song position
  static const String songPositionInt = 'song_position';
  /// Key to save last song id
  static const String songIdInt = 'song_id';
  /// Key to save last song id
  static const String loopModeBool = 'loop_mode';
}
