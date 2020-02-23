/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

const Duration kSelectionDuration = Duration(milliseconds: 450);

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
class TrackListScreen extends StatefulWidget {
  final EdgeInsets bottomPadding;
  TrackListScreen(
      {Key key, this.bottomPadding: const EdgeInsets.only(bottom: 0.0)})
      : super(key: key);

  @override
  _TrackListScreenState createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  /// Contains selected song ids
  Set<int> selectionSet = {};

  /// Value used to animate selection count number
  int prevSetLength = 0;

  /// Enables selection mode
  bool _selectionMode;

  /// Denotes state of unselection animation
  bool unselecting = false;

  /// Switcher to control track tiles selection re-render
  final IntSwitcher _switcher = IntSwitcher();

  bool refreshing = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  StreamSubscription<void> _playlistChangeSubscription;
  StreamSubscription<Duration> _durationChangeSubscription;

  @override
  void initState() {
    super.initState();
    _playlistChangeSubscription =
        PlaylistControl.onPlaylistListChange.listen((event) {
      // Update list on playlist changes
      _switcher.change();
    });
    _durationChangeSubscription = MusicPlayer.onDurationChanged.listen((event) {
      // Needed to update current track indicator
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playlistChangeSubscription.cancel();
    _durationChangeSubscription.cancel();
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

  /// Sets [unselecting] to false when all items are removed (they are removed from [SongTile] widget itself, calling [onUnselect])
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
      _selectionMode = false;
      unselecting = true;
      _switcher.change();
    });
    // Needed to release clear set fully when animation is ended, cause some tiles may be out of scope
    await Future.delayed(kSelectionDuration);
    if (mounted)
      setState(() {
        selectionSet = {};
        unselecting = false;
      });
  }

