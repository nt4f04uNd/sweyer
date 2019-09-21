import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app/constants/constants.dart' as Constants;
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Type for audio manager focus
enum AudioFocusType { focus, no_focus, focus_delayed }

/// Type for play process state
enum PlayStateType { stopped, playing, paused }

/// Features to sort by
enum SortFeature { date, title }

/// Function for call player functions from AudioPlayers package until they will be completed, or until recursive callstack will exceed 10
///
/// First argument is callback to complete
///
/// Seconds argument is initial callStackSize and optional
///
/// TODO: test this method
Future<int> _recursiveCallback(Future<int> callback(),
    [int callStackSize = 0]) async {
  int res = await callback();
  if (res != 1 && callStackSize < 10) // If result isn't successful try again
    return await _recursiveCallback(callback, callStackSize++);
  else if (res == 1) // If  result is successful return 1
    return 1;
  else // If result isn't successful and callstack exceeded return 0
    throw Exception(
        "_recursiveCallback failed and didn't manage to get success before callstack exceeded 10");
}

// FIXME: conduct a massive refactor of methods and properties
class MusicPlayer {
  static MusicPlayer getInstance;

  /// Channel for handling audio focus
  static const _methodChannel =
      const MethodChannel(Constants.MethodChannel.channelName);

  /// Event channel for receiving native android events
  static const _eventChannel =
      const EventChannel(Constants.EventChannel.channelName);

  /// `[MusicFinder]` player instance
  final _playerInstance = AudioPlayer();

  /// Paths of found tracks in `fetchSongs` method
  List<Song> _songs;

  /// Some songs collection to play (used in search currently), it has a bigger priority than songs list, so if in playlist there is more than zero songs, next and prev actions will prefer to play it
  List<Song> _playList = [];

  /// A subscription to duration change in constructior
  StreamSubscription<Duration> _durationChangeListenerSubscription;

  /// Subscription for events stream
  StreamSubscription _eventSubscription;

  /// Subscription for changes in state
  StreamSubscription<AudioPlayerState> _stateChangeSubscription;

  /// Subscription for completion changes
  StreamSubscription<void> _completionSubscription;

  /// Subscription for completion changes
  StreamSubscription<String> _playerErrorSubscription;

  /// Audio manager focus state
  AudioFocusType focusState = AudioFocusType.no_focus;

  /// Is notification visible
  bool notificationState = false;

  /// Is notification visible
  bool loopModeState = false;

  /// Flag to see if song searching is performing
  ///
  /// TODO: remove this value as it duplicates searchingOperation
  bool searchingState = false;

  /// Hook handle
  /// Variable to save latest hook press time
  DateTime _latestHookPressTime;

  /// How much times hook has been pressed during handle multiple presses time (e.g. 700ms)
  int _hookPressStack = 0;

  /// Current index of playing track in `_songs`
  ///
  /// TODO: `_songs` list can be resorted so I should to write method that updates this variable on resort
  int playingTrackIdState;

  /// Is player tries to switch right now
  /// TODO: improve implementation of this
  bool switching = false;

  _TrackListChangeStreamController _trackListChangeStreamController =
      _TrackListChangeStreamController();

  AsyncOperation searchingOperation = AsyncOperation();

  // Getters
  /// Get current playing song
  Song get currentSong {
    _songsCheck();
    return _songs.firstWhere(
      (el) => el.id == playingTrackIdState,
      // FIXME: accessing _songs[0] can actually cause an error when there's no songs
      orElse: () => _songs[0],
    );
  }

  /// Get songs count
  int get songsCount {
    _songsCheck();
    return _songs.length;
  }

  /// Whether songs list instantiated or not (in the future will implement cashing so, but for now this depends on `fetchSongs`)
  bool get songsReady => _songs != null;

  /// If songs array is empty
  bool get songsEmpty => _songs.isEmpty;

  /// Get stream of changes on audio position.
  Stream<Duration> get onAudioPositionChanged =>
      _playerInstance.onAudioPositionChanged;

  /// Get stream of changes on player state.
  Stream<AudioPlayerState> get onPlayerStateChanged =>
      _playerInstance.onPlayerStateChanged;

  /// Get stream of changes on audio duration
  Stream<Duration> get onDurationChanged => _playerInstance.onDurationChanged;

