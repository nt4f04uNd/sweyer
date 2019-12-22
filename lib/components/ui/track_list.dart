/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// This widget is needed because I need to call `Scaffold.of(context).openDrawer()`
/// which requires context to have scaffold in it
/// separating widget allows to to that
class _MainRouteAppBarLeading extends StatelessWidget {
  const _MainRouteAppBarLeading({
    Key key,
    @required this.selectionMode,
    @required this.onCloseClick,
  }) : super(key: key);

  /// NOTE This has to be a raw value, can null, to display that main route is mounted first time
  /// And we don't need to play animation
  final bool selectionMode;
  final Function onCloseClick;

  @override
  Widget build(BuildContext context) {
    return AnimatedMenuCloseButton(
      key: ValueKey(selectionMode),
      animateDirection: selectionMode,
      onCloseClick: onCloseClick,
      onMenuClick: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}

class FakeInputBox extends StatelessWidget {
  const FakeInputBox({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: () => ShowFunctions.showSongsSearch(context),
          child: FractionallySizedBox(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 12.0, top: 7.0, bottom: 7.0, right: 12.0),
              decoration: BoxDecoration(
                color: Constants.AppTheme.searchFakeInput.auto(context),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).textTheme.caption.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// List of fetched tracks
class MainRouteTrackList extends StatefulWidget {
  final EdgeInsets bottomPadding;
  MainRouteTrackList(
      {Key key, this.bottomPadding: const EdgeInsets.only(bottom: 0.0)})
      : super(key: key);

  @override
  _MainRouteTrackListState createState() => _MainRouteTrackListState();
}

class _MainRouteTrackListState extends State<MainRouteTrackList> {
  /// Contains selected song ids
  Set<int> selectionSet = {};

  /// Value used to animate selection count number
  int prevSetLength = 0;

  /// Enables selection mode
  bool _selectionMode;

  /// Denotes state of unselection animation
  bool unselecting = false;

  /// Switcher to control track tiles selection re-render
  IntSwitcher _switcher = IntSwitcher();

  bool refreshing = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  StreamSubscription<void> _playlistChangeSubscription;

  @override
  void initState() {
    super.initState();
    _playlistChangeSubscription =
        PlaylistControl.onPlaylistListChange.listen((event) {
      // Update list on playlist changes
      _switcher.change();
    });
  }

  @override
  void dispose() {
    _playlistChangeSubscription.cancel();
    super.dispose();
  }

  /// Performs tracks refetch
  Future<void> _handleRefresh() async {
    await PlaylistControl.refetchSongs();
    return Future.value();
  }

  /// Check if user selecting tracks
  bool isSelection() {
    return _selectionMode != null && _selectionMode;
  }

  /// Adds item index to set and enables selection mode if needed
  void _handleSelect(int id) {
    prevSetLength = selectionSet.length;
    selectionSet.add(id);
    if (!isSelection())
      setState(() {
        _selectionMode = true;
      });
    else
      setState(() {});
  }

  /// Removes item index from set and disables selection mode if set is empty
  void _handleUnselect(int id, bool onMount) {
    prevSetLength = selectionSet.length;
    selectionSet.remove(id);
    if (selectionSet.isEmpty) {
      // If none elements are selected - trigger unselecting animation and disable selection mode
      if (!unselecting) {
        setState(() {
          unselecting = true;
          _selectionMode = false;
        });
      } else
        _selectionMode = false;
    } else {
      if (!onMount) setState(() {});
    }
  }

  /// Sets `unselecting` to false when all items are removed (they are removed from `TrackTile` widget itself, calling `onUnselect`)
  void _handleNotifyUnselection() {
    if (selectionSet.isEmpty) {
      setState(() {
        selectionSet = {};
        unselecting = false;
      });
    }
  }

  void _handleCloseSelection() async {
    setState(() {
      unselecting = true;
      _switcher.change();
    });
    // Needed to release clear set fully when animation is ended, cause some tiles may be out of scope
    await Future.delayed(Duration(milliseconds: 300));
    _switcher.change();
    if (mounted)
      setState(() {
        selectionSet = {};
        _selectionMode = false;
        unselecting = false;
      });
  }

  void _handleDelete() {
    ShowFunctions.showDialog(
      context,
      title: Text("Удаление"),
      content: Text(
        "Вы действительно хотите удалить ${selectionSet.length} треков? Это действие необратимо",
      ),
      acceptButton: DialogFlatButton(
        child: Text('Удалить'),
        textColor: Constants.AppTheme.redFlatButton.auto(context),
        onPressed: () {
          Navigator.of(context).pop();
          PlaylistControl.deleteSongs(selectionSet);
          setState(() {
            selectionSet = {};
            unselecting = false;
            _selectionMode = false;
          });
        },
      ),
      declineButton: DialogFlatButton(
        child: Text('Отмена'),
        textColor: Constants.AppTheme.declineButton.auto(context),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  //***************ACTIONS*******************************************************
  List<Widget> _renderAppBarActions() {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: !isSelection()
              ? SMMIconButton(
                  splashColor: Constants.AppTheme.splash.auto(context),
                  icon: Icon(Icons.sort),
                  color: Constants.AppTheme.mainContrast.auto(context),
                  onPressed: () => ShowFunctions.showSongsSortModal(context),
                )
              : IgnorePointer(
                  ignoring: unselecting,
                  child: SMMIconButton(
                    splashColor: Constants.AppTheme.splash.auto(context),
                    key: UniqueKey(),
                    color: Constants.AppTheme.mainContrast.auto(context),
                    icon: Icon(Icons.delete_outline),
                    onPressed: _handleDelete,
                  ),
                ),
        ),
      ),
    ];
  }

//***************TITLE*******************************************************
  Widget _renderAppBarTitle() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: !isSelection()
          ? FakeInputBox()
          : Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text(
                  "Выбрано",
                  style: TextStyle(
                    color: Constants.AppTheme.mainContrast.auto(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 20.0),
                    child: AnimatedSwitcher(
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final inForwardAnimation = Tween<Offset>(
                          begin: Offset(0.0, -0.7),
                          end: Offset(0.0, 0.0),
                        ).animate(
                          CurvedAnimation(
                            curve: Curves.easeOut,
                            parent: animation,
                          ),
                        );
                        final inBackAnimation = Tween<Offset>(
                          begin: Offset(0.0, 0.7),
                          end: Offset(0.0, 0.0),
                        ).animate(
                          CurvedAnimation(
                            curve: Curves.easeOut,
                            parent: animation,
                          ),
                        );
                        final outForwardAnimation = Tween<Offset>(
                          begin: Offset(0.0, 0.7),
                          end: Offset(0.0, 0.0),
                        ).animate(
                          CurvedAnimation(
                            curve: Curves.easeIn,
                            parent: animation,
                          ),
                        );
                        final outBackAnimation = Tween<Offset>(
                          begin: Offset(0.0, -0.7),
                          end: Offset(0.0, 0.0),
                        ).animate(
                          CurvedAnimation(
                            curve: Curves.easeIn,
                            parent: animation,
                          ),
                        );

                        //* For entering widget
                        if (child.key == ValueKey(selectionSet.length)) {
                          if (selectionSet.length >= prevSetLength)
                            return SlideTransition(
                              position: inForwardAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          else
                            return SlideTransition(
                              position: inBackAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                        }
                        //* For exiting widget
                        else {
                          if (selectionSet.length >= prevSetLength) {
                            return SlideTransition(
                              position: outForwardAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          } else
                            return SlideTransition(
                              position: outBackAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                        }
                      },
                      duration: Duration(milliseconds: 160),
                      child: Padding(
                        key: ValueKey(selectionSet.length),
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          selectionSet.length.toString(),
                          style: TextStyle(
                            color:
                                Constants.AppTheme.mainContrast.auto(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerWidget(),
      appBar: AppBar(
        titleSpacing: 0.0,
        leading: _MainRouteAppBarLeading(
          selectionMode: _selectionMode,
          onCloseClick: _handleCloseSelection,
        ),
        actions: _renderAppBarActions(),
        title: _renderAppBarTitle(),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: widget.bottomPadding,
            child: Container(
              child: CustomRefreshIndicator(
                color: Constants.AppTheme.refreshIndicatorArrow.auto(context),
                backgroundColor: Colors.deepPurple,
                strokeWidth: 2.5,
                key: _refreshIndicatorKey,
                onRefresh: _handleRefresh,
                child: SingleTouchRecognizerWidget(
                  child: Container(
                    child: Scrollbar(
                      child: ListView.builder(
                        physics: SMMBouncingScrollPhysics(),
                        itemCount: PlaylistControl.length(PlaylistType.global),
                        padding: EdgeInsets.only(bottom: 65, top: 0),
                        itemBuilder: (context, index) {
                          return StreamBuilder(
                              stream: MusicPlayer.onDurationChanged,
                              builder: (context, snapshot) {
                                final int id = PlaylistControl.getSongAt(
                                        index, PlaylistType.global)
                                    .id;
                                return TrackTile(
                                  index,
                                  // Specify object key that can be changed to re-render song tile
                                  key: ValueKey(index + _switcher.value),
                                  selectable: true,
                                  selected: selectionSet.contains(id),
                                  someSelected: isSelection(),
                                  unselecting: unselecting,
                                  playing: id == PlaylistControl.currentSongId,
                                  additionalClickCallback: () {
                                    PlaylistControl.resetPlaylists();
                                  },
                                  onSelected: () => _handleSelect(id),
                                  onUnselected: (bool onMount) =>
                                      _handleUnselect(id, onMount),
                                  notifyUnselection: () =>
                                      _handleNotifyUnselection(),
                                );
                              });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomTrackPanel(),
        ],
      ),
    );
  }
}

/// Widget to render current playlist in player right right tab
///
/// Stateful because I need its state is needed to use global key
class PlayerRoutePlaylist extends StatefulWidget {
  PlayerRoutePlaylist({
    Key key,
  }) : super(key: key);

  @override
  PlayerRoutePlaylistState createState() => PlayerRoutePlaylistState();
}

class PlayerRoutePlaylistState extends State<PlayerRoutePlaylist> {
  final ItemScrollController itemScrollController = ItemScrollController();

  final ScrollController frontScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    int initialScrollIndex;
    final int length = PlaylistControl.length();
    final int currentSongIndex = PlaylistControl.currentSongIndex();
    if (length > 11) {
      initialScrollIndex =
          currentSongIndex > length - 6 ? length - 6 : currentSongIndex;
    } else
      initialScrollIndex = 0;

    return Container(
      child: SingleTouchRecognizerWidget(
        child: Scrollbar(
          child: ScrollablePositionedList.builder(
            physics: SMMBouncingScrollPhysics(),
            frontScrollController: frontScrollController,
            itemScrollController: itemScrollController,
            itemCount: length,
            padding: EdgeInsets.only(bottom: 10, top: 5),
            initialScrollIndex: initialScrollIndex,
            itemBuilder: (context, index) {
              return StreamBuilder(
                  stream: MusicPlayer.onDurationChanged,
                  builder: (context, snapshot) {
                    return TrackTile(
                      index,
                      key: UniqueKey(),
                      playing: index == currentSongIndex,
                      song: PlaylistControl.getSongAt(index),
                      pushToPlayerRouteOnClick: false,
                    );
                  });
            },
          ),
        ),
      ),
    );
  }
}

/// `TrackTile` that represents a single track in `TrackList`
class TrackTile extends StatefulWidget {
  TrackTile(
    this.trackTileIndex, {
    Key key,
    this.pushToPlayerRouteOnClick: true,
    this.playing: false,
    this.song,
    this.additionalClickCallback,
    this.selectable = false,
    this.selected = false,
    this.someSelected = false,
    this.unselecting = false,
    this.onSelected,
    this.onUnselected,
    this.notifyUnselection,
  }) : super(key: key);

  /// Index of rendering element from
  final int trackTileIndex;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function additionalClickCallback;

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  final Song song;

  // Selection props
  /// Enables tile selection on long press
  final bool selectable;

  /// Makes tiles to be selected on first render, after this can be done via internal state
  final bool selected;

  /// If any tile is selected
  final bool someSelected;

  /// Blocks tile events when true
  ///
  /// Used to events when unselection animation is performed
  final bool unselecting;

  /// Callback that is fired when item gets selected (before animation)
  final Function onSelected;

  /// Callback that is fired when item gets unselected (before animation)
  final Function onUnselected;

  /// Callback that is fired when item gets unselected (after animation)
  final Function notifyUnselection;

  @override
  _TrackTileState createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile>
    with SingleTickerProviderStateMixin {
  /// Instance of music player
  Song _song;

  /// Is track tile selected
  bool _selected;

  AnimationController _animationController;
  Animation<double> _animationOpacity;
  Animation<double> _animationOpacityInverse;
  Animation<double> _animationBorderRadius;
  Animation<double> _animationScale;
  Animation<double> _animationScaleInverse;

  @override
  void initState() {
    super.initState();

    /// If song data is not provided, then find it by index of row in current row
    _song = widget.song ??
        PlaylistControl.getSongAt(widget.trackTileIndex, PlaylistType.global);

    _selected = widget.selected ?? false;
    if (widget.selectable) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );

      final CurvedAnimation animationBase = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );

      _animationOpacity =
          Tween<double>(begin: 0, end: 1).animate(animationBase);
      _animationOpacityInverse =
          Tween<double>(begin: 1.0, end: 0.0).animate(animationBase);

      _animationBorderRadius =
          Tween<double>(begin: 10, end: 20).animate(animationBase);

      _animationScale =
          Tween<double>(begin: 1.0, end: 1.2).animate(animationBase);

      _animationScaleInverse =
          Tween<double>(begin: 1.17, end: 1.0).animate(animationBase);

      _animationController
        ..addListener(() {
          setState(() {
            // The state that has changed here is the animation object’s value.
          });
        });

      if (widget.unselecting) {
        // Perform unselection animation
        if (_selected) {
          _animationController.value = 1;
          _unselect(true);
          _selected = false;
        }
      } else {
        if (_selected)
          _animationController.value = 1;
        else
          _animationController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    if (widget.selectable) _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await MusicPlayer.clickTrackTile(_song.id);
    if (widget.additionalClickCallback != null)
      widget.additionalClickCallback();
    // Playing because clickTrackTile changes any other type to it
    if (widget.pushToPlayerRouteOnClick &&
        MusicPlayer.playState == AudioPlayerState.PLAYING)
      Navigator.of(context).pushNamed(Constants.Routes.player.value);
  }

  // Performs unselect animation and calls `onSelected` and `notifyUnselection`
  void _unselect([bool onMount = false]) async {
    widget.onUnselected(onMount);
    await _animationController.reverse();
    widget.notifyUnselection();
  }

  void _select() async {
    widget.onSelected();
    await _animationController.forward();
  }

  void _toggleSelection() {
    setState(() {
      _selected = !_selected;
    });
    if (_selected) {
      _select();
    } else
      _unselect();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.unselecting,
      child: ListTileTheme(
        selectedColor: Theme.of(context).textTheme.title.color,
        child: ListTile(
          title: Text(
            _song.title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              // fontSize: 16 /* Default flutter title font size (not dense) */),
              fontSize: 15 /* Default flutter title font size (not dense) */,

              // fontWeight: ThemeControl.isDark ?FontWeight.w500 : FontWeight.w600,
            ),
          ),
          subtitle: Artist(artist: _song.artist),
          selected: _selected,
          dense: true,
          isThreeLine: false,
          leading: widget.selectable
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(_animationBorderRadius.value),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: Constants.AppTheme.albumArtSmall.auto(context),
                        child: FadeTransition(
                          opacity: _animationOpacityInverse, // Inverse values
                          child: ScaleTransition(
                            scale: _animationScale,
                            child: AlbumArt(path: _song.albumArtUri),
                          ),
                        ),
                      ),
                      if (_animationController.value != 0)
                        FadeTransition(
                          opacity: _animationOpacity,
                          child: Container(
                            width: 48,
                            height: 48,
                            color: Colors.deepPurple,
                            child: ScaleTransition(
                              scale: _animationScaleInverse,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : AlbumArt(path: _song.albumArtUri),
          trailing: widget.playing
              ? Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.only(left: 10, top: 0),
          onTap: widget.selectable && widget.someSelected
              ? _toggleSelection
              : _handleTap,
          onLongPress: widget.selectable ? _toggleSelection : null,
        ),
      ),
    );
  }
}
