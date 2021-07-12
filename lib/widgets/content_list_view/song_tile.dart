/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar label computations
const double kSongTileHeight = 64.0;
const double kSongTileHorizontalPadding = 10.0;
const SongTileClickBehavior kSongTileClickBehavior = SongTileClickBehavior.play;
const SongTileVariant kSongTileVariant = SongTileVariant.albumArt;

/// Describes how to respond to song tile clicks.
enum SongTileClickBehavior {
  /// Always start the clicked song from  play,

  /// A  ///
  /// Expands that player route.
  play,

  /// Allow play/pause on the clicked song.
  ///
  /// Doesn't expand the player route.
  playPause,
}

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
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.variant = kSongTileVariant,
    this.clickBehavior = kSongTileClickBehavior,
    this.horizontalPadding = kSongTileHorizontalPadding,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  SongTile.selectable({
    Key? key,
    required this.song,
    required int selectionIndex,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    bool longPressSelectionGestureEnabled = true,
    bool handleTapInSelection = true,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.variant = kSongTileVariant,
    this.clickBehavior = kSongTileClickBehavior,
    this.horizontalPadding = kSongTileHorizontalPadding,
    this.backgroundColor = Colors.transparent,
  }) : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
              selectionController is SelectionController<SelectionEntry<Song>>),
       super.selectable(
         key: key,
         selectionIndex: selectionIndex,
         selected: selected,
         longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
         handleTapInSelection: handleTapInSelection,
         selectionController: selectionController,
       );

  final Song song;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this song is current, if yes, enables animated
  /// [CurrentIndicator] over the ablum art/instead song number.
  /// 
  /// If not specified, by default uses [ContentUtils.songIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Whether to handle taps by default.
  /// By default plays song on tap.
  final bool enableDefaultOnTap;

  final SongTileVariant variant;

  /// How to respond to tile clicks.
  ///
  /// Will be force treated as [SongTileClickBehavior.playPause] if [selectionRouteOf] is `true`.
  final SongTileClickBehavior clickBehavior;
  final double horizontalPadding;

  /// Background tile color.
  /// By default tile background is transparent.
  final Color backgroundColor;

  @override
  _SongTileState createState() => _SongTileState();
}

class _SongTileState extends SelectableState<SelectionEntry<Song>, SongTile> with ContentTileComponentsMixin {
  Color? previousBackgroundColor;

  @override
  void didUpdateWidget(SongTile oldWidget) {
    previousBackgroundColor = oldWidget.backgroundColor;
    super.didUpdateWidget(oldWidget);
  }

  @override
  SelectionEntry<Song> toSelectionEntry() => SelectionEntry<Song>(
    index: selectionRoute
      ? ContentControl.state.allSongs.getIndex(widget.song)
      : widget.selectionIndex!,
    data: widget.song,
    origin: selectionRoute && widget.song.origin is DuplicatingSongOriginMixin ? widget.song.origin : null,
  );

  @override
  bool? get widgetSelected => selectionRoute
    ? widget.selectionController!.data.contains(SelectionEntry<Song>(
        index: ContentControl.state.allSongs.getIndex(widget.song),
        data: widget.song,
        origin: widget.song.origin is DuplicatingSongOriginMixin ? widget.song.origin : null,
      ))
    : super.widgetSelected;

  bool get showAlbumArt => widget.variant == SongTileVariant.albumArt;

  void _handleTap() {
    super.handleTap(() async {
      widget.onTap?.call();
      final song = widget.song;
      final player = MusicPlayer.instance;
      if (!selectionRoute && widget.clickBehavior == SongTileClickBehavior.play) {
        playerRouteController.open();
        await player.setSong(song);
        await player.play();
      } else {
        if (song == ContentControl.state.currentSong) {
          if (!player.playing) {
            await player.play();
          } else {
            await player.pause();
          }
        } else {
          await player.setSong(song);
          await player.play();
        }
      }
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
    Widget subtitle = ArtistWidget(
      artist: widget.song.artist,
      trailingText: formatDuration(Duration(milliseconds: widget.song.duration)),
    );
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

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: ColorTween(begin: previousBackgroundColor, end: widget.backgroundColor),
      builder: (context, value, child) => Material(
        color: value,
        child: child,
      ),
      child: NFListTile(
        dense: true,
        isThreeLine: false,
        contentPadding: EdgeInsets.only(
          left: widget.horizontalPadding,
          right: rightPadding,
        ),
        onTap: widget.enableDefaultOnTap || selectable && widget.selectionController!.inSelection
          ? _handleTap
          : widget.onTap,
        onLongPress: handleLongPress,
        title: title,
        subtitle: subtitle,
        leading: albumArt,
        trailing: selectionRoute
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.trailing != null)
                  widget.trailing!,
                buildAddToSelection(),
              ],
            )
          : widget.trailing,
      ),
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
            if (!showAlbumArt && !selectionRoute) {
              if (animation.status == AnimationStatus.forward ||
                  animation.status == AnimationStatus.completed ||
                  animation.value > 0.2) {
                rightPadding += 40.0;
              }
            }
            return _buildTile(albumArt, rightPadding);
          },
        ),
        if (!selectionRoute && animation.status != AnimationStatus.dismissed)
          Positioned(
            left: showAlbumArt ? 34.0 + widget.horizontalPadding : null,
            right: showAlbumArt ? null : 4.0 + widget.horizontalPadding,
            bottom: showAlbumArt ? 2.0 : 20.0,
            child: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: SelectionCheckmark(animation: animation),
            ),
          ),
      ],
    );
  }
}