  /// Get stream of player completions
  Stream<void> get onPlayerCompletion => _playerInstance.onPlayerCompletion;

  /// Get stream of player errors
  Stream<String> get onPlayerError => _playerInstance.onPlayerError;

  /// Get stream of notifier events about changes on track list
  Stream<void> get onTrackListChange =>
      _trackListChangeStreamController._controller.stream;

  AudioPlayerState get playState => _playerInstance.state;

  /// Get current position
  Future<Duration> get currentPosition async {
    try {
      return Duration(milliseconds: await _playerInstance.getCurrentPosition());
    } catch (e) {}
  }

  /// ATTENTION: IF YOU USE `call.arguemnts` WITH THIS FUNCTION, TYPE CAST IT THROUGH `List<T> List.cast<T>()`, because `call.arguemnts` `as` type cast will crash closure execution
  void _getSongsFromChannel(List<String> songsJsons) {
    List<Song> foundSongs = [];
    for (String songJson in songsJsons) {
      foundSongs.add(Song.fromJson(jsonDecode(songJson)));
    }
    _songs = foundSongs;

    searchingState = false;
    searchingOperation.finishOperation();

    // Emit event to track change stream
    _trackListChangeStreamController.emitEvent();

    _saveSongsJson();
  }

  MusicPlayer() {
    getInstance = this;

    // Change player mode for sure
    _playerInstance.mode = PlayerMode.MEDIA_PLAYER;

    _durationChangeListenerSubscription = onDurationChanged.listen((event) {
      switching = false;
    });

    _completionSubscription = onPlayerCompletion.listen((event) {
      // Play next track if not in loop mode
      if (!loopModeState) clickNext();
    });

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      switch (event) {
        case Constants
            .EventChannel.eventBecomeNoisy: // handle headphones disconnect
          pause();
          break;
        case Constants.EventChannel.eventPlay:
          clickPausePlay();
          break;
        case Constants.EventChannel.eventPause:
          clickPausePlay();
          break;
        case Constants.EventChannel.eventNext:
          clickNext();
          break;
        case Constants.EventChannel.eventPrev:
          clickPrev();
          break;
        default:
          throw Exception('Invalid event');
      }
    });

    _stateChangeSubscription = onPlayerStateChanged.listen((event) async {
      if (!songsEmpty) {
        // TODO: improve this code
        var prefs = await SharedPreferences.getInstance();
        prefs.setInt(Constants.PrefKeys.songIdInt, currentSong.id);
      }

      switch (event) {
        case AudioPlayerState.PLAYING:
          _showNotification(
              artist: artistString(currentSong.artist),
              title: currentSong.title,
              isPlaying: true);
          notificationState = true;
          break;
        case AudioPlayerState.PAUSED:
          if (notificationState)
            _showNotification(
                artist: artistString(currentSong.artist),
                title: currentSong.title,
                isPlaying: false);
          break;
        case AudioPlayerState.STOPPED:
          _closeNotification();
          notificationState = false;
          break;
        case AudioPlayerState.COMPLETED:
          break;
        default:
          break;
      }
    });

    // TODO: see how to improve focus and gaindelayed usage
    // Set listener for method calls for changing focus
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      // debugPrint('${call.method}, ${call.arguments.toString()}');

      if (call.method == Constants.MethodChannel.methodFocusChange) {
        switch (call.arguments) {
          // TODO: rewrite instead of these methods my class methods (resume, pause, etc.)
          case Constants.MethodChannel.argFocusGain:
            int res = await _recursiveCallback(_playerInstance.resume);
            if (res == 1) focusState = AudioFocusType.focus;
            break;
          case Constants.MethodChannel.argFocusLoss:
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.no_focus;
            break;
          case Constants.MethodChannel.argFocusLossTrans:
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            break;
          case Constants.MethodChannel.argFocusLossTransCanDuck:
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            // TODO: implement volume change
            break;
          default:
            throw Exception('Incorrect method argument came from native code');
        }
      } else if (call.method == Constants.MethodChannel.methodSendSongs) {
        // NOTE: cast method is must be here, `as` crashes code execution
        _getSongsFromChannel(call.arguments.cast<String>());
      } else if (call.method == Constants.MethodChannel.methodHookButtonClick) {
        // Avoid errors when app is loading
        if (songsReady) {
          DateTime now = DateTime.now();
          if (_latestHookPressTime == null ||
              now.difference(_latestHookPressTime) >
                  Duration(milliseconds: 600)) {
            // If hook is pressed first time or last press were more than 0.5s ago
            _latestHookPressTime = now;
            _hookPressStack = 1;
            _handleHookDelayedPress();
          } else if (_hookPressStack == 1 || _hookPressStack == 2) {
            // This condition ensures that nothing more than 3 will not be assigned to _hookPressStack
            _hookPressStack++;
          }
        }
      }
    });

    _init();
  }

  /// Play/pause, next or prev function depending on `_hookPressStack`
  void _handleHookDelayedPress() async {
    // Wait 0.5s
    await Future.delayed(Duration(milliseconds: 600));
    switch (_hookPressStack) {
      case 1:
        clickPausePlay();
        break;
      case 2:
        clickNext();
        break;
      case 3:
        clickPrev();
        break;
    }
    _hookPressStack = 0;
  }