  void _handleDelete() {
    ShowFunctions.showDialog(
      context,
      title: Text("Удаление (не имплементировано)"),
      content: Text(
        "Вы действительно хотите удалить ${selectionSet.length} треков? Это действие необратимо",
      ),
      acceptButton: DialogFlatButton(
        child: Text('Удалить'),
        textColor: Constants.AppTheme.acceptButton.auto(context),
        onPressed: () {
          Navigator.of(context).pop();
          PlaylistControl.deleteSongs(selectionSet);
          _handleCloseSelection();
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
          duration: kSelectionDuration,
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
      duration: kSelectionDuration,
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
                      duration: const Duration(milliseconds: 200),
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
    final songs = PlaylistControl.getPlaylist(PlaylistType.global).songs;

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
                        physics: const SMMBouncingScrollPhysics(),
                        itemCount:
                            PlaylistControl.getPlaylist(PlaylistType.global)
                                .length,
                        padding: const EdgeInsets.only(bottom: 65, top: 0),
                        itemBuilder: (context, index) {
                          return SelectableSongTile(
                            song: songs[index],
                            // Specify object key that can be changed to re-render song tile
                            key: ValueKey(index + _switcher.value),
                            selected: selectionSet.contains(songs[index].id),
                            someSelected: isSelection(),
                            unselecting: unselecting,
                            playing: songs[index].id ==
                                PlaylistControl.currentSongId,
                            additionalClickCallback:
                                PlaylistControl.resetPlaylists,
                            onSelected: () => _handleSelect(songs[index].id),
                            onUnselected: (bool onMount) =>
                                _handleUnselect(songs[index].id, onMount),
                            notifyUnselection: () => _handleNotifyUnselection(),
                          );
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
    final int length = PlaylistControl.getPlaylist().length;
    final int currentSongIndex = PlaylistControl.currentSongIndex();
    if (length > 11) {
      initialScrollIndex =
          currentSongIndex > length - 6 ? length - 6 : currentSongIndex;
    } else
      initialScrollIndex = 0;

    final songs = PlaylistControl.getPlaylist().songs;

    return Container(
      child: SingleTouchRecognizerWidget(
        child: Scrollbar(
          child: ScrollablePositionedList.builder(
              physics: const SMMBouncingScrollPhysics(),
              frontScrollController: frontScrollController,
              itemScrollController: itemScrollController,
              itemCount: length,
              padding: const EdgeInsets.only(bottom: 10, top: 5),
              initialScrollIndex: initialScrollIndex,
              itemBuilder: (context, index) {
                return SongTile(
                  song: songs[index],
                  playing: index == currentSongIndex,
                  pushToPlayerRouteOnClick: false,
                );
              }),
        ),
      ),
    );
  }
}

//***************************************** Song Tiles ******************************************

/// Every SongTile flavor must implement this
abstract class SongTileInterface {
  SongTileInterface(this.song);

  /// Song data to display
  final Song song;
}

/// [SongTile] that represents a single track in [TrackList]
class SongTile extends StatelessWidget implements SongTileInterface {
  SongTile({
    Key key,
    @required this.song,
    this.pushToPlayerRouteOnClick: true,
    this.playing: false,
    this.additionalClickCallback,
  }) : super(key: key);

  /// Song data to display
  @override
  final Song song;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function additionalClickCallback;

  void _handleTap(BuildContext context) async {
    await MusicPlayer.clickSongTile(song.id);
    if (additionalClickCallback != null) additionalClickCallback();
    // Playing because clickSongTile changes any other type to it
    // TODO: move out ot this widget pushing route
    if (pushToPlayerRouteOnClick &&
        MusicPlayer.playerState == AudioPlayerState.PLAYING)
      Navigator.of(context).pushNamed(Constants.Routes.player.value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      selectedColor: Theme.of(context).textTheme.headline6.color,
      child: ListTile(
        subtitle: Artist(artist: song.artist),
        // subtitle: Text(song.artist),
        dense: true,
        isThreeLine: false,
        contentPadding: const EdgeInsets.only(left: 10, top: 0),
        onTap: () => _handleTap(context),
        leading: AlbumArtSmall(path: song.albumArtUri),
        title: Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15 /* Default flutter title font size (not dense) */,
          ),
        ),
        trailing: playing
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
      ),
    );
  }
}

/// [SongTile] that represents a single track in [TrackList]
class SelectableSongTile extends StatefulWidget implements SongTileInterface {
  SelectableSongTile({
    Key key,
    @required this.song,
    this.pushToPlayerRouteOnClick: true,
    this.playing: false,
    this.additionalClickCallback,
    this.selected = false,
    this.someSelected = false,
    this.unselecting = false,
    this.onSelected,
    this.onUnselected,
    this.notifyUnselection,
  })  : assert(song != null),
        super(key: key);

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  @override
  final Song song;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function additionalClickCallback;

  // Selection props

  /// Makes tiles to be selected on first render, after this can be done via internal state
  final bool selected;

  /// If any tile is selected
  final bool someSelected;

  /// Blocks tile events when true
  ///
  /// Used to know when unselection animation is performed
  final bool unselecting;

  /// Callback that is fired when item gets selected (before animation)
  final Function onSelected;

  /// Callback that is fired when item gets unselected (before animation)
  final Function onUnselected;

  /// Callback that is fired when item gets unselected (after animation)
  final Function notifyUnselection;

  @override
  _SelectableSongTileState createState() => _SelectableSongTileState();
}

class _SelectableSongTileState extends State<SelectableSongTile>
    with SingleTickerProviderStateMixin {
  /// Is track tile selected or not
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

    _selected = widget.selected ?? false;
    _animationController = AnimationController(
      vsync: this,
      duration: kSelectionDuration,
    );

    final CurvedAnimation animationBase = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _animationOpacity = Tween<double>(begin: 0, end: 1).animate(animationBase);
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await MusicPlayer.clickSongTile(widget.song.id);
    if (widget.additionalClickCallback != null)
      widget.additionalClickCallback();
    // Playing because clickSongTile changes any other type to it
    if (widget.pushToPlayerRouteOnClick &&
        MusicPlayer.playerState == AudioPlayerState.PLAYING)
      Navigator.of(context).pushNamed(
          Constants.Routes.player.value); // TODO: move this out of here
  }

  // Performs unselect animation and calls [onSelected] and [notifyUnselection]
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
        selectedColor: Theme.of(context).textTheme.headline6.color,
        child: ListTile(
          subtitle: Artist(artist: widget.song.artist),
          selected: _selected,
          dense: true,
          isThreeLine: false,
          contentPadding: const EdgeInsets.only(left: 10, top: 0),
          onTap: widget.someSelected ? _toggleSelection : _handleTap,
          onLongPress: _toggleSelection,
          title: Text(
            widget.song.title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15 /* Default flutter title font size (not dense) */,
            ),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(_animationBorderRadius.value),
            child: Stack(
              children: <Widget>[
                Container(
                  color: Constants.AppTheme.albumArtSmall.auto(context),
                  child: FadeTransition(
                    opacity: _animationOpacityInverse, // Inverse values
                    child: ScaleTransition(
                      scale: _animationScale,
                      child: AlbumArtSmall(path: widget.song.albumArtUri),
                    ),
                  ),
                ),
                if (_animationController.value != 0)
                  FadeTransition(
                    opacity: _animationOpacity,
                    child: Container(
                      width: 48.0,
                      height: 48.0,
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
          ),
          trailing: !widget.playing
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
