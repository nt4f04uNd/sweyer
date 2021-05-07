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
    Key? key,
    String? number,
    this.current = false,
  }) : number = int.tryParse(number ?? ''),
       super(key: key);

  final int? number;
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
    } else if (number != null && number! > 0 && number! < 999) {
      // Since this class won't be used for playlsits, but only for albums,
      // I limit the number to be from 0 to 999, in other cases consider it invalid/unsassigned and show a dot
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
class SongTile extends SelectableWidget<SelectionEntry> {
  SongTile({
    Key? key,
    required this.song,
    this.current,
    this.onTap,
    this.clickBehavior = SongClickBehavior.play,
    this.variant = SongTileVariant.albumArt,
    this.horizontalPadding = kSongTileHorizontalPadding,
  }) : index = null,
       super(key: key);

  SongTile.selectable({
    Key? key,
    required this.song,
    required int this.index,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    this.current,
    this.onTap,
    this.clickBehavior = SongClickBehavior.play,
    this.variant = SongTileVariant.albumArt,
    this.horizontalPadding = kSongTileHorizontalPadding,
  }) : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
              selectionController is SelectionController<SelectionEntry<Song>>),
       super.selectable(
         key: key,
         selected: selected,
         selectionController: selectionController,
       );

  final Song song;
  final int? index;

  /// Whether this song is current, if yes, enables animated
  /// [CurrentIndicator] over the ablum art/instead song number.
  /// 
  /// If not specified, by default uses [ContentUtils.songIsCurrent].
  final bool? current;
  final VoidCallback? onTap;
  final SongClickBehavior clickBehavior;
  final SongTileVariant variant;
  final double horizontalPadding;

  @override
  SelectionEntry<Song> toSelectionEntry() => SelectionEntry<Song>(
    index: index,
    data: song,
  );

  @override
  _SongTileState createState() => _SongTileState();
}

class _SongTileState extends SelectableState<SongTile> {
  bool get showAlbumArt => widget.variant == SongTileVariant.albumArt;

  void _handleTap() {
    super.handleTap(() async {
      widget.onTap?.call();
      await MusicPlayer.instance.handleSongClick(
        context,
        widget.song,
        behavior: widget.clickBehavior,
      );
    });
  }

  bool get current {
    return widget.current ?? ContentUtils.songIsCurrent(widget.song);
  }

  Widget _buildTile(Widget albumArt, [double? rightPadding]) {
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
      onLongPress: toggleSelection,
      title: title,
      subtitle: subtitle,
      leading: albumArt,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget albumArt;
    if (showAlbumArt) {
      albumArt = ContentArt.songTile(
        source: ContentArtSource.song(widget.song),
        current: current,
      );
    } else {
      albumArt = SongNumber(
        number: widget.song.track,
        current: current,
      );
    }
    if (!selectable)
      return _buildTile(albumArt);
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            var rightPadding = widget.horizontalPadding;
            if (!showAlbumArt) {
              if (animation.status == AnimationStatus.forward ||
                  animation.status == AnimationStatus.completed ||
                  animation.value > 0.2) {
                rightPadding += 40.0;
              }
            }
            return _buildTile(albumArt, rightPadding);
          },
        ),
        if (animation.status != AnimationStatus.dismissed)
          Positioned(
            left: showAlbumArt ? 34.0 + widget.horizontalPadding : null,
            right: showAlbumArt ? null : 10.0 + widget.horizontalPadding,
            bottom: showAlbumArt ? 2.0 : 20.0,
            child: SelectionCheckmark(animation: animation),
          ),
      ],
    );
  }
}
