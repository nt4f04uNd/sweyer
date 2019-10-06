import 'dart:async';
import 'package:app/components/albumArt.dart';
import 'package:app/components/animatedPlayPauseButton.dart';
import 'package:app/components/track_list.dart';
import 'package:app/constants/constants.dart' as Constants;
import 'package:app/heroes/albumArtHero.dart';
import 'package:app/components/marquee.dart';
import 'package:app/player/playlist.dart';
import 'package:app/routes/exifRoute.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

Route createPlayerRoute() {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(0.0, 1.0);
      var end = Offset.zero;
      // var curve = Curves.fastLinearToSlowEaseIn;
      var curve = Curves.fastOutSlowIn;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return PlayerRoute();
    },
  );
}

class PlayerRoute extends StatefulWidget {
  @override
  _PlayerRouteState createState() => _PlayerRouteState();
}

class _PlayerRouteState extends State<PlayerRoute> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: TabBarView(children: [
        MainPlayerTab(),
        _PlaylistTab()
        // Scaffold(
        //   body: TrackList2(),
        // )
      ]),
    );
  }
}

class _PlaylistTab extends StatefulWidget {
  @override
  __PlaylistTabState createState() => __PlaylistTabState();
}

/// TODO: FIXME: add comments refactor add typedefs do renaming
/// TODO: add animation to scroll button show/hide
enum ScrollButtonType { up, down }

class __PlaylistTabState extends State<_PlaylistTab>
    with AutomaticKeepAliveClientMixin<_PlaylistTab> {
  @override
  bool get wantKeepAlive => true;

  /// How much tracks to ignore scrolling
  static const int tracksScrollOffset = 6;
  static const Duration scrollDuration = const Duration(milliseconds: 600);

  GlobalKey<TrackListState2> globalKeyTrackList = GlobalKey();

  bool scrollButtonShown = false;

  /// A bool var to disable show/hide in tracklist controller listener when manual `scrollToSong` is performing
  bool scrolling = false;
  ScrollButtonType scrollButtonType = ScrollButtonType.up;
  StreamSubscription<void> _songChangeSubscription;
  StreamSubscription<void> _playlistChangeSubscription;

  int prevPlayingIndex =
      MusicPlayer.instance.playlistControl.currentSongIndex();

  void showHideScrollButton(bool value, [ScrollButtonType scrollButtonType]) {
    setState(() {
      this.scrollButtonShown = value;
      if (scrollButtonType != null) this.scrollButtonType = scrollButtonType;
    });
  }

  /// Scrolls to current song
  ///
  /// If optional `index` is provided - scrolls to it
  Future<void> scrollToSong([int index]) async {
    if (!scrolling) {
      if (index == null)
        index = MusicPlayer.instance.playlistControl.currentSongIndex();

      setState(() {
        scrolling = true;
      });
      Future.delayed(
          // Set a future to resolve `scrolling` to false after scroll performed
          scrollDuration,
          () => setState(() {
                scrolling = false;
              }));
      showHideScrollButton(false);
      await globalKeyTrackList.currentState.itemScrollController.scrollTo(
          index: index, duration: scrollDuration, curve: Curves.easeInOut);
      // Call `jumpTo` to reset scroll controller offset
      globalKeyTrackList.currentState.itemScrollController.jumpTo(index: index);
    }
  }

  /// Jumps to current song
  ///
  /// If optional `index` is provided - jumps to it
  void jumpToSong([int index]) async {
    if (index == null)
      index = MusicPlayer.instance.playlistControl.currentSongIndex();

    showHideScrollButton(false);
    globalKeyTrackList.currentState.itemScrollController.jumpTo(index: index);
  }

  /// A more complex funtion with additional checks
  Future<void> performScrolling() async {
    final int playlistLength = MusicPlayer.instance.playlistControl.length();

    final int playingIndex =
        MusicPlayer.instance.playlistControl.currentSongIndex();

    if (playlistLength > tracksScrollOffset) {
      // If playlist is longer than 12
      if (prevPlayingIndex == 0 && playingIndex == playlistLength - 1) {
        // Scroll to bottom from first track
        jumpToSong(playlistLength - 1 - tracksScrollOffset);
      } else if (playingIndex == 0) {
        //  await scrollToSong(0);
        setState(() {
          scrolling = scrolling; // Trigger setstate
        });
        // Call `frontScrollController`'s animate as `scrollTo` gives ragged animation on first list element
        await globalKeyTrackList.currentState.frontScrollController.animateTo(
            globalKeyTrackList
                .currentState.frontScrollController.position.minScrollExtent,
            duration: scrollDuration,
            curve: Curves.easeInOut);

        jumpToSong(); // Reset scrollcontroller's position
      } else if (prevPlayingIndex == playlistLength - 1 && playingIndex == 0) {
        // When prev track was last in playlist
        jumpToSong();
      } else if (playingIndex < playlistLength - tracksScrollOffset) {
        // Scroll to current song and tapped track is in between range [0:playlistLength - offset]
        await scrollToSong();
      } else if (playingIndex >= playlistLength - 1 - tracksScrollOffset) {
        // If at the end of the list
        await scrollToSong(playlistLength - 1 - tracksScrollOffset);
      }
    }
    prevPlayingIndex = playingIndex;
  }

  @override
  void initState() {
    super.initState();
    _playlistChangeSubscription =
        MusicPlayer.instance.onPlaylistListChange.listen((event) async {
      // Reset value when playlist changes
      prevPlayingIndex =
          MusicPlayer.instance.playlistControl.currentSongIndex();
      // Jump when tracklist changes (e.g. shuffle happened)
      jumpToSong();
    });
    _songChangeSubscription =
        MusicPlayer.instance.onSongChange.listen((event) async {
      // Scroll when track changes
      await performScrolling();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _playlistChangeSubscription.cancel();
    _songChangeSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: MusicPlayer.instance.onPlaylistListChange,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(80.0), // here the desired height
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: AppBar(
                  actions: <Widget>[
                    Visibility(
                      visible: scrollButtonShown,
                      maintainState: true,
                      maintainAnimation: true,
                      child: AnimatedOpacity(
                        opacity: scrollButtonShown ? 1 : 0,
                        duration: Duration(milliseconds: 600),
                        child: IconButton(
                            splashColor: Colors.transparent,
                            icon: scrollButtonType == ScrollButtonType.up
                                ? Icon(Icons.keyboard_arrow_up)
                                : Icon(Icons.keyboard_arrow_down),
                            onPressed: performScrolling),
                      ),
                    )
                  ],
                  title: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Далее',
                        style: TextStyle(fontSize: 24),
                      ),
                      MusicPlayer.instance.playlistControl.playlistType ==
                              PlaylistType.global
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                'Основной плейлист',
                                style: TextStyle(fontSize: 14),
                              ),
                            )
                          : MusicPlayer.instance.playlistControl.playlistType ==
                                  PlaylistType.shuffled
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    'Перемешанный плейлист',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    'Найденный плейлист',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )
                    ],
                  ),
                  automaticallyImplyLeading: false,
                ),
              ),
            ),
            body: Container(
              padding: const EdgeInsets.only(top: 4.0),
              child: TrackList2(
                key: globalKeyTrackList,
                showHideScrollButton: showHideScrollButton,
                scrollButtonShown: scrollButtonShown,
                scrolling: scrolling,
              ),
            ),
          );
        });
  }
}

