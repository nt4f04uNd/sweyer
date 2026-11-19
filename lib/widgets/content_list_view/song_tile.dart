import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar label computations
const double _tileVerticalPadding = 8.0;

/// The padding that is added to the top of the subtitle widget.
const _subtitleTopPadding = 4.0;

/// The padding that is added to the bottom of the subtitle widget.
const _subtitleBottomPadding = 3.0;

/// The [TextStyle] used for the title text from the [theme].
TextStyle? _titleTheme(ThemeData theme) => theme.textTheme.titleLarge;
TextStyle? _subtitleTheme(ThemeData theme) => ArtistWidget.defaultTextStyle(theme);

double kSongTileHeight(BuildContext context) => _calculateSongTileHeight(context);

double _calculateSongTileHeight(BuildContext context) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  final theme = Theme.of(context);
  return _calculateSongTileHeightMemo(
    textScaleFactor,
    _titleTheme(theme)?.fontSize,
    _subtitleTheme(theme)?.fontSize,
    context,
  );
}

final _calculateSongTileHeightMemo = imemo3plus1(
  (double a1, double? a2, double? a3, BuildContext context) =>
      math.max(
        kSongTileArtSize,
        _kSongTileTextHeight(context),
      ) +
      _tileVerticalPadding * 2,
);

/// The height of the title and subtitle part of the [SongTile].
double _kSongTileTextHeight(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);
  final theme = Theme.of(context);
  return calculateLineHeight(_titleTheme(theme), textScaler) +
      calculateLineHeight(_subtitleTheme(theme), textScaler) +
      _subtitleTopPadding +
      _subtitleBottomPadding;
}

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
    super.key,
    String? number,
    this.current = false,
  }) : number = int.tryParse(number ?? '');

  final int? number;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (current) {
      child = Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: CurrentIndicator(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    } else if (number != null && number! > 0 && number! < 999) {
      // Since this class won't be used for playlists, but only for albums,
      // I limit the number to be from 0 to 999, in other cases consider it invalid/unassigned and show a dot
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
          color: theme.colorScheme.onSecondaryContainer,
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
  const SongTile({
    super.key,
    required this.song,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.showFavoriteIndicator = true,
    this.variant = kSongTileVariant,
    this.clickBehavior = kSongTileClickBehavior,
    this.horizontalPadding = kSongTileHorizontalPadding,
    this.backgroundColor = Colors.transparent,
  });

  const SongTile.selectable({
    super.key,
    required this.song,
    required super.selectionIndex,
    required super.selectionController,
    super.selected = false,
    super.longPressSelectionGestureEnabled = true,
    super.handleTapInSelection = true,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.showFavoriteIndicator = true,
    this.variant = kSongTileVariant,
    this.clickBehavior = kSongTileClickBehavior,
    this.horizontalPadding = kSongTileHorizontalPadding,
    this.backgroundColor = Colors.transparent,
  })  : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
            selectionController is SelectionController<SelectionEntry<Song>>),
        super.selectable();

  final Song song;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this song is current, if yes, enables animated
  /// [CurrentIndicator] over the album art/instead song number.
  ///
  /// If not specified, by default uses [ContentUtils.songIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Whether to handle taps by default.
  /// By default plays song on tap.
  final bool enableDefaultOnTap;

  /// Whether to show the trailing favorite heart indicator.
  final bool showFavoriteIndicator;

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
  SelectionEntry<Song> toSelectionEntry() => SelectionEntry<Song>.fromContent(
        content: widget.song,
        index: widget.selectionIndex!,
        context: context,
      );

  @override
  bool? get widgetSelected =>
      selectionRoute ? widget.selectionController!.data.contains(toSelectionEntry()) : super.widgetSelected;

  bool get showAlbumArt => widget.variant == SongTileVariant.albumArt;

  void _handleTap() {
    super.handleTap(() async {
      widget.onTap?.call();
      final song = widget.song;
      final player = PlayerManager.instance;
      if (!selectionRoute && widget.clickBehavior == SongTileClickBehavior.play) {
        playerRouteController.open();
        await player.setSong(song);
        await player.play();
      } else {
        if (song == PlaybackControl.instance.currentSong) {
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
    final theme = Theme.of(context);
    Widget title = Text(
      widget.song.title,
      overflow: TextOverflow.ellipsis,
      style: _titleTheme(theme),
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
      child: Material(
        color: widget.backgroundColor,
        child: InkWell(
          onTap: widget.enableDefaultOnTap || selectable && widget.selectionController!.inSelection
              ? _handleTap
              : widget.onTap,
          onLongPress: handleLongPress,
          splashFactory: NFListTileInkRipple.splashFactory,
          child: Padding(
            padding: EdgeInsets.only(
              top: _tileVerticalPadding,
              bottom: _tileVerticalPadding,
              left: widget.horizontalPadding,
              right: rightPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: albumArt,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        title,
                        const SizedBox(height: _subtitleTopPadding),
                        subtitle,
                        const SizedBox(height: _subtitleBottomPadding),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showFavoriteIndicator) FavoriteIndicator(shown: widget.song.isFavorite),
                    if (widget.trailing != null) widget.trailing!,
                    if (selectionRoute) buildAddToSelection(),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    if (!selectable) {
      return _buildTile(albumArt);
    }
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
