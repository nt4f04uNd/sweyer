import 'dart:async';
import 'package:app/components/albumArt.dart';
import 'package:app/components/animatedPlayPauseButton.dart';
import 'package:app/components/popup_menu.dart' as customPopup;
import 'package:app/components/track_list.dart';
import 'package:app/components/marquee.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/prefs.dart';
import 'package:app/routes/exifRoute.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

Route createPlayerRoute() {
  return PageRouteBuilder(
    // TODO: move this into separate module that will contain all page `PageRouteBuilder`s
    transitionDuration: Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(0.0, 1.0);
      var end = Offset.zero;
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

class _PlayerRouteState extends State<PlayerRoute>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final GlobalKey<_PlaylistTabState> _playlistTabKey =
      GlobalKey<_PlaylistTabState>();
  final int _tabsLength = 2;
  int openedTabIndex = 0;
  int prevTabIndex = 0;
  bool isChangingTabIndex = false;
  bool initialRender = true;

  @override
  void initState() {
    super.initState(); // TODO: add comments
    _tabController = TabController(vsync: this, length: _tabsLength);
    _tabController.addListener(() {
      setState(() {
        if (openedTabIndex != _tabController.index)
          openedTabIndex = _tabController.index;
        if (isChangingTabIndex != _tabController.indexIsChanging)
          isChangingTabIndex = _tabController.indexIsChanging;
        if (openedTabIndex == 0 && initialRender ||
            _tabController.previousIndex == 1) {
          if (initialRender) initialRender = false;
          _playlistTabKey.currentState.jumpOnTabChange();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        MainPlayerTab(),
        _PlaylistTab(
            key: _playlistTabKey,
            openedTabIndex: openedTabIndex,
            isChangingTabIndex: isChangingTabIndex)
      ],
    );
  }
}

class _PlaylistTab extends StatefulWidget {
  final int openedTabIndex;
  final bool isChangingTabIndex;
  _PlaylistTab(
      {Key key,
      @required this.openedTabIndex,
      @required this.isChangingTabIndex})
      : super(key: key);

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

/// TODO: FIXME: add comments refactor add typedefs do renaming
/// TODO: add animation to scroll button show/hide
enum ScrollButtonType { up, down }

class _PlaylistTabState extends State<_PlaylistTab>
    with AutomaticKeepAliveClientMixin<_PlaylistTab> {
  @override
  bool get wantKeepAlive => true;

  /// How much tracks to ignore scrolling
  static const int tracksScrollOffset = 6;
  static const Duration scrollDuration = const Duration(milliseconds: 600);

  GlobalKey<CurrentPlaylistWidgetState> globalKeyCurrentPlaylistWidget =
      GlobalKey();

  /// A bool var to disable show/hide in tracklist controller listener when manual `scrollToSong` is performing
  bool scrolling = false;
  ScrollButtonType scrollButtonType = ScrollButtonType.up;
  StreamSubscription<void> _songChangeSubscription;
  StreamSubscription<void> _playlistChangeSubscription;

  int prevPlayingIndex = PlaylistControl.currentSongIndex();

  @override
  void initState() {
    super.initState();
    _playlistChangeSubscription =
        PlaylistControl.onPlaylistListChange.listen((event) async {
      // Reset value when playlist changes
      prevPlayingIndex = PlaylistControl.currentSongIndex();
      // Jump when tracklist changes (e.g. shuffle happened)
      jumpToSong();
    });
    _songChangeSubscription =
        PlaylistControl.onSongChange.listen((event) async {
      // Scroll when track changes
      if (widget.openedTabIndex == 0){
      setState((){});
        await performScrolling();
      }
      else if (widget.openedTabIndex == 1) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _playlistChangeSubscription.cancel();
    _songChangeSubscription.cancel();
  }

  /// Scrolls to current song
  ///
  /// If optional `index` is provided - scrolls to it
  Future<void> scrollToSong([int index]) async {
    if (index == null) index = PlaylistControl.currentSongIndex();

    await globalKeyCurrentPlaylistWidget.currentState.itemScrollController
        .scrollTo(
            index: index, duration: scrollDuration, curve: Curves.easeInOut);
    // Call `jumpTo` to reset scroll controller offset
    globalKeyCurrentPlaylistWidget.currentState.itemScrollController
        .jumpTo(index: index);
  }

  /// Jumps to current song
  ///
  /// If optional `index` is provided - jumps to it
  void jumpToSong([int index]) async {
    if (index == null) index = PlaylistControl.currentSongIndex();

    globalKeyCurrentPlaylistWidget.currentState.itemScrollController
        .jumpTo(index: index);
  }

  /// A more complex function with additional checks
  Future<void> performScrolling() async {
    final int playlistLength = PlaylistControl.length();
    final int playingIndex = PlaylistControl.currentSongIndex();
    final int maxScrollIndex = playlistLength - 1 - tracksScrollOffset;

    // Exit immediately if index didn't change
    if (prevPlayingIndex == playingIndex) return;

    // If playlist is longer than e.g. 6
    if (playlistLength > tracksScrollOffset) {
      if (prevPlayingIndex >= maxScrollIndex && playingIndex == 0) {
        // When prev track was last in playlist
        jumpToSong();
      } else if (playingIndex == 0) {
        setState(() {
          // Trigger setstate
        });
        // Call `frontScrollController`'s animate as `scrollTo` gives ragged animation on first list element
        await globalKeyCurrentPlaylistWidget.currentState.frontScrollController
            .animateTo(
                globalKeyCurrentPlaylistWidget.currentState
                    .frontScrollController.position.minScrollExtent,
                duration: scrollDuration,
                curve: Curves.easeInOut);

        jumpToSong(); // Reset scrollcontroller's position
      } else if (playingIndex < maxScrollIndex) {
        // Scroll to current song and tapped track is in between range [0:playlistLength - offset]
        await scrollToSong();
      } else if (prevPlayingIndex > maxScrollIndex) {
        // Do nothing when it is already scrolled to `maxScrollIndex`
        return;
      } else if (playingIndex >= maxScrollIndex) {
        if (prevPlayingIndex == 0)
          jumpToSong(maxScrollIndex);
        // If at the end of the list
        else
          await scrollToSong(maxScrollIndex);
      }
      prevPlayingIndex = playingIndex;
    }
  }

  /// Jump to song when changing tab to `0`
  Future<void> jumpOnTabChange() async {
    final int playlistLength = PlaylistControl.length();
    final int playingIndex = PlaylistControl.currentSongIndex();
    final int maxScrollIndex = playlistLength - 1 - tracksScrollOffset;

    // If playlist is longer than e.g. 6
    if (playlistLength > tracksScrollOffset) {
      if (playingIndex < maxScrollIndex) {
        jumpToSong();
      } else if (playingIndex >= maxScrollIndex) {
        // If at the end of the list
        jumpToSong(maxScrollIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
        stream: PlaylistControl.onPlaylistListChange,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(80.0), // here the desired height
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: AppBar(
                  title: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Далее',
                        style: TextStyle(fontSize: 24),
                      ),
                      PlaylistControl.playlistType == PlaylistType.global
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                'Основной плейлист',
                                style: TextStyle(fontSize: 14),
                              ),
                            )
                          : PlaylistControl.playlistType ==
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
              child: CurrentPlaylistWidget(
                key: globalKeyCurrentPlaylistWidget,
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
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  /// Key for `MarqueeWidget` to reset its scroll on song change
  UniqueKey marqueeKey = UniqueKey();

  StreamSubscription<void> _changeSongSubscription;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    // Handle track switch
    _changeSongSubscription = PlaylistControl.onSongChange.listen((event) {
      // Create new key for marque widget to reset scroll
      marqueeKey = UniqueKey();
      setState(() {
        _duration =
            Duration(milliseconds: PlaylistControl.currentSong?.duration);
      });
    });
  }

  @override
  void dispose() {
    _changeSongSubscription.cancel();
    super.dispose();
  }

  Future<void> _setInitialCurrentPosition() async {
    setState(() {
      _duration = Duration(milliseconds: PlaylistControl.currentSong?.duration);
    });
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
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: Color(0xff121212),
                  ),
                  child: customPopup.CustomPopupMenuButton<void>(
                    // NOTE https://api.flutter.dev/flutter/material/PopupMenuButton-class.html
                    onSelected: (_) {
                      Navigator.of(context).push(createExifRoute(widget));
                    },
                    padding: const EdgeInsets.all(0.0),
                    itemBuilder: (BuildContext context) =>
                        <customPopup.PopupMenuEntry<void>>[
                      customPopup.PopupMenuItem<void>(
                        value: '',
                        // height: 30.0,
                        child: Text('Изменить информацию о треке'),
                      ),
                    ],
                  ),
                ),
              )
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
                            PlaylistControl.currentSong?.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 21),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 30),
                        child: Text(
                          artistString(PlaylistControl.currentSong?.artist),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 10),
                        child: AlbumArt(
                          path: PlaylistControl.currentSong?.albumArtUri,
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
                      child: TrackSlider(
                        duration: _duration,
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
                          color: PlaylistControl.playlistType ==
                                  PlaylistType.shuffled
                              ? null
                              : Colors.grey.shade800,
                          onPressed: () {
                            setState(() {
                              if (PlaylistControl.playlistType ==
                                  PlaylistType.shuffled)
                                PlaylistControl.resetPlaylists();
                              else
                                PlaylistControl.setShuffledPlaylist();
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
                                    onTap: MusicPlayer.clickPrev,
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
                                    onTap: MusicPlayer.clickNext,
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
                          color: MusicPlayer.loopModeState
                              ? null
                              : Colors.grey.shade800,
                          onPressed: () {
                            setState(() {
                              MusicPlayer.switchLoopMode();
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

class TrackSlider extends StatefulWidget {
  final Duration duration;
  TrackSlider({Key key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  _TrackSliderState createState() => _TrackSliderState();
}

class _TrackSliderState extends State<TrackSlider> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);

  /// Value to perform drag
  double _localValue;

  SharedPreferences prefs;

  /// Subscription for audio position change stream
  /// TODO: move all this stuff into separate class (e.g. inherited widget) as it is also used in bottom track panel
  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<void> _changeSongSubscription;

  /// Is user dragging slider right now
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();
    _getPrefsInstance();

    // Handle track position movement
    _changePositionSubscription =
        MusicPlayer.onAudioPositionChanged.listen((event) {
      if (event.inSeconds - 0.9 > _value.inSeconds && !_isDragging) {
        // Prevent waste updates
        setState(() {
          _value = event;
          if (prefs != null)
            Prefs.byKey.songPositionInt.setPref(_value.inSeconds, prefs);
        });
      } else if (event.inMilliseconds < 200) {
        setState(() {
          _isDragging = false;
          _localValue = event.inSeconds.toDouble();
          _value = event;
        });
      }
    });

    // Handle track switch
    _changeSongSubscription = PlaylistControl.onSongChange.listen((event) {
      setState(() {
        _isDragging = false;
        _localValue = 0.0;
        _value = Duration(seconds: 0);
      });
    });
  }

  @override
  void dispose() {
    _changePositionSubscription.cancel();
    _changeSongSubscription.cancel();
    super.dispose();
  }

  Future<void> _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.currentPosition;
    setState(() {
      _value = currentPosition;
    });
  }

  void _getPrefsInstance() async {
    prefs = await Prefs.sharedInstance;
  }

  // Drag functions
  void _handleChangeStart(double newValue) async {
    setState(() {
      _isDragging = true;
      _localValue = newValue;
    });
  }

  void _handleChanged(double newValue) {
    setState(() {
      if (!_isDragging) _isDragging = true;
      _localValue = newValue;
    });
  }

  /// FIXME: this called multiple times since it is inside `TabBarView`, currently unable to fix, as this issue relies deeply to flutter architecture
  void _handleChangeEnd(double newValue) async {
    // if (_isDragging) {
    await MusicPlayer.seek(newValue.toInt());
    setState(() {
      _isDragging = false;
      _value = Duration(seconds: newValue.toInt());
    });
    // }
  }

  String _calculateDisplayedPositionTime() {
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
    int minutes = widget.duration.inMinutes;
    // Seconds in 0-59 format
    int seconds = widget.duration.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value: _isDragging ? _localValue : _value.inSeconds.toDouble(),
            // value: _value.inSeconds.toDouble(),
            max: widget.duration.inSeconds.toDouble(),
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
    ));
  }
}
