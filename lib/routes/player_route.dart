/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerRoute extends StatefulWidget {
  @override
  _PlayerRouteState createState() => _PlayerRouteState();
}

class _PlayerRouteState extends State<PlayerRoute> {
  PageController _pageController = PageController();
  bool initialRender = true;
  final GlobalKey<_PlaylistTabState> _playlistTabKey =
      GlobalKey<_PlaylistTabState>();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page == 0.0) {
        _playlistTabKey.currentState.opened = false;
        if (initialRender)
          initialRender = false;
        else
          _playlistTabKey.currentState.jumpOnTabChange();
      } else if (_pageController.page == 1.0) {
        _playlistTabKey.currentState.opened = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          _MainPlayerTab(),
          _PlaylistTab(
            key: _playlistTabKey,
          )
        ],
      ),
    );
  }
}

class _PlaylistTab extends StatefulWidget {
  _PlaylistTab({Key key}) : super(key: key);

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<_PlaylistTab>
    with AutomaticKeepAliveClientMixin<_PlaylistTab> {
  // This mixin doesn't allow widget to redraw
  @override
  bool get wantKeepAlive => true;

  /// How much tracks to ignore scrolling
  static const int tracksScrollOffset = 6;
  static const Duration scrollDuration = const Duration(milliseconds: 600);

// This is set in parent via global key
  bool opened = false;

  GlobalKey<PlayerRoutePlaylistState> globalKeyPlayerRoutePlaylist =
      GlobalKey();

  /// A bool var to disable show/hide in tracklist controller listener when manual [scrollToSong] is performing
  bool scrolling = false;
  StreamSubscription<void> _durationSubscription;
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
    _durationSubscription = MusicPlayer.onDurationChanged.listen((event) async {
      // Scroll when track changes
      if (opened) {
        // Just update list if opened, this is needed to update current track indicator
        setState(() {});
      } else {
        await performScrolling();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _playlistChangeSubscription.cancel();
    _durationSubscription.cancel();
    super.dispose();
  }

  /// Scrolls to current song
  ///
  /// If optional [index] is provided - scrolls to it
  Future<void> scrollToSong([int index]) async {
    if (index == null) index = PlaylistControl.currentSongIndex();

    return globalKeyPlayerRoutePlaylist.currentState.itemScrollController
        .scrollTo(
            index: index, duration: scrollDuration, curve: Curves.easeInOut);
  }

  /// Jumps to current song
  ///
  /// If optional [index] is provided - jumps to it
  void jumpToSong([int index]) async {
    if (index == null) index = PlaylistControl.currentSongIndex();
    globalKeyPlayerRoutePlaylist.currentState.itemScrollController
        .jumpTo(index: index);
  }

  /// A more complex function with additional checks
  Future<void> performScrolling() async {
    final int playlistLength = PlaylistControl.getPlaylist().length;
    final int playingIndex = PlaylistControl.currentSongIndex();
    final int maxScrollIndex = playlistLength - 1 - tracksScrollOffset;

    // Exit immediately if index didn't change
    if (prevPlayingIndex == playingIndex) return;

    // If playlist is longer than e.g. 6
    if (playlistLength > tracksScrollOffset) {
      if (prevPlayingIndex >= maxScrollIndex && playingIndex == 0) {
        // When prev track was last in playlist
        jumpToSong();
        prevPlayingIndex = playingIndex;
      } else if (playingIndex < maxScrollIndex) {
        prevPlayingIndex = playingIndex;
        // Scroll to current song and tapped track is in between range [0:playlistLength - offset]
        await scrollToSong();
      } else if (prevPlayingIndex > maxScrollIndex) {
        /// Do nothing when it is already scrolled to [maxScrollIndex]
        return;
      } else if (playingIndex >= maxScrollIndex) {
        if (prevPlayingIndex == 0) {
          jumpToSong(maxScrollIndex);
          prevPlayingIndex = playingIndex;
        }
        // If at the end of the list
        else {
          prevPlayingIndex = playingIndex;
          await scrollToSong(maxScrollIndex);
        }
      }
    }
  }

  /// Jump to song when changing tab to `0`
  Future<void> jumpOnTabChange() async {
    final int playlistLength = PlaylistControl.getPlaylist().length;
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
              preferredSize: Size.fromHeight(80.0),
              child: Padding(
                padding: const EdgeInsets.only(top: 22.0),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  title: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Далее',
                        style: TextStyle(
                          fontSize: 24,
                          height: 1,
                          color: Theme.of(context).textTheme.headline6.color,
                        ),
                      ),
                      Text(
                        PlaylistControl.playlistType == PlaylistType.global
                            ? 'Основной плейлист'
                            : PlaylistControl.playlistType ==
                                    PlaylistType.shuffled
                                ? 'Перемешанный плейлист'
                                : 'Найденный плейлист',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.caption.color,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              padding: const EdgeInsets.only(top: 4.0),
              child: PlayerRoutePlaylist(
                key: globalKeyPlayerRoutePlaylist,
              ),
            ),
          );
        });
  }
}

class _MainPlayerTab extends StatefulWidget {
  @override
  _MainPlayerTabState createState() => _MainPlayerTabState();
}