// TODO: add implementation for this function and change method name to `get_intent_action_view`
  Future<void> _isIntentActionView() async {
    debugPrint((await _methodChannel
            .invokeMethod(Constants.MethodChannel.methodIntentActionView))
        .toString());
  }

  /// Request audio manager focus
  Future<void> _requestFocus() async {
    if (focusState == AudioFocusType.no_focus) {
      switch (await _methodChannel
          .invokeMethod<String>(Constants.MethodChannel.methodRequestFocus)) {
        case Constants.MethodChannel.returnRequestFail:
          focusState = AudioFocusType.no_focus;
          break;
        case Constants.MethodChannel.returnRequestGrant:
          focusState = AudioFocusType.focus;
          break;
        case Constants.MethodChannel.returnRequestDelay:
          focusState = AudioFocusType.focus_delayed;
          break;
      }
    }
  }

  /// Abandon audio manager focus
  Future<void> _abandonFocus() async {
    await _methodChannel
        .invokeMethod(Constants.MethodChannel.methodAbandonFocus);
    focusState = AudioFocusType.no_focus;
  }

// TODO: move notification methods to separate class maybe
  /// Method to show/update notification
  void _showNotification(
      {@required String title,
      @required String artist,
      @required bool isPlaying}) async {
    await _methodChannel.invokeMethod(
        Constants.MethodChannel.methodShowNotification,
        {"title": title, "artist": artist, "isPlaying": isPlaying});
  }

  /// Method to hide notification
  void _closeNotification() async {
    await _methodChannel
        .invokeMethod(Constants.MethodChannel.methodCloseNotification);
  }

  void switchLoopMode() async {
    var prefs = await SharedPreferences.getInstance();
    if (loopModeState) {
      _playerInstance.setReleaseMode(ReleaseMode.STOP);
      prefs.setBool(Constants.PrefKeys.loopModeBool, false);
    } else {
      _playerInstance.setReleaseMode(ReleaseMode.LOOP);
      prefs.setBool(Constants.PrefKeys.loopModeBool, true);
    }
    loopModeState = !loopModeState;
  }

  //TODO: add usage for set url method
  /// Play track
  ///
  /// `songId` argument denotes an id track to play
  Future<void> play(int songId) async {
    switching = true;
    await _requestFocus();
    int res = 0;
    try {
      if (focusState == AudioFocusType.focus)
        res = await _playerInstance.play(getSongById(songId).trackUri);
      else if (focusState == AudioFocusType.focus_delayed)
        // Set url if no focus has been granted
        res = await _playerInstance.setUrl(getSongById(songId).trackUri);
    } on PlatformException catch (e) {
      if (e.code == "error") {
        // If could not play for platform exception reasons
        debugPrint(
            'Error thrown in my player class play method - ${e.toString()}');
        // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
        // Play next track after broken one
        await _playerInstance.play(getSongById(getNextSongId(songId)).trackUri);
        _songs.removeAt(getSongIndexById(songId)); //Remove broken track
        _trackListChangeStreamController.emitEvent();
        fetchSongs(); // Perform fetching
      }
    } catch (e) {
      debugPrint(
          'Error thrown in my player class play method - ${e.toString()}');
    } finally {
      // If res is successful, then change playing track id
      if (res == 1)
        playingTrackIdState = songId;
      // If no focus has been granted or if error occured then set `switching` to false. In default case it is handled in `onDurationChanged` listener
      else
        switching = false;
    }
  }

  /// Resume player
  ///
  /// It handles errors the same way as play method above
  /// Positional optional argument `songId` is needed to jump to next track when handling error
  Future<void> resume([int songId]) async {
    // If `songId` hasn't been provided then use playing id state
    if (songId == null) songId = playingTrackIdState;
    switching = true;
    await _requestFocus();
    int res = 0;
    try {
      if (focusState == AudioFocusType.focus)
        res = await _playerInstance.resume();
      // Else if gainFocus is being handled in `setMethodCallHandler` listener above.
      //When delay is over android triggers AUDIOFOCUS_GAIN and track starts to play

      // Do nothing if no focus has been granted

    } on PlatformException catch (e) {
      if (e.code == "error") {
        // If could not play for platform exception reasons
        debugPrint(
            'Error thrown in my player class play method - ${e.toString()}');
        // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
        // Play next track after broken one
        await _playerInstance.play(getSongById(getNextSongId(songId)).trackUri);
        _songs.removeAt(getSongIndexById(songId)); //Remove broken track
        _trackListChangeStreamController.emitEvent();
        fetchSongs(); // Perform fetching
      }
    } catch (e) {
      debugPrint(
          'Error thrown in my player class play method - ${e.toString()}');
    } finally {
      // If res is successful, then change playing track id
      if (res == 1)
        playingTrackIdState = songId;
      // If no focus has been granted or if error occured then set `switching` to false. In default case it is handled in `onDurationChanged` listener
      else
        switching = false;
    }
  }

  /// Pause player
  Future<void> pause() async {
    final int result = await _playerInstance.pause();
    await _abandonFocus();
  }

  /// Stop player
  Future<void> stop() async {
    final int result = await _playerInstance.stop();
    // Change state if result is successful
    await _abandonFocus();
  }

  /// Seek
  Future<void> seek(int seconds) async {
    await _playerInstance.seek(Duration(seconds: seconds));
  }

  /// Returns song object by index in songs array
  Song getSongByIndex(int index) {
    _songsCheck();
    return _songs[index];
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    _songsCheck();
    return _songs.firstWhere((el) => el.id == id);
  }

  /// Returns song id in by its index in songs array
  int getSongIdByIndex(int index) {
    _songsCheck();
    return _songs[index].id;
  }

  /// Returns song index in array by its id
  int getSongIndexById(int id) {
    _songsCheck();
    return _songs.indexWhere((el) => el.id == id);
  }

  /// Returns song id in by its index in songs array
  int getSongIdByIndexInPlaylist(int index) {
    assert(_playList.isNotEmpty, "_playList is empty!");
    return _playList[index].id;
  }

  /// Returns song index in array by its id
  int getSongIndexByIdInPlaylist(int id) {
    assert(_playList.isNotEmpty, "_playList is empty!");
    return _playList.indexWhere((el) => el.id == id);
  }

  /// Returns next song index
  ///
  /// If optional `index` is provided, function will return incremented index
  int getNextSongId([int index]) {
    if (index == null) index = playingTrackIdState;
    if (_playList.isEmpty) {
      final int nextSongIndex = getSongIndexById(index) + 1;
      if (nextSongIndex >= songsCount) {
        return getSongIdByIndex(0);
      }
      return getSongIdByIndex(nextSongIndex);
    } else {
      final int nextSongIndex = getSongIndexByIdInPlaylist(index) + 1;
      if (nextSongIndex >= _playList.length) {
        return getSongIdByIndexInPlaylist(0);
      }
      return getSongIdByIndexInPlaylist(nextSongIndex);
    }
  }

  /// Returns prev song index
  ///
  /// If optional `index` is provided, function will return decremented index
  int getPrevSongId() {
    if (_playList.isEmpty) {
      final int prevSongIndex = getSongIndexById(playingTrackIdState) - 1;
      if (prevSongIndex < 0) {
        return getSongIdByIndex(songsCount - 1);
      }
      return getSongIdByIndex(prevSongIndex);
    } else {
      final int prevSongIndex =
          getSongIndexByIdInPlaylist(playingTrackIdState) - 1;
      if (prevSongIndex < 0) {
        return getSongIdByIndexInPlaylist(_playList.length - 1);
      }
      return getSongIdByIndexInPlaylist(prevSongIndex);
    }
  }

  /// Function that fires when pause/play button got clicked
  void clickPausePlay() async {
    debugPrint(switching.toString());
    // TODO: refactor
    if (!switching) {
      switch (playState) {
        case AudioPlayerState.PLAYING:
          await pause();
          break;
        case AudioPlayerState.PAUSED:
          await resume();
          break;
        case AudioPlayerState.STOPPED:
          // Currently unused and shouldn't
          await play(playingTrackIdState);
          break;
        case AudioPlayerState.COMPLETED:
          await play(playingTrackIdState);
          break;
        default:
          // throw Exception('Invalid player state variant');
          break;
      }
    }
  }

  /// Function that fires when next track button got clicked
  Future<void> clickNext() async {
    if (!switching) await play(getNextSongId());
  }

  /// Function that fires when prev track button got clicked
  Future<void> clickPrev() async {
    if (!switching) await play(getPrevSongId());
  }

  /// Function that handles click on track tile
  ///
  /// `clickedSongId` argument denotes an id of clicked track `TrackList`
  Future<void> clickTrackTile(int clickedSongId) async {
    if (!switching) {
      switch (playState) {
        case AudioPlayerState.PLAYING:
          // If user clicked the same track
          if (playingTrackIdState == clickedSongId)
            await pause();
          // If user decided to click a new track
          else
            await play(clickedSongId);
          break;
        case AudioPlayerState.PAUSED:
          // If user clicked the same track
          if (playingTrackIdState == clickedSongId)
            await resume(clickedSongId);
          // If user decided to click a new track
          else
            await play(clickedSongId);
          break;
        case AudioPlayerState.STOPPED:
          // Currently unused and should't
          await play(clickedSongId);
          break;
        case AudioPlayerState.COMPLETED:
          await play(clickedSongId);
          break;
        default:
          // All other case, e.g. null or state after error
          await play(clickedSongId);
          break;
      }
    }
  }

  /// Search in song array by query
  Iterable<Song> searchSongs(String query) {
    if (query != '') {
      // Lowercase to bring strings to one format
      query = query.toLowerCase();
      return _songs.where((el) =>
          el.title.toLowerCase().contains(query) ||
          el.artist.toLowerCase().contains(query) ||
          el.album.toLowerCase().contains(query));
    }
    return null;
  }

  void setPlaylist(List<Song> songs) {
    // FIXME: try to optimize this, add some comparison e.g
    _playList = songs;
  }

  void resetPlaylist() {
    _playList = [];
  }

  /// Sort song by feature
  void sortSongs(SortFeature feature) {
    _songsCheck();
    switch (feature) {
      case SortFeature.date:
        _songs.sort((a, b) => b.dateModified.compareTo(a.dateModified));
        break;
      case SortFeature.title:
        _songs.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    // Emit event to track change stream
    _trackListChangeStreamController.emitEvent();
  }

  // TODO: refactor next 3 functions
  ///
  _initSongsJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/songs.json');
    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(jsonEncode([]));
    } else if (await file.readAsString() == "") {
      await file.writeAsString(jsonEncode([]));
    }
  }

  _readSongsJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/songs.json');
      String jsonContent = await file.readAsString();
      _songs = [...jsonDecode(jsonContent).map((el) => Song.fromJson(el))];
    } catch (e) {
      _songs = []; // Set empty array if error has been caught
      debugPrint('Error reading songs json, setting to empty songs list');
    }
  }

  _saveSongsJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/songs.json');
    var jsonContent = jsonEncode(_songs);
    await file.writeAsString(jsonContent);
    debugPrint('Json saved');
  }

  /// Init whole music instance
  _init() async {
    await _initSongsJson();
    await _readSongsJson();

    // Get saved data
    var prefs = await SharedPreferences.getInstance();
    var savedSongId = prefs.getInt(Constants.PrefKeys.songIdInt);
    var savedSongPos = prefs.getInt(Constants.PrefKeys.songPositionInt);
    var savedLoopMode = prefs.getBool(Constants.PrefKeys.loopModeBool);

    // Set loop mode to true if it is true in prefs
    if (savedLoopMode != null && savedLoopMode) {
      loopModeState = savedLoopMode;
      _playerInstance.setReleaseMode(ReleaseMode.LOOP);
    }

    // Permissions
    // TODO: add button to re-request permissions
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    Map<PermissionGroup, PermissionStatus> permissions;
    if (permission == PermissionStatus.denied)
      permissions = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);

    if (!songsEmpty) {
      // songsEmpty condition is here to avoid errors when trying to get first song index
      // Setup initial playing state index from prefs
      playingTrackIdState = savedSongId ?? getSongIdByIndex(0);

      try {
        // Set url of first track in player instance
        await _playerInstance.setUrl(currentSong.trackUri);
      } catch (e) {
        // playingTrackIdState =
        //     null; // Set to null to display that there's no currently playing track and user could not go to player route (NOTE: THIS IS VERY UNRELIABLE)
        debugPrint('Wasn\'t able to set url to _playerInstance');
      }

      // Seek to saved position
      if (savedSongPos != null)
        _playerInstance.seek(Duration(seconds: savedSongPos));
    }

    // Init player state
    await _playerInstance.pause();

    // Emit event to track change stream
    _trackListChangeStreamController.emitEvent();

    await fetchSongs();

    // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (playingTrackIdState == null)
    if (!songsEmpty && playingTrackIdState == null) {
      // Setup initial playing state index from prefs
      playingTrackIdState = savedSongId ?? getSongIdByIndex(0);

      try {
        // Set url of first track in player instance
        await _playerInstance.setUrl(currentSong.trackUri);
      } catch (e) {
        // playingTrackIdState =
        //     null; // Set to null to display that there's no currently playing track and user could not go to player route (NOTE: THIS IS VERY UNRELIABLE)
        debugPrint('Wasn\'t able to set url to _playerInstance');
      }

      // Seek to saved position
      if (savedSongPos != null)
        _playerInstance.seek(Duration(seconds: savedSongPos));
    }
  }

  /// Finds songs on user device
  Future<void> fetchSongs() async {
    // _songs.removeWhere(
    //     // Remove all elements whose duration is shorter than 30 seconds
    //     (item) => item.duration < Duration(seconds: 30).inMilliseconds);
    // Emit event
    searchingState = true;

    await _methodChannel
        .invokeMethod<String>(Constants.MethodChannel.methodRetrieveSongs);

    return await searchingOperation.doOperation();
  }

  /// Method that asserts that `_songs` is not `null`
  void _songsCheck() {
    assert(songsReady,
        '_songs is null, probably because it is not initilized by fetchSongs');
  }
}

