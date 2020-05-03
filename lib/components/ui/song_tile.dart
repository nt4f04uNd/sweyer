/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

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
  void _handleTap() async {
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
        //       menuPadding: EdgeInsets.zero,
        //     );
        //   },
        //   child:
        SMMListTile(
      key: _key,
      subtitle: Artist(artist: widget.song.artist),
      // subtitle: Text(song.artist),
      dense: true,
      isThreeLine: false,
      contentPadding: const EdgeInsets.only(left: 10.0, top: 0.0),
      onTap: _handleTap,
      leading: AlbumArtSmall(path: widget.song.albumArt),
      title: Text(
        widget.song.title,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headline6,
      ),
      trailing: widget.playing ? const SongIndicator() : null,
      // ),
    );
  }
}

/// [SongTile] that represents a single track in [SongListTab]
class SelectableSongTile extends StatefulWidget implements SongTileInterface {
  SelectableSongTile({
    Key key,
    @required this.song,
    @required this.selectionController,
    this.pushToPlayerRouteOnClick = true,
    this.playing = false,
    this.onTap,
    this.selected = false,
  })  : assert(song != null),
        super(key: key);

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  @override
  final Song song;

  /// Global selection controller
  final SelectionController selectionController;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function onTap;

  /// Basically makes tiles to be selected on first render, after this can be done via internal state
  final bool selected;

  @override
  _SelectableSongTileState createState() => _SelectableSongTileState();
}

class _SelectableSongTileState extends State<SelectableSongTile>
    with SingleTickerProviderStateMixin {
  /// Is track tile selected or not
  bool _selected;

  AnimationController _animationController;
  CurvedAnimation _animationBase;
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
    _animationController.addListener(() => setState(() {}));

    _animationBase = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _animationOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationBase);
    _animationOpacityInverse =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationBase);
    _animationBorderRadius =
        Tween<double>(begin: 10.0, end: 20.0).animate(_animationBase);
    _animationScale =
        Tween<double>(begin: 1.0, end: 1.2).animate(_animationBase);
    _animationScaleInverse =
        // Tween<double>(begin: 1.17, end: 1.0).animate(_animationBase);
        Tween<double>(begin: 1.23, end: 1.0).animate(_animationBase);

    /// We have to check if controller is "closing", i.e. user pressed global close button to quit the selection.
    /// Doing this check, if user will start to fling down very fast at this moment, some tiles that will be built at this moment
    /// will know about they have to play the unselection animation too.
    if (widget.selectionController.notInSelection) {
      // Perform unselection animation
      if (_selected) {
        _selected = false;
        _animationController.value =
            widget.selectionController.animationController.value;
        _animationController.reverse();
      }
    } else {
      if (_selected) {
        _animationController.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.selectionController.inSelection) {
      _toggleSelection();
    } else {
      if (widget.onTap != null) widget.onTap();
      MusicPlayer.handleClickSongTile(context, widget.song,
          pushToPlayerRoute: widget.pushToPlayerRouteOnClick);
    }
  }

  void _select() {
    widget.selectionController.selectItem(widget.song.id);
    _animationController.forward();
  }

  // Performs unselect animation and calls [onSelected] and [notifyUnselection]
  void _unselect() {
    widget.selectionController.unselectItem(widget.song.id);
    _animationController.reverse();
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
    final theme = Theme.of(context);
    return SMMListTile(
      subtitle: Artist(artist: widget.song.artist),
      dense: true,
      isThreeLine: false,
      contentPadding: const EdgeInsets.only(left: 10.0, top: 0.0),
      onTap: _handleTap,
      onLongPress: _toggleSelection,
      title: Text(
        widget.song.title,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.headline6,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(_animationBorderRadius.value),
        child: Stack(
          children: <Widget>[
            FadeTransition(
              opacity: _animationOpacityInverse, // Inverse values
              child: ScaleTransition(
                scale: _animationScale,
                child: AlbumArtSmall(path: widget.song.albumArt),
              ),
            ),
            if (_animationController.value != 0)
              FadeTransition(
                opacity: _animationOpacity,
                child: Container(
                  width: 48.0,
                  height: 48.0,
                  color: theme.colorScheme.primary,
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
      trailing: widget.playing ? const SongIndicator() : null,
    );
  }
}
