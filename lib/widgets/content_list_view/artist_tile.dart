import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar computations.
const double kArtistTileHeight = kArtistTileArtSize + _tileVerticalPadding * 2;
const double _tileVerticalPadding = 8.0;
const double _horizontalPadding = 16.0;

class ArtistTile extends SelectableWidget<SelectionEntry> {
  const ArtistTile({
    Key? key,
    required this.artist,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    double? horizontalPadding,
    this.backgroundColor = Colors.transparent,
  })  : horizontalPadding = horizontalPadding ?? _horizontalPadding,
        super(key: key);

  const ArtistTile.selectable({
    Key? key,
    required this.artist,
    required int selectionIndex,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    bool longPressSelectionGestureEnabled = true,
    bool handleTapInSelection = true,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    double? horizontalPadding,
    this.backgroundColor = Colors.transparent,
  })  : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
            selectionController is SelectionController<SelectionEntry<Artist>>),
        horizontalPadding = horizontalPadding ?? _horizontalPadding,
        super.selectable(
          key: key,
          selectionIndex: selectionIndex,
          selected: selected,
          longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
          handleTapInSelection: handleTapInSelection,
          selectionController: selectionController,
        );

  final Artist artist;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this queue is currently playing, if yes, enables animated
  /// [CurrentIndicator] over the album art.
  ///
  /// If not specified, by default uses [ContentUtils.originIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Whether to handle taps by default.
  /// By default plays song on tap.
  final bool enableDefaultOnTap;

  final double horizontalPadding;

  /// Background tile color.
  /// By default tile background is transparent.
  final Color backgroundColor;

  @override
  _ArtistTileState createState() => _ArtistTileState();
}

class _ArtistTileState extends SelectableState<SelectionEntry<Artist>, ArtistTile> with ContentTileComponentsMixin {
  @override
  SelectionEntry<Artist> toSelectionEntry() => SelectionEntry<Artist>.fromContent(
        content: widget.artist,
        index: widget.selectionIndex!,
        context: context,
      );

  void _handleTap() {
    super.handleTap(() {
      widget.onTap?.call();
      HomeRouter.of(context).goto(HomeRoutes.factory.content<Artist>(widget.artist));
    });
  }

  bool get current {
    if (widget.current != null) {
      return widget.current!;
    }
    return ContentUtils.originIsCurrent(widget.artist);
  }

  Widget _buildTile() {
    final source = ContentArtSource.artist(widget.artist);
    final l10n = getl10n(context);
    return Material(
      color: widget.backgroundColor,
      child: InkWell(
        onTap: widget.enableDefaultOnTap || selectable && widget.selectionController!.inSelection
            ? _handleTap
            : widget.onTap,
        onLongPress: handleLongPress,
        splashFactory: NFListTileInkRipple.splashFactory,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: _tileVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ContentArt.artistTile(
                  source: source,
                  defaultArtIcon: Artist.icon,
                  current: current,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ContentUtils.localizedArtist(widget.artist.artist, l10n),
                        overflow: TextOverflow.ellipsis,
                        style: ThemeControl.instance.theme.textTheme.headline6,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FavoriteIndicator(shown: widget.artist.isFavorite),
                  if (widget.trailing != null) widget.trailing!,
                  if (selectionRoute) buildAddToSelection(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!selectable) {
      return _buildTile();
    }
    return Stack(
      children: [
        _buildTile(),
        if (!selectionRoute && animation.status != AnimationStatus.dismissed)
          Positioned(
            left: kArtistTileArtSize - 4.0,
            bottom: 6.0,
            child: SelectionCheckmark(animation: animation),
          ),
      ],
    );
  }
}
