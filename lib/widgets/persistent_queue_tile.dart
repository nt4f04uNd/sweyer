/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

/// Needed for scrollbar computations.
const double kPersistentQueueTileHeight = kPersistentQueueTileArtSize + _tileVerticalPadding * 2;
const double _tileVerticalPadding = 8.0;
const double _horizontalPadding = 16.0;

class PersistentQueueTile<T extends PersistentQueue> extends SelectableWidget<SelectionEntry> {
  const PersistentQueueTile({
    Key? key,
    required this.queue,
    this.trailing,
    this.current,
    this.onTap,
    this.small = false,
    double? horizontalPadding,
  })  : horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
        index = null,
        super(key: key);

  const PersistentQueueTile.selectable({
    Key? key,
    required this.queue,
    required int this.index,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    this.trailing,
    this.current,
    this.onTap,
    this.small = false,
    double? horizontalPadding,
  }) : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
              selectionController is SelectionController<SelectionEntry<T>>),
       horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
       super.selectable(
         key: key,
         selected: selected,
         selectionController: selectionController,
       );

  final T queue;
  final int? index;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this queue is currently playing, if yes, enables animated
  /// [CurrentIndicator] over the ablum art.
  /// 
  /// If not specified, by default uses [ContentUtils.persistentQueueIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Creates a small variant of the tile with the sizes of [SelectableTile].
  final bool small;
  final double horizontalPadding;

  @override
  SelectionEntry<T> toSelectionEntry() => SelectionEntry<T>(
    index: index,
    data: queue,
  );

  @override
  _PersistentQueueTileState<T> createState() => _PersistentQueueTileState();
}

class _PersistentQueueTileState<T extends PersistentQueue> extends SelectableState<PersistentQueueTile<T>> {
  void _handleTap() {
    super.handleTap(() {
      widget.onTap?.call();
      HomeRouter.instance.goto(HomeRoutes.factory.persistentQueue<T>(widget.queue));
    });
  }

  bool get current {
    if (widget.current != null)
      return widget.current!;
    return ContentUtils.persistentQueueIsCurrent(widget.queue);
  }

  Widget _buildTile() {
    final source = ContentArtSource.persistentQueue(widget.queue);
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
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.small
                ? ContentArt.songTile(
                    source: source,
                    current: current,
                  )
                : ContentArt.persistentQueueTile(
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
                  children: <Widget>[
                    Text(
                      widget.queue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ThemeControl.theme.textTheme.headline6,
                    ),
                    if (widget.queue is Album)
                      ArtistWidget(
                        artist: (widget.queue as Album).artist,
                        textStyle: const TextStyle(fontSize: 14.0, height: 1.0),
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
          left: kPersistentQueueTileArtSize + 2.0,
          bottom: 2.0,
          child: SelectionCheckmark(animation: animation),
        ),
      ],
    );
  }
}
