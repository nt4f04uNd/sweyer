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
        contentPadding: const EdgeInsets.only(left: 10.0, top: 0.0),
        onTap: _handleTap,
        leading: AlbumArtSmall(path: widget.song.albumArt),
        title: Text(
          widget.song.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15.0 /* Default flutter title font size (not dense) */,
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
                    borderRadius: BorderRadius.circular(10.0),
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

  /// Makes tiles to be selected on first render, after this can be done via internal state
  final bool selected;

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

    if (widget.selectionController.isClosing) {
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
    if (widget.selectionController.selectionSet.isNotEmpty &&
        !widget.selectionController.isClosing) {
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
  void _unselect([bool onMount = false]) {
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
    return ListTileTheme(
      selectedColor: Theme.of(context).textTheme.headline6.color,
      child: SMMListTile(
        subtitle: Artist(artist: widget.song.artist),
        selected: _selected,
        dense: true,
        isThreeLine: false,
        contentPadding: const EdgeInsets.only(left: 10.0, top: 0.0),
        onTap: _handleTap,
        onLongPress: _toggleSelection,
        title: Text(
          widget.song.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15.0 /* Default flutter title font size (not dense) */,
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
                  child: AlbumArtSmall(path: widget.song.albumArt),
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
                  width: 10.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
      ),
    );
  }
}
