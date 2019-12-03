import 'package:app/components/albumArt.dart';
import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/buttons.dart';
import 'package:app/components/custom_refresh_indicator.dart';
import 'package:app/components/drawer.dart';
import 'package:app/components/gestures.dart';
import 'package:app/components/show_functions.dart';
import 'package:app/constants/routes.dart';
import 'package:app/constants/themes.dart';
import 'package:app/player/player_widgets.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/song.dart';
import 'package:app/utils/switcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'custom_icon_button.dart';
import 'scrollable_positioned_list/scrollable_positioned_list.dart';

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

  /// Enables selection mode
  bool selectionMode = false;

  /// Denotes state of unselection animation
  bool unselecting = false;

  /// Switcher to control track tiles selection re-render
  IntSwitcher _switcher = IntSwitcher();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool refreshing = false;

  /// Performs tracks refetch
  Future<void> _refreshHandler() async {
    await PlaylistControl.refetchSongs();
    _switcher.change();
    return Future.value();
  }

  /// Adds item index to set and enables selection mode if needed
  void _handleSelect(int id) {
    selectionSet.add(id);
    if (!selectionMode)
      setState(() {
        selectionMode = true;
      });
  }

  /// Removes item index from set and disables selection mode if set is empty
  void _handleUnselect(int id) {
    selectionSet.remove(id);
    if (selectionSet.isEmpty) {
      // If none elements are selected - trigger unselecting animation and disable selection mode
      if (!unselecting) {
        setState(() {
          unselecting = true;
          selectionMode = false;
        });
      } else
        selectionMode = false;
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
    setState(() {
      selectionSet = {};
      selectionMode = false;
      unselecting = false;
    });
  }

  void _handleDelete() {
    ShowFunctions.showDialog(
      context,
      title: Text("Удаление"),
      content: Text(
          "Вы действительно хотите удалить ${selectionSet.length} треков? Это действие необратимо"),
      acceptButton: DialogFlatButton(
        child: Text('Удалить'),
        textColor: AppTheme.redFlatButton.auto(context),
        onPressed: () {
          Navigator.of(context).pop();
          PlaylistControl.deleteSongs(selectionSet);
          setState(() {
            selectionSet = {};
            unselecting = false;
            selectionMode = false;
          });
        },
      ),
      declineButton: DialogFlatButton(
        child: Text('Отмена'),
        textColor: AppTheme.declineButton.auto(context),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: //This will change the drawer background
              AppTheme.drawer.auto(context),
        ),
        child: DrawerWidget(),
      ),
      appBar: AppBar(
        leading: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: selectionMode
              ? IgnorePointer(
                  ignoring: unselecting,
                  child: CustomIconButton(
                    splashColor: AppTheme.splash.auto(context),
                    icon: Icon(Icons.close,
                        color: Theme.of(context).iconTheme.color),
                    color: Theme.of(context).iconTheme.color,
                    onPressed: _handleCloseSelection,
                  ),
                )
              : DrawerButton(),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: selectionMode
                  ? IgnorePointer(
                      ignoring: unselecting,
                      child: CustomIconButton(
                        splashColor: AppTheme.splash.auto(context),
                        key: UniqueKey(),
                        color: Theme.of(context).iconTheme.color,
                        icon: Icon(Icons.delete),
                        onPressed: _handleDelete,
                      ),
                    )
                  : CustomIconButton(
                      splashColor: AppTheme.splash.auto(context),
                      icon: Icon(Icons.sort),
                      color: Theme.of(context).iconTheme.color,
                      onPressed: () =>
                          ShowFunctions.showSongsSortModal(context),
                    ),
            ),
          ),
        ],
        titleSpacing: 0.0,
        title: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: selectionMode ? 0 : 1,
          child: IgnorePointer(
            ignoring: selectionMode,
            child: Padding(
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
                        color: AppTheme.searchFakeInput.auto(context),
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
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: widget.bottomPadding,
            child: Container(
              child: CustomRefreshIndicator(
                color: AppTheme.refreshIndicatorArrow.auto(context),
                backgroundColor:
                    AppTheme.refreshIndicatorBackground.auto(context),
                strokeWidth: 2.5,
                key: _refreshIndicatorKey,
                onRefresh: _refreshHandler,
                child: SingleTouchRecognizerWidget(
                  child: Container(
                    child: Scrollbar(
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: PlaylistControl.length(PlaylistType.global),
                        padding: EdgeInsets.only(bottom: 65, top: 0),
                        itemBuilder: (context, index) {
                          return StreamBuilder(
                              stream: PlaylistControl.onSongChange,
                              builder: (context, snapshot) {
                                final int id = PlaylistControl.getSongByIndex(
                                        index, PlaylistType.global)
                                    .id;
                                return TrackTile(
                                  index,
                                  // Specify object key that can be changed to re-render song tile
                                  key: ObjectKey(
                                      index + _switcher.value * 10000),
                                  selectable: true,
                                  selected: selectionSet.contains(id),
                                  someSelected: selectionMode,
                                  unselecting: unselecting,
                                  playing: id == PlaylistControl.currentSongId,
                                  additionalClickCallback: () {
                                    PlaylistControl.resetPlaylists();
                                  },
                                  onSelected: () => _handleSelect(id),
                                  onUnselected: () => _handleUnselect(id),
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
        child:Scrollbar(
                      child:  ScrollablePositionedList.builder(
          physics: BouncingScrollPhysics(),
          frontScrollController: frontScrollController,
          itemScrollController: itemScrollController,
          itemCount: length,
          padding: EdgeInsets.only(bottom: 10, top: 5),
          initialScrollIndex: initialScrollIndex,
          itemBuilder: (context, index) {
            return StreamBuilder(
                stream: PlaylistControl.onSongChange,
                builder: (context, snapshot) {
                  return TrackTile(
                    index,
                    key: UniqueKey(),
                    playing: index == currentSongIndex,
                    song: PlaylistControl.getSongByIndex(index),
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

  Animation<double> _animationOpacity;
  Animation<double> _animationBorderRadius;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    /// If song data is not provided, then find it by index of row in current row
    _song = widget.song ??
        PlaylistControl.getSongByIndex(
            widget.trackTileIndex, PlaylistType.global);

    _selected = widget.selected ?? false;
    if (widget.selectable) {
      _animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 300));
      _animationOpacity = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
      // 0.4 because we need border radius to be not bigger than 10. 10 to 20(max needed value) is 0.5
      _animationBorderRadius = Tween<double>(begin: 0.5, end: 1).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

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
          _unselect();
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
      Navigator.of(context).pushNamed(Routes.player.value);
  }

  // Performs unselect animation and calls `onSelected` and `notifyUnselection`
  void _unselect() async {
    widget.onUnselected();
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
                fontSize: 16 /* Default flutter title font size (not dense) */),
          ),
          subtitle: Artist(artist: _song.artist),
          selected: _selected,
          dense: true,
          isThreeLine: false,
          leading: widget.selectable
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(_animationBorderRadius.value * 20),
                  child: Stack(children: <Widget>[
                    AlbumArt(path: _song.albumArtUri),
                    if (_animationController.value != 0)
                      Opacity(
                        opacity: _animationOpacity.value,
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.deepPurple,
                          // color: Colors.deepPurple,
                          child: Container(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ]),
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
                        borderRadius: BorderRadius.circular(10)),
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
