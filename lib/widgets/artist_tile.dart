/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
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
    double? horizontalPadding,
  })  : horizontalPadding = horizontalPadding ?? _horizontalPadding,
        index = null,
        super(key: key);

  const ArtistTile.selectable({
    Key? key,
    required this.artist,
    required int this.index,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    this.trailing,
    this.current,
    this.onTap,
    double? horizontalPadding,
  }) : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
              selectionController is SelectionController<SelectionEntry<Artist>>),
       horizontalPadding = horizontalPadding ?? _horizontalPadding,
       super.selectable(
         key: key,
         selected: selected,
         selectionController: selectionController,
       );

  final Artist artist;
  final int? index;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this queue is currently playing, if yes, enables animated
  /// [CurrentIndicator] over the ablum art.
  /// 
  /// If not specified, by default uses [ContentUtils.persistentQueueIsCurrent].
  /// TODO: current
  final bool? current;
  final VoidCallback? onTap;

  final double horizontalPadding;

  @override
  SelectionEntry<Artist> toSelectionEntry() => SelectionEntry<Artist>(
    index: index,
    data: artist,
  );

  @override
  _ArtistTileState createState() => _ArtistTileState();
}

class _ArtistTileState extends SelectableState<ArtistTile> {
  void _handleTap() {
    super.handleTap(() {
      widget.onTap?.call();
      HomeRouter.instance.goto(HomeRoutes.factory.content<Artist>(widget.artist));
    });
  }

  bool get current {
    if (widget.current != null)
      return widget.current!;
    // TODO: current
    return false;
  }

  Widget _buildTile() {
    final source = ContentArtSource.artist(widget.artist);
    final l10n = getl10n(context);
    return InkWell(
      onTap: _handleTap,
      onLongPress: toggleSelection,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ThemeControl.theme.textTheme.headline6,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: widget.trailing,
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
          left: kArtistTileArtSize + 2.0,
          bottom: 2.0,
          child: SelectionCheckmark(animation: animation),
        ),
      ],
    );
  }
}

