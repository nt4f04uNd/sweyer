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

// class _PlaylistTab extends StatefulWidget {
//   const _PlaylistTab({Key key}) : super(key: key);

//   @override
//   __PlaylistTabState createState() => __PlaylistTabState();
// }

// class __PlaylistTabState extends State<_PlaylistTab> {
//   @override
//   Widget build(BuildContext context) {
//     print('fwqfwq');
//     return Scaffold(
//       body: Container(
//           child: TrackList2(
//               // getOffsetMethod: () => listViewOffset,
//               // setOffsetMethod: (offset) => this.listViewOffset = offset,
//               )),
//     );
//   }
// }

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

  GlobalKey<TrackListState2> globalKey = GlobalKey();

  bool scrollButtonShown = false;
  ScrollButtonType scrollButtonType = ScrollButtonType.up;
  StreamSubscription<Duration> durationChangeSubscription;
  Duration prevDuration = Duration(seconds: 0);

  void showHideScrollButton(bool value, [ScrollButtonType scrollButtonType]) {
    setState(() {
      this.scrollButtonShown = value;
      if (scrollButtonType != null) this.scrollButtonType = scrollButtonType;
    });
  }

  void scrollToCurrentSong() {
    globalKey.currentState.itemScrollController.jumpTo(
        index: MusicPlayer.instance.playlistControl.playlist.getSongIndexById(
            MusicPlayer.instance.playlistControl.currentSong.id));
  }

  @override
  void initState() {
    super.initState();
    durationChangeSubscription =
        MusicPlayer.instance.onDurationChanged.listen((event) {
      if (prevDuration != event) {
        prevDuration = event;
        scrollToCurrentSong(); // TODO: FIXME: add better self written swtich event stream
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    durationChangeSubscription.cancel();
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
                    scrollButtonShown
                        ? IconButton(
                            icon: Icon(scrollButtonType == ScrollButtonType.up
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down),
                            onPressed: scrollToCurrentSong)
                        : SizedBox.shrink()
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
              child: TrackList2(
                key: globalKey,
                showHideScrollButton: showHideScrollButton,
                scrollButtonShown: scrollButtonShown,
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
                    child: TrackSlider(),
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
                                    .resetPlaylist();
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

class TrackSlider extends StatefulWidget {
  TrackSlider({Key key}) : super(key: key);

  _TrackSliderState createState() => _TrackSliderState();
}

class _TrackSliderState extends State<TrackSlider> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  int seconds = 0;

  /// Value to perform drag
  double _localValue;

  /// Subscription for audio position change stream
  /// TODO: move all this stuff into separate class (e.g. inherited widget) as it is also used in bottom track panel
  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<dynamic> _changeDurationSubscription;

  /// Is user dragging slider right now
  bool _isDragging = false;
  // MusicPlayer MusicPlayer.instance = MusicPlayer.instance;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();
    _getPrefsInstance();

    // Handle track position movement
    _changePositionSubscription =
        MusicPlayer.instance.onAudioPositionChanged.listen((event) {
      // print("${event.inSeconds - 5}, ${this._value.inSeconds}, $seconds");
      if (event.inSeconds - 0.9 > _value.inSeconds) // Prevent waste updates
        setState(() {
          _value = event;
          seconds = event.inSeconds;
          // print("${this._value.inSeconds}, $seconds");
          if (prefs != null)
            prefs.setInt(Constants.PrefKeys.songPositionInt, _value.inSeconds);
        });
    });

    // Handle track swtich
    _changeDurationSubscription =
        MusicPlayer.instance.onDurationChanged.listen((event) {
      if (_duration !=
          event) // FIXME: TODO: onDurationChanged for some reason invoked constanly so review all places where it is used
        setState(() {
          _value = Duration(seconds: 0);
          //  seconds= 0;
          _duration = Duration(
              milliseconds:
                  MusicPlayer.instance.playlistControl.currentSong.duration);
        });
    });
  }

  @override
  void dispose() {
    _changePositionSubscription.cancel();
    _changeDurationSubscription.cancel();
    super.dispose();
  }

  void _getPrefsInstance() async {
    prefs = await SharedPreferences.getInstance();
  }

  _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.instance.currentPosition;
    setState(() {
      _value = currentPosition;
      seconds = currentPosition.inSeconds;
      _duration = Duration(
          milliseconds:
              MusicPlayer.instance.playlistControl.currentSong.duration);
    });
  }

  // Drag functions
  void _handleChangeStart(double newValue) async {
    setState(() {
      _localValue = newValue;
      _isDragging = true;
    });
  }

  void _handleChanged(double newValue) {
    setState(() {
      _localValue = newValue;
    });
  }

  void _handleChangeEnd(double newValue) async {
    await MusicPlayer.instance.seek(newValue.toInt());
    setState(() {
      _value = Duration(seconds: newValue.toInt());
      _isDragging = false;
    });
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
    int minutes = _duration.inMinutes;
    // Seconds in 0-59 format
    int seconds = _duration.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  @override
  Widget build(BuildContext context) {
    print('fffffffffffffff');
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
              max: Duration(
                      milliseconds: MusicPlayer
                          .instance.playlistControl.currentSong.duration)
                  .inSeconds
                  .toDouble(),
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
    );
  }
}