class MainPlayerTab extends StatefulWidget {
  MainPlayerTab({Key key}) : super(key: key);

  _MainPlayerTabState createState() => _MainPlayerTabState();
}

class _MainPlayerTabState extends State<MainPlayerTab> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  /// Value to perform drag
  double _localValue;

  /// Subscription for audio position change stream
  /// TODO: move all this stuff into separate class (e.g. inherited widget) as it is also used in bottom track panel
  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<void> _changeSongSubscription;

  /// Is user dragging slider right now
  bool _isDragging = false;
  // MusicPlayer MusicPlayer.instance = MusicPlayer.instance;
  SharedPreferences prefs;

  /// Key for `MarqueeWidget` to reset its scroll on song change
  UniqueKey marqueeKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();
    _getPrefsInstance();

    // Handle track position movement
    _changePositionSubscription =
        MusicPlayer.instance.onAudioPositionChanged.listen((event) {
      if (event.inSeconds - 0.9 > _value.inSeconds) // Prevent waste updates
        setState(() {
          _value = event;
          if (prefs != null)
            prefs.setInt(Constants.PrefKeys.songPositionInt, _value.inSeconds);
        });
      else if (event.inMilliseconds < 200) {
        setState(() {
          _value = event;
        });
      }
    });

    // Handle track swtich
    _changeSongSubscription = MusicPlayer.instance.onSongChange.listen((event) {
      // Create new key for marque widget to reset scroll
      marqueeKey = UniqueKey();
      setState(() {
        _value = Duration(seconds: 0);
        _duration = Duration(
            milliseconds:
                MusicPlayer.instance.playlistControl.currentSong.duration);
      });
    });
  }

  @override
  void dispose() {
    _changePositionSubscription.cancel();
    _changeSongSubscription.cancel();
    super.dispose();
  }

  void _getPrefsInstance() async {
    prefs = await SharedPreferences.getInstance();
  }

  _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.instance.currentPosition;
    setState(() {
      _value = currentPosition;
      _duration = Duration(
          milliseconds:
              MusicPlayer.instance.playlistControl.currentSong.duration);
    });
  }

  // Drag functions
  void _handleChangeStart(double newValue) async {
    print('_isDragging1 $_isDragging');
    setState(() {
      _isDragging = true;
      _localValue = newValue;
    });
    print('_isDragging2 $_isDragging');
  }

  void _handleChanged(double newValue) {
    setState(() {
      _isDragging = true;
      _localValue = newValue;
    });
  }

  void _handleChangeEnd(double newValue) async {
    await MusicPlayer.instance.seek(newValue.toInt());
    setState(() {
      _isDragging = false;
      _value = Duration(seconds: newValue.toInt());
    });
  }

  String _calculateDisplayedPositionTime() {
    // print(_isDragging);
    /// Value to work with, depends on `_isDragging` state, either `_value` or `_localValue`
    Duration workingValue;
    if (_isDragging) // Update time indicator when dragging
      workingValue = Duration(seconds: _localValue.toInt());
    else
      workingValue = _value;

    int minutes = workingValue.inMinutes;
    // Seconds in 0-59 format
    int seconds = workingValue.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  String _calculateDisplayedDurationTime() {
    int minutes = _duration.inMinutes;
    // Seconds in 0-59 format
    int seconds = _duration.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(63.0), // here the desired height
          child: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.pop(context, false),
            ),
            actions: <Widget>[
              Theme(
                data: Theme.of(context).copyWith(
                    cardColor: Color(0xff151515),
                    cardTheme: CardTheme(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(100),
                      ),
                    ))),
                child: PopupMenuButton<void>(
                  // NOTE https://api.flutter.dev/flutter/material/PopupMenuButton-class.html
                  onSelected: (dynamic result) {
                    Navigator.of(context).push(createExifRoute(widget));
                    // Navigator.push(
                    //     context,
                    //     PageTransition(
                    //         type: PageTransitionType.rightToLeftWithFade,
                    //         child: ExifRoute()));
                  },
                  padding: const EdgeInsets.all(0.0),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      value: '',
                      height: 30.0,
                      child: Transform.translate(
                          offset: Offset(0.0, 10.0),
                          child: Text('Изменить информацию о треке')),
                    ),
                  ],
                ),
              )
              // IconButton(
              //   icon: Icon(Icons.more_vert),
              //   // onPressed: () => Navigator.of(context)
              //   //     .push(createExifRoute(widget)),

              // ),
            ],
            automaticallyImplyLeading: false,
          ),
        ),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: MarqueeWidget(
                          key: marqueeKey,
                          text: Text(
                            MusicPlayer
                                .instance.playlistControl.currentSong.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 21),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 30),
                        child: Text(
                          artistString(MusicPlayer
                              .instance.playlistControl.currentSong.artist),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 10),
                        child: AlbumArt(
                          path: MusicPlayer
                              .instance.playlistControl.currentSong.albumArtUri,
                          isLarge: true,
                        ),
                      ),
                    ]),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            transform: Matrix4.translationValues(5, 0, 0),
                            child: Text(
                              // TODO: move and refactor this code, and by the way split a whole page into separate widgets
                              _calculateDisplayedPositionTime(),
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.deepPurple,
                              inactiveColor: Colors.white.withOpacity(0.2),
                              value: _isDragging
                                  ? _localValue
                                  : _value.inSeconds.toDouble(),
                              max: _duration.inSeconds.toDouble(),
                              min: 0,
                              onChangeStart: _handleChangeStart,
                              onChanged: _handleChanged,
                              onChangeEnd: _handleChangeEnd,
                            ),
                          ),
                          Container(
                            transform: Matrix4.translationValues(-5, 0, 0),
                            child: Text(
                              _calculateDisplayedDurationTime(),
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 40, top: 10, left: 20, right: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.shuffle),
                          color: MusicPlayer
                                      .instance.playlistControl.playlistType ==
                                  PlaylistType.shuffled
                              ? null
                              : Colors.grey.shade800,
                          onPressed: () {
                            setState(() {
                              if (MusicPlayer
                                      .instance.playlistControl.playlistType ==
                                  PlaylistType.shuffled)
                                MusicPlayer.instance.playlistControl
                                    .resetPlaylists();
                              else
                                MusicPlayer.instance.playlistControl
                                    .setShuffledPlaylist();
                            });
                          },
                        ),
                        Expanded(
                          child: Container(
                            // padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: InkWell(
                                    radius: 50,
                                    borderRadius: BorderRadius.circular(100),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.skip_previous,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    onTap: MusicPlayer.instance.clickPrev,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1,
                                        color: Colors.white.withOpacity(0.15)),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: AnimatedPlayPauseButton(),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1,
                                        color: Colors.white.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: InkWell(
                                    radius: 50,
                                    borderRadius: BorderRadius.circular(100),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.skip_next,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    onTap: MusicPlayer.instance.clickNext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox.fromSize(
                        //   size: Size.square(48),
                        // )
                        IconButton(
                          icon: Icon(Icons.loop),
                          color: MusicPlayer.instance.loopModeState
                              ? null
                              : Colors.grey.shade800,
                          onPressed: () {
                            setState(() {
                              MusicPlayer.instance.switchLoopMode();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
