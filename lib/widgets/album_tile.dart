/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar computations.
const double kAlbumTileHeight = kAlbumTileArtSize + _tileVerticalPadding * 2;
const double _tileVerticalPadding = 8.0;
const double _horizontalPadding = 16.0;

/// todo: [Selectable] interface
class AlbumTile extends StatefulWidget {
  const AlbumTile({
    Key key,
    @required this.album,
    this.current = false,
    this.onTap,
    this.small = false,
    double horizontalPadding,
  })  : assert(album != null),
        horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
        index = null,
        selected = null,
        selectionController = null,
        super(key: key);

  const AlbumTile.selectable({
    Key key,
    @required this.album,
    @required this.index,
    @required this.selectionController,
    this.current = false,
    this.onTap,
    this.small = false,
    double horizontalPadding,
    this.selected = false,
  })  : assert(album != null),
        assert(index != null),
        assert(selectionController != null),
        horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
        super(key: key);

  final Album album;
  final int index;

  /// Whether this album is currently playing.
  /// Enables animated indicator at the end of the tile.
  final bool current;
  final VoidCallback onTap;

  /// Creates a small variant of the tile with the sizes of [SelectableTile].
  final bool small;
  final double horizontalPadding;

  final bool selected;
  final SelectionController<AlbumSelectionEntry> selectionController;

  @override
  _AlbumTileState createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile> with SingleTickerProviderStateMixin {
  bool _selected;
  AnimationController controller;
  Animation scaleAnimation;

  bool get selectable => widget.selectionController != null;

  AlbumSelectionEntry get selectionEntry => AlbumSelectionEntry(
        index: widget.index,
        album: widget.album,
      );

  @override
  void initState() {
    super.initState();
    if (selectable) {
      _selected = widget.selected ?? false;
      controller = AnimationController(
        vsync: this,
        duration: kSelectionDuration,
      );
      scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      ));
      if (_selected) {
        controller.value = 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant AlbumTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectable) {
      if (selectable && oldWidget.selected != widget.selected) {
        _selected = widget.selected;
        if (_selected) {
          controller.forward();
        } else {
          controller.reverse();
        }
      } else if (widget.selectionController.notInSelection && _selected) {
        /// We have to check if controller is 'closing', i.e. user pressed global close button to quit the selection.
        _selected = false;
        controller.value = widget.selectionController.animationController.value;
        controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (controller != null) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap() async {
    if (selectable && widget.selectionController.inSelection) {
      _toggleSelection();
    } else {
      if (widget.onTap != null) {
        widget.onTap();
      }
      HomeRouter.instance.goto(HomeRoutes.factory.album(widget.album));
    }
  }

  void _toggleSelection() {
    if (!selectable)
      return;
    setState(() {
      _selected = !_selected;
    });
    if (_selected)
      _select();
    else
      _unselect();
  }

  void _select() {
    widget.selectionController.selectItem(selectionEntry);
    controller.forward();
  }

  void _unselect() {
    widget.selectionController.unselectItem(selectionEntry);
    controller.reverse();
  }

  Widget _buildTile() {
    return InkWell(
      onTap: _handleTap,
      onLongPress: selectable ? _toggleSelection : null,
      splashFactory: NFListTileInkRipple.splashFactory,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: _tileVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.small
                ? AlbumArt.songTile(
                    path: widget.album.albumArt,
                    current: widget.current,
                  )
                : AlbumArt.albumTile(
                  path: widget.album.albumArt,
                  current: widget.current,
                ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.album.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ThemeControl.theme.textTheme.headline6,
                    ),
                    ArtistWidget(
                      artist: widget.album.artist,
                      textStyle: const TextStyle(fontSize: 14.0, height: 1.0),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!selectable)
      return _buildTile();
    return Stack(
      children: [
        _buildTile(),
        Positioned(
          left: 72.0,
          bottom: 2.0,
          child: SelectionCheckmark(animation: scaleAnimation),
        ),
      ],
    );
  }
}
