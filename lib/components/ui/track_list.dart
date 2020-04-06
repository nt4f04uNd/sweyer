/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

const Duration kSMMSelectionDuration = Duration(milliseconds: 500);

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
      {Key key, this.bottomPadding: const EdgeInsets.only(bottom: 34.0)})
      : super(key: key);

  @override
  _TrackListScreenState createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen>
    with SingleTickerProviderStateMixin {
  bool everSelected = false;

  /// Contains selected song ids
  Set<int> selectionSet = {};

  /// Value used to animate selection count number
  int prevSetLength = 0;

  /// Denotes state of unselection animation
  bool unselecting = false;

  /// Switcher to control track tiles selection re-render
  final IntSwitcher _switcher = IntSwitcher();

  bool refreshing = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  AnimationController selectionController;
  StreamSubscription<void> _playlistChangeSubscription;
  StreamSubscription<Song> _songChangeSubscription;

  // Var to show exit toast
  DateTime _lastBackPressTime;

  @override
  void initState() {
    super.initState();

    selectionController =
        AnimationController(vsync: this, duration: kSMMSelectionDuration);
    selectionController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (unselecting) {
          selectionSet = {};
          unselecting = false;
        }
        setState(() {
          _switcher.change();
        });
      }
    });

    _playlistChangeSubscription =
        ContentControl.state.onPlaylistListChange.listen((event) {
      // Update list on playlist changes
      _switcher.change();
    });
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) {
      // Needed to update current track indicator
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playlistChangeSubscription.cancel();
    _songChangeSubscription.cancel();
    selectionController.dispose();
    super.dispose();
  }

  /// Performs tracks refetch
  Future<void> _handleRefresh() async {
    await ContentControl.refetchSongs();
    return Future.value();
  }

  void _handleSelectionUpdate(Song song) {
    everSelected = true;
    if (selectionSet.length == 1) {
      setState(() {});
      selectionController.forward();
    } else if (selectionSet.isEmpty) {
      selectionController.reverse();
    } else {
      setState(() {});
    }
  }

  void _handleCloseSelection() {
    setState(() {
      unselecting = true;
      selectionController.reverse();
      _switcher.change();
    });
  }

  void _handleDelete() {
    ShowFunctions.showDialog(
      context,
      title: const Text("Удаление"),
      content: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 15.0),
          children: [
            TextSpan(text: "Вы уверены, что хотите удалить "),
            TextSpan(
              text: selectionSet.length == 1
                  ? ContentControl.state
                      .getPlaylist(PlaylistType.global)
                      .getSongById(selectionSet.first)
                      .title
                  : "${selectionSet.length} треков",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: " ?"),
          ],
        ),
      ),
      acceptButton: DialogRaisedButton(
        text: "Удалить",
        onPressed: () {
          _handleCloseSelection();
          ContentControl.deleteSongs(selectionSet);
        },
      ),
    );
  }

  Future<bool> _handlePop(BuildContext context) async {
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
      return Future.value(false);
    } else if (selectionController.status == AnimationStatus.forward ||
        selectionController.status == AnimationStatus.completed) {
      _handleCloseSelection();
      return false;
    } else {
      DateTime now = DateTime.now();
      // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime) > Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.showToast(msg: 'Нажмите еще раз для выхода');
        return Future.value(false);
      }
      return Future.value(true);
    }
  }

  //***************ACTIONS*******************************************************
  List<Widget> _renderAppBarActions() {
    // TODO: refactor
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
        child: AnimatedBuilder(
          animation: selectionController,
          builder: (BuildContext context, Widget child) => Stack(
            children: [
              IgnorePointer(
                ignoring:
                    selectionController.status == AnimationStatus.forward ||
                        selectionController.status == AnimationStatus.completed,
                child: FadeTransition(
                  opacity:
                      Tween(begin: 1.0, end: 0.0).animate(selectionController),
                  child: SMMIconButton(
                    icon: const Icon(Icons.sort),
                    color: Constants.AppTheme.mainContrast.auto(context),
                    onPressed: () => ShowFunctions.showSongsSortModal(context),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring:
                    selectionController.status == AnimationStatus.reverse ||
                        selectionController.status == AnimationStatus.dismissed,
                child: FadeTransition(
                  opacity: selectionController,
                  child: SMMIconButton(
                    color: Constants.AppTheme.mainContrast.auto(context),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _handleDelete,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

//***************TITLE*******************************************************
  Widget _renderAppBarTitle() {
    // TODO: refactor
    return AnimatedBuilder(
      animation: selectionController,
      builder: (BuildContext context, Widget child) => IgnorePointer(
        ignoring: selectionController.isAnimating,
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: selectionController.status == AnimationStatus.forward ||
                  selectionController.status == AnimationStatus.completed,
              child: FadeTransition(
                opacity:
                    Tween(begin: 1.0, end: 0.0).animate(selectionController),
                child: FakeInputBox(),
              ),
            ),
            IgnorePointer(
              ignoring: selectionController.status == AnimationStatus.reverse ||
                  selectionController.status == AnimationStatus.dismissed,
              child: FadeTransition(
                opacity: selectionController,
                child: Row(
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
                        constraints: const BoxConstraints(minWidth: 20.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            final inForwardAnimation = Tween<Offset>(
                              begin: const Offset(0.0, -0.7),
                              end: const Offset(0.0, 0.0),
                            ).animate(
                              CurvedAnimation(
                                curve: Curves.easeOut,
                                parent: animation,
                              ),
                            );

                            final inBackAnimation = Tween<Offset>(
                              begin: const Offset(0.0, 0.7),
                              end: const Offset(0.0, 0.0),
                            ).animate(
                              CurvedAnimation(
                                curve: Curves.easeOut,
                                parent: animation,
                              ),
                            );

                            final outForwardAnimation = Tween<Offset>(
                              begin: const Offset(0.0, 0.7),
                              end: const Offset(0.0, 0.0),
                            ).animate(
                              CurvedAnimation(
                                curve: Curves.easeIn,
                                parent: animation,
                              ),
                            );

                            final outBackAnimation = Tween<Offset>(
                              begin: const Offset(0.0, -0.7),
                              end: const Offset(0.0, 0.0),
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
                          child: Padding(
                            // Not letting to go less 1 to not play animation from 1 to 0
                            key: ValueKey(
                              selectionSet.length > 0 ? selectionSet.length : 1,
                            ),
                            padding: const EdgeInsets.only(left: 5.0),
                            child: Text(
                              (selectionSet.length > 0
                                      ? selectionSet.length
                                      : 1)
                                  .toString(),
                              style: TextStyle(
                                color: Constants.AppTheme.mainContrast
                                    .auto(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final songs = ContentControl.state.getPlaylist(PlaylistType.global).songs;

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        titleSpacing: 0.0,
        leading: AnimatedBuilder(
          animation: selectionController,
          builder: (BuildContext context, Widget child) =>
              _MainRouteAppBarLeading(
            selectionMode: !everSelected
                ? null
                : selectionController.status == AnimationStatus.forward ||
                    selectionController.status == AnimationStatus.completed,
            onCloseClick: _handleCloseSelection,
          ),
        ),
        actions: _renderAppBarActions(),
        title: _renderAppBarTitle(),
      ),
      body: Builder(
        builder: (context) => WillPopScope(
          onWillPop: () => _handlePop(context),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: widget.bottomPadding,
                child: CustomRefreshIndicator(
                  color: Constants.AppTheme.refreshIndicatorArrow.auto(context),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.5,
                  key: _refreshIndicatorKey,
                  onRefresh: _handleRefresh,
                  child: SingleTouchRecognizerWidget(
                    child: SongsListScrollBar(
                      controller: _scrollController,
                      labelContentBuilder: (offsetY) {
                        int idx =
                            ((offsetY - 32.0) / kSMMSongTileHeight).round();
                        if (idx >= songs.length) {
                          idx = songs.length - 1;
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              // TODO: refactor and move to separate widget
                              padding:
                                  const EdgeInsets.only(left: 4.0, right: 4.0),
                              width: 22.0,
                              margin: const EdgeInsets.only(left: 4.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                songs[idx].title[0].toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16.0,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const Text(
                              "  —  ",
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: Text(
                                  songs[idx].title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      child: ListView.builder(
                        // physics: const SMMBouncingScrollPhysics(),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: ContentControl.state
                            .getPlaylist(PlaylistType.global)
                            .length,
                        padding: const EdgeInsets.only(bottom: 34.0, top: 0),
                        itemBuilder: (context, index) {
                          return SelectableSongTile(
                            song: songs[index],
                            selectionSet: selectionSet,
                            selectionController: selectionController,
                            // Specify object key that can be changed to re-render song tile
                            key: ValueKey(index + _switcher.value),
                            selected: selectionSet.contains(songs[index].id),
                            unselecting: unselecting,
                            playing: songs[index].id ==
                                ContentControl.state.currentSongId,
                            onTap: ContentControl.resetPlaylists,
                            onSelected: _handleSelectionUpdate,
                            onUnselected: _handleSelectionUpdate,
                            // notifyUnselection: () => _handleNotifyUnselection(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              BottomTrackPanel(),
            ],
          ),
        ),
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
    final int length = ContentControl.state.currentPlaylist.length;
    final int currentSongIndex = ContentControl.state.currentSongIndex;
    if (length > 11) {
      initialScrollIndex =
          currentSongIndex > length - 6 ? length - 6 : currentSongIndex;
    } else
      initialScrollIndex = 0;

    final songs = ContentControl.state.currentPlaylist.songs;

    return Container(
      child: SingleTouchRecognizerWidget(
        child: SMMScrollbar(
          child: ScrollablePositionedList.builder(
            // physics: const SMMBouncingScrollPhysics(),
            physics: const AlwaysScrollableScrollPhysics(),
            frontScrollController: frontScrollController,
            itemScrollController: itemScrollController,
            itemCount: length,
            // padding: const EdgeInsets.only(bottom: 10, top: 5),

            initialScrollIndex: initialScrollIndex,
            itemBuilder: (context, index) {
              // print("udx $index");
              return SongTile(
                song: songs[index],
                playing: index == currentSongIndex,
                pushToPlayerRouteOnClick: false,
              );
            },
          ),
        ),
      ),
    );
  }
}

//***************************************** Song Tiles ******************************************

/// Needed for scrollbar label computations
const double kSMMSongTileHeight = 64.0;

/// Every SongTile flavor must implement this
abstract class SongTileInterface {
  SongTileInterface(this.song);

  /// Song data to display
  final Song song;
}

/// [SongTile] that represents a single track in [TrackList]
class SongTile extends StatefulWidget implements SongTileInterface {
  SongTile({
    Key key,
    @required this.song,
    this.pushToPlayerRouteOnClick: true,
    this.playing: false,
    this.onTap,
  }) : super(key: key);

  /// Song data to display
  @override
  final Song song;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function onTap;

  @override
  _SongTileState createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  void _handleTap(BuildContext context) async {
    if (widget.onTap != null) widget.onTap();

    await MusicPlayer.handleClickSongTile(context, widget.song,
        pushToPlayerRoute: widget.pushToPlayerRouteOnClick);
  }

  final GlobalKey _key = GlobalKey();
  Offset pos;
  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   RenderBox box = _key.currentContext.findRenderObject();
    //   pos = box.localToGlobal(Offset.zero);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return
        // GestureDetector(
        //   onLongPressStart: (_) {
        //     var pos = _.globalPosition;
        //     print(pos.dx);
        //     showSMMMenu<dynamic>(
        //       context: context,
        //       elevation: 1,

        //       items: <SMMPopupMenuEntry<dynamic>>[
        //         SMMPopupMenuItem<void>(
        //           value: '',
        //           child: Center(
        //             child: Text(
        //               'Флексануть,,,,,,,,,,,,,,,,,,,,,,,,',
        //               style: TextStyle(fontSize: 16),
        //             ),
        //           ),
        //         ),
        //       ],
        //       initialValue: "kek",
        //       // position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width/16, pos.dy + 8.0, 0, 0),

        //       position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),

        //       // menuBorderRadius: widget.menuBorderRadius,
        //       menuPadding: const EdgeInsets.all(0.0),
        //     );
        //   },
        //   child:
        ListTileTheme(
      key: _key,
      selectedColor: Theme.of(context).textTheme.headline6.color,
      child: SMMListTile(
        subtitle: Artist(artist: widget.song.artist),
        // subtitle: Text(song.artist),
        dense: true,
        isThreeLine: false,
        contentPadding: const EdgeInsets.only(left: 10, top: 0),
        onTap: () => _handleTap(context),
        leading: AlbumArtSmall(path: widget.song.albumArtUri),
        title: Text(
          widget.song.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15 /* Default flutter title font size (not dense) */,
          ),
        ),
        trailing: widget.playing
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            : null,
      ),
      // ),
    );
  }
}

/// [SongTile] that represents a single track in [TrackList]
class SelectableSongTile extends StatefulWidget implements SongTileInterface {
  SelectableSongTile({
    Key key,
    @required this.song,
    @required this.selectionSet,
    @required this.selectionController,
    this.pushToPlayerRouteOnClick = true,
    this.playing = false,
    this.onTap,
    this.onSelected,
    this.onUnselected,
    this.selected = false,
    this.unselecting = false,
  })  : assert(song != null),
        super(key: key);

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  @override
  final Song song;

  /// A set to of selected songs.
  /// The items are automatically added on tile selection.
  final Set<int> selectionSet;

  /// Global selection controller
  final AnimationController selectionController;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function onTap;

  // Selection props

  /// Callback that is fired when item gets selected (before animation)
  final void Function(Song) onSelected;

  /// Callback that is fired when item gets unselected (before animation)
  final void Function(Song) onUnselected;

  /// Makes tiles to be selected on first render, after this can be done via internal state
  final bool selected;

  /// Blocks tile events when true
  ///
  /// Used to know when unselection animation is performed and perform it too
  final bool unselecting;

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
      duration: kSMMSelectionDuration,
    );

    final CurvedAnimation animationBase = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _animationOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationBase);
    _animationOpacityInverse =
        Tween<double>(begin: 1.0, end: 0.0).animate(animationBase);

    _animationBorderRadius =
        Tween<double>(begin: 10.0, end: 20.0).animate(animationBase);

    _animationScale =
        Tween<double>(begin: 1.0, end: 1.2).animate(animationBase);

    _animationScaleInverse =
        // Tween<double>(begin: 1.17, end: 1.0).animate(animationBase);
        Tween<double>(begin: 1.23, end: 1.0).animate(animationBase);

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
        _animationController.reverse();
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

  void _handleTap() {
    if (widget.onTap != null) widget.onTap();
    MusicPlayer.handleClickSongTile(context, widget.song,
        pushToPlayerRoute: widget.pushToPlayerRouteOnClick);
  }

  void _select() {
    widget.selectionSet.add(widget.song.id);
    widget.selectionController.forward();
    // widget.onSelected();
    _animationController.forward();
    if (widget.onSelected != null) {
      widget.onSelected(widget.song);
    }
  }

  // Performs unselect animation and calls [onSelected] and [notifyUnselection]
  void _unselect([bool onMount = false]) {
    // widget.onUnselected(onMount);
    widget.selectionSet.remove(widget.song.id);
    _animationController.reverse();
    if (widget.onUnselected != null) {
      widget.onUnselected(widget.song);
    }
    // widget.notifyUnselection();
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
      ignoring: widget.selectionController.status == AnimationStatus.reverse,
      child: ListTileTheme(
        selectedColor: Theme.of(context).textTheme.headline6.color,
        child: SMMListTile(
          subtitle: Artist(artist: widget.song.artist),
          selected: _selected,
          dense: true,
          isThreeLine: false,
          contentPadding: const EdgeInsets.only(left: 10, top: 0),
          onTap: widget.selectionSet.isNotEmpty ? _toggleSelection : _handleTap,
          onLongPress: _toggleSelection,
          title: Text(
            widget.song.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15 /* Default flutter title font size (not dense) */,
            ),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(_animationBorderRadius.value),
            child: Stack(
              children: <Widget>[
                FadeTransition(
                  opacity: _animationOpacityInverse, // Inverse values
                  child: ScaleTransition(
                    scale: _animationScale,
                    child: AlbumArtSmall(path: widget.song.albumArtUri),
                  ),
                ),
                if (_animationController.value != 0)
                  FadeTransition(
                    opacity: _animationOpacity,
                    child: Container(
                      width: 48.0,
                      height: 48.0,
                      color: Theme.of(context).colorScheme.primary,
                      child: ScaleTransition(
                        scale: _animationScaleInverse,
                        child: const Icon(
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
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
          // ),
        ),
      ),
    );
  }
}
