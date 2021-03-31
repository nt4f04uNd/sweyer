/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar label computations
const double kSongTileHeight = 64.0;
const double kSongTileHorizontalPadding = 10.0;

/// Describes what to draw in the tile leading.
enum SongTileVariant {
  /// Set by default, will draw an [AlbumArt.songTile] in the tile leading.
  albumArt,

  /// Will draw [SongNumber] in the tile leading.
  number
}

/// Supposed to draw a [Song.track] number, or '-' symbol if it's null.
class SongNumber extends StatelessWidget {
  SongNumber({
    Key key,
    String number,
    this.current = false,
  })  : assert(current != null),
        number = int.tryParse(number ?? ''),
        super(key: key);
  final int number;
  final bool current;
  @override
  Widget build(BuildContext context) {
    Widget child;
    if (current) {
      child = Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: CurrentIndicator(
          color: ThemeControl.theme.colorScheme.onBackground,
        ),
      );
    } else if (number != null && number > 0 && number < 999) {
      // since this class won't be used for playlsits, but only for albums
      // i limit the number to be from 0 to 999, in other cases consider it invalid/unsassigned and show a dot
      child = Text(
        number.toString(),
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      child = Container(
        width: 7.0,
        height: 7.0,
        decoration: BoxDecoration(
          color: ThemeControl.theme.colorScheme.onBackground,
          borderRadius: const BorderRadius.all(
            Radius.circular(100.0),
          ),
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      width: kSongTileArtSize,
      height: kSongTileArtSize,
      padding: const EdgeInsets.only(right: 4.0),
      child: child,
    );
  }
}

/// A [SongTile] that can be selected.
///
/// todo: [Selectable] interface
class SongTile extends StatefulWidget {
  SongTile({
    Key key,
    @required this.song,
    this.current = false,
    this.onTap,
    this.clickBehavior = SongClickBehavior.play,
    this.variant = SongTileVariant.albumArt,
    this.horizontalPadding = kSongTileHorizontalPadding,
  })  : assert(song != null),
        selected = null,
        index = null,
        selectionController = null,
        super(key: key);

  SongTile.selectable({
    Key key,
    @required this.song,
    @required this.index,
    @required this.selectionController,
    this.current = false,
    this.onTap,
    this.selected = false,
    this.clickBehavior = SongClickBehavior.play,
    this.variant = SongTileVariant.albumArt,
    this.horizontalPadding = kSongTileHorizontalPadding,
  })  : assert(song != null),
        assert(index != null),
        assert(selectionController != null),
        super(key: key);

  final Song song;
  final int index;

  /// Whether this song is current.
  /// Enables animated indicator at the end of the tile.
  final bool current;
  final VoidCallback onTap;
  final SongClickBehavior clickBehavior;
  final SongTileVariant variant;
  final double horizontalPadding;

  /// Basically makes tiles aware whether they are selected in some global set.
  /// This will be used on first build, after this tile will have internal selection state.
  final bool selected;
  final SelectionController<SongSelectionEntry> selectionController;

  @override
  _SongTileState createState() => _SongTileState();
}

class _SongTileState extends State<SongTile>
    with SingleTickerProviderStateMixin {
  bool _selected;
  AnimationController controller;
  Animation scaleAnimation;

  bool get selectable => widget.selectionController != null;

  SongSelectionEntry get selectionEntry => SongSelectionEntry(
        index: widget.index,
        song: widget.song,
      );

  bool get showAlbumArt => widget.variant == SongTileVariant.albumArt;

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
  void didUpdateWidget(covariant SongTile oldWidget) {
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
      await MusicPlayer.handleSongClick(
        context,
        widget.song,
        behavior: widget.clickBehavior,
      );
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

  Widget _buildTile(
    Widget albumArt, [
    double rightPadding,
  ]) {
    rightPadding ??= widget.horizontalPadding;
    final theme = ThemeControl.theme;
    Widget title = Text(
      widget.song.title,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.headline6,
    );
    Widget subtitle = ArtistWidget(artist: widget.song.artist);
    if (!showAlbumArt) {
      // Reduce padding between leading and title.
      Widget translate(Widget child) {
        return Transform.translate(
          offset: const Offset(-16.0, 0.0),
          child: child,
        );
      }

      title = translate(title);
      subtitle = translate(subtitle);
    }
    return NFListTile(
      dense: true,
      isThreeLine: false,
      contentPadding: EdgeInsets.only(
        left: widget.horizontalPadding,
        right: rightPadding,
      ),
      onTap: _handleTap,
      onLongPress: selectable ? _toggleSelection : null,
      title: title,
      subtitle: subtitle,
      leading: albumArt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumArt = showAlbumArt
        ? AlbumArt.songTile(
            path: widget.song.albumArt,
            current: widget.current,
          )
        : SongNumber(
            number: widget.song.track,
            current: widget.current,
          );
    if (!selectable)
      return _buildTile(albumArt);
    return Stack(
      children: [
        AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            var rightPadding = widget.horizontalPadding;
            if (!showAlbumArt) {
              if (scaleAnimation.status == AnimationStatus.forward ||
                  scaleAnimation.status == AnimationStatus.completed ||
                  scaleAnimation.value > 0.2) {
                rightPadding += 40.0;
              }
            }
            return _buildTile(albumArt, rightPadding);
          },
        ),
        Positioned(
          left: showAlbumArt ? 34.0 + widget.horizontalPadding : null,
          right: showAlbumArt ? null : 10.0 + widget.horizontalPadding,
          bottom: showAlbumArt ? 2.0 : 20.0,
          child: SelectionCheckmark(animation: scaleAnimation),
        ),
      ],
    );
  }
}