/// TODO: improve this class
class AsyncOperation {
  Completer _completer = Completer();

  // Send future object back to client.
  Future<void> doOperation() {
    return _completer.future;
  }

  // Something calls this when the value is ready.
  void finishOperation() {
    _completer.complete();
    _completer = Completer(); // Update completer
  }

  // If something goes wrong, call this.
  void errorHappened(error) {
    _completer.completeError(error);
  }
}

/// Component to show artist, or automatically show "Неизвестный исоплнитель" instead of "<unknown>"
class Artist extends StatelessWidget {
  final String artist;
  const Artist({Key key, @required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        artist != '<unknown>' ? artist : 'Неизестный исполнитель',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          //Default flutter subtitle font size (not densed)
          fontSize: 14,
          // This is used in ListTile elements
          color: Theme.of(context).textTheme.caption.color,
        ),
      ),
    );
  }
}

/// Function that returns artist, or automatically show "Неизвестный исоплнитель" instead of "<unknown>"
String artistString(String artist) =>
    artist != '<unknown>' ? artist : 'Неизестный исполнитель';

/// Class to create change and control stream
class _TrackListChangeStreamController {
  /// Stream controller used to create stream of changes on track list (just to notify)
  StreamController _controller = StreamController<void>.broadcast();

  /// Emit change event
  void emitEvent() {
    _controller.add(null);
  }
}