class _MainPlayerTabState extends State<_MainPlayerTab>
    with AutomaticKeepAliveClientMixin<_MainPlayerTab> {
  // This mixin doesn't allow widget to redraw
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageBase(
      backButton: SMMBackButton(
        icon: Icons.keyboard_arrow_down,
        size: 40.0,
      ),
      actions: <Widget>[
        SingleAppBarAction(
          child: _MoreButton(),
        )
      ],
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _TrackShowcase(),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  child: _TrackSlider(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 40, top: 10, left: 20, right: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    ShuffleButton(),
                    _PlaybackButtons(),
                    LoopButton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaybackButtons extends StatelessWidget {
  const _PlaybackButtons({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Constants.AppTheme.prevNextBorder.auto(context),
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: SMMIconButton(
                size: 44,
                icon: Icon(
                  Icons.skip_previous,
                  color: Constants.AppTheme.mainContrast.auto(context),
                ),
                onPressed: MusicPlayer.playPrev,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Constants.AppTheme.playPauseBorder.auto(context),
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: AnimatedPlayPauseButton(),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    width: 1,
                    color: Constants.AppTheme.prevNextBorder.auto(context)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: SMMIconButton(
                size: 44,
                icon: Icon(
                  Icons.skip_next,
                  color: Constants.AppTheme.mainContrast.auto(context),
                ),
                onPressed: MusicPlayer.playNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({Key key}) : super(key: key);

  List<SMMPopupMenuEntry<void>> _itemBuilder(BuildContext context) => [
        SMMPopupMenuItem<void>(
          value: '',
          child: Center(
            child: Text(
              'Изменить информацию',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: Constants.AppTheme.popupMenu.auto(context),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 5.0),
        child: SMMPopupMenuButton<void>(
          itemBuilder: _itemBuilder,
          tooltipEnabled: false,
          buttonSize: 40.0,
          menuPadding: const EdgeInsets.all(0.0),
          menuBorderRadius: const BorderRadius.all(
            Radius.circular(15.0),
          ),
          onSelected: (_) {
            // NOTE https://api.flutter.dev/flutter/material/PopupMenuButton-class.html
            Navigator.of(context).pushNamed(Constants.Routes.exif.value);
          },
        ),
      ),
    );
  }
}

/// A widget that displays all information about current song
class _TrackShowcase extends StatefulWidget {
  _TrackShowcase({Key key}) : super(key: key);

  @override
  _TrackShowcaseState createState() => _TrackShowcaseState();
}

class _TrackShowcaseState extends State<_TrackShowcase> {
  /// Key for [MarqueeWidget] to reset its scroll on song change
  UniqueKey marqueeKey = UniqueKey();
  StreamSubscription<void> _durationSubscription;

  @override
  void initState() {
    super.initState();
    // Handle track switch
    _durationSubscription = MusicPlayer.onDurationChanged.listen((event) {
      // Create new key for marque widget to reset scroll
      setState(() {
        marqueeKey = UniqueKey();
      });
    });
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
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
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 30),
              child: Artist(
                artist: PlaylistControl.currentSong.artist,
                textStyle:
                    TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child:
                  AlbumArtLarge(path: PlaylistControl.currentSong?.albumArtUri),
            ),
          ],
        ),
      ),
    );
  }
}



  /// TODO: convert this to use [LabelledSlider] widget
class _TrackSlider extends StatefulWidget {
  _TrackSlider({Key key}) : super(key: key);

  _TrackSliderState createState() => _TrackSliderState();
}

class _TrackSliderState extends State<_TrackSlider> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  /// Value to perform drag
  double _localValue;

  SharedPreferences prefs;

  /// Subscription for audio position change stream
  StreamSubscription<Duration> _positionSubscription;
  StreamSubscription<void> _durationSubscription;

  /// Is user dragging slider right now
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();
    _getPrefsInstance();

    // Handle track position movement
    _positionSubscription = MusicPlayer.onAudioPositionChanged.listen((event) {
      if (!_isDragging) {
        setState(() {
          _value = event;
        });
      }
    });

    // Handle track switch
    _durationSubscription = MusicPlayer.onDurationChanged.listen((event) {
      setState(() {
        _isDragging = false;
        _localValue = 0.0;
        _value = const Duration(seconds: 0);
        _duration = event;
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    super.dispose();
  }

  Future<void> _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.currentPosition;
    var currentDuration = await MusicPlayer.currentDuration;
    setState(() {
      _duration = Duration(milliseconds: PlaylistControl.currentSong?.duration);
      _value = currentPosition;
    });
  }

  void _getPrefsInstance() async {
    prefs = await Prefs.getSharedInstance();
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

  /// FIXME: this called multiple times since it is inside [TabBarView], currently unable to fix, as this issue relies deeply to flutter architecture
  void _handleChangeEnd(double newValue) async {
    // if (_isDragging) {
    await MusicPlayer.seek(Duration(seconds: newValue.toInt()));
    setState(() {
      _isDragging = false;
      _value = Duration(seconds: newValue.toInt());
    });
    // }
  }

  String _calculateDisplayedPositionTime() {
    /// Value to work with, depends on [_isDragging] state, either [_value] or [_localValue]
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
        child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 35.0,
          transform: Matrix4.translationValues(5, 0, 0),
          child: Text(
            _calculateDisplayedPositionTime(),
            style: TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            activeColor: Colors.deepPurple,
            inactiveColor: Constants.AppTheme.sliderInactive.auto(context),
            value: _isDragging ? _localValue : _value.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            min: 0,
            onChangeStart: _handleChangeStart,
            onChanged: _handleChanged,
            onChangeEnd: _handleChangeEnd,
          ),
        ),
        Container(
          width: 35.0,
          transform: Matrix4.translationValues(-5, 0, 0),
          child: Text(
            _calculateDisplayedDurationTime(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ));
  }
}
