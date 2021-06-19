/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/logic/logic.dart';
import 'package:sweyer/sweyer.dart';

/// Generalizes all content tiles into one widget and exposes
/// common propertlies of all tiles.
class ContentTile<T extends Content> extends StatelessWidget {
  const ContentTile({
    Key? key,
    this.contentType,
    required this.content,
    this.trailing,
    this.current,
    this.onTap,
    this.horizontalPadding,
    this.backgroundColor = Colors.transparent,
    this.songTileVariant = kSongTileVariant,
    this.songTileClickBehavior = kSongTileClickBehavior,
    this.index,
    this.selected = false,
    this.selectionGestureEnabled = true,
    this.selectionController,
  }) : super(key: key);

  final Type? contentType;
  final T content;
  final Widget? trailing;
  final bool? current;
  final VoidCallback? onTap;
  final double? horizontalPadding;
  final Color backgroundColor;
  final SongTileVariant songTileVariant;
  final SongTileClickBehavior songTileClickBehavior;

  final int? index;
  final bool selected;
  final bool selectionGestureEnabled;
  final ContentSelectionController<SelectionEntry>? selectionController;

  static double getHeight<T extends Content>(Type? contentType) {
    return contentPick<T, double>(
      contentType: contentType,
      song: kSongTileHeight,
      album: kPersistentQueueTileHeight,
      playlist: kPersistentQueueTileHeight,
      artist: kArtistTileHeight,
    );
  }

  bool get selectable => selectionController != null;

  ValueGetter<Widget> forPersistentQueue<Q extends PersistentQueue>() {
    return () => !selectable
      ? PersistentQueueTile<Q>(
          queue: content as Q,
          onTap: onTap,
          trailing: trailing,
          current: current,
          horizontalPadding: horizontalPadding,
          backgroundColor: backgroundColor,
        )
      : PersistentQueueTile<Q>.selectable(
          queue: content as Q,
          index: index!,
          selectionController: selectionController!,
          selected: selected,
          selectionGestureEnabled: selectionGestureEnabled,
          trailing: trailing,
          current: current,
          onTap: onTap,
          horizontalPadding: horizontalPadding,
          backgroundColor: backgroundColor,
        );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !selectable || selectable && index != null,
      'If tile is selectable, an `index` must be provided'
    );

    final localSelectable = selectable;
    return contentPick<T, ValueGetter<Widget>>(
      contentType: contentType,
      song: () => !localSelectable
        ? SongTile(
            song: content as Song,
            trailing: trailing,
            current: current,
            onTap: onTap,
            horizontalPadding: horizontalPadding ?? kSongTileHorizontalPadding,
            backgroundColor: backgroundColor,
            variant: songTileVariant,
            clickBehavior: songTileClickBehavior,
          )
        : SongTile.selectable(
            song: content as Song,
            index: index!,
            selectionController: selectionController,
            selected: selected,
            selectionGestureEnabled: selectionGestureEnabled,
            trailing: trailing,
            current: current,
            onTap: onTap,
            horizontalPadding: horizontalPadding ?? kSongTileHorizontalPadding,
            backgroundColor: backgroundColor,
            variant: songTileVariant,
            clickBehavior: songTileClickBehavior,
          ),
      album: forPersistentQueue<Album>(),
      playlist: forPersistentQueue<Playlist>(),
      artist: () => !localSelectable
        ? ArtistTile(
            artist: content as Artist,
            trailing: trailing,
            current: current,
            onTap: onTap,
            horizontalPadding: horizontalPadding,
            backgroundColor: backgroundColor,
          )
        : ArtistTile.selectable(
            artist: content as Artist,
            index: index!,
            selectionController: selectionController,
            selected: selected,
            selectionGestureEnabled: selectionGestureEnabled,
            trailing: trailing,
            current: current,
            onTap: onTap,
            horizontalPadding: horizontalPadding,
            backgroundColor: backgroundColor,
          ),
    )();
  }
}