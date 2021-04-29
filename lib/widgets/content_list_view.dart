/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';

/// Signature used for [ContentListView.currentTest] and [ContentListView.selected].
///
/// The argument [index] is index of the item.
typedef _ItemTest = bool Function(int index);

/// Signature used for [ContentListView.itemBuilder].
///
/// The [item] is the prebuilt item tile widget.
typedef _ItemBuilder = Widget Function(BuildContext context, int index, Widget item);

/// Renders a list of content.
///
/// Picks some value based on the provided `T` type of [Content].
///
/// Instead of `T`, you can explicitly specify [contentType].
class ContentListView<T extends Content> extends StatelessWidget {
  /// Creates a content list with automatically applied draggable scrollbar.
  const ContentListView({
    Key? key,
    this.contentType,
    required this.list,
    this.itemBuilder,
    this.controller,
    this.selectionController,
    this.leading,
    this.currentTest,
    this.selectedTest,
    this.songTileVariant = SongTileVariant.albumArt,
    this.songClickBehavior = SongClickBehavior.play,
    this.onItemTap,
    this.padding = EdgeInsets.zero,
    this.physics = const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
    this.interactiveScrollbar = true,
    this.alwaysShowScrollbar = false,
    this.showScrollbarLabel = false,
  }) : super(key: key);

  /// An explicit content type.
  final Type? contentType;

  /// Content list.
  final List<T> list;
  
  /// Builder that allows to wrap the prebuilt item tile tile.
  /// For example can be used to add [Dismissible].
  final _ItemBuilder? itemBuilder;

  /// Viewport scroll controller.
  final ScrollController? controller;

  /// If specified, list will be built as [SongTile.selectable],
  /// otherwise [SongTile] is used (in case if content is [Song]).
  final ContentSelectionController<SelectionEntry>? selectionController;

  /// A widget to build before all items.
  final Widget? leading;

  /// Returned value is passed to [SongTile.current] (in case if content is [Song]).
  ///
  /// The argument [index] is index of the song.
  final _ItemTest? currentTest;

  /// Returned values is passed to [SongTile.selected] (in case if content is [Song]).
  /// 
  /// The argument [index] is index of the song.
  final _ItemTest? selectedTest;

  /// Passed to [SongTile.variant].
  final SongTileVariant songTileVariant;

  /// Passed to [SongTile.clickBehavior].
  final SongClickBehavior songClickBehavior;

  /// Callback to be called on item tap.
  final VoidCallback? onItemTap;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// See [ScrollView.physics].
  final ScrollPhysics physics;

  /// Whether the scrollbar is interactive.
  final bool interactiveScrollbar;

  /// Whether to always show the scrollbar.
  final bool alwaysShowScrollbar;

  /// Whether to draw a label when scrollbar is dragged.
  final bool showScrollbarLabel;

  @override
  Widget build(BuildContext context) {
    final localController = controller ?? ScrollController();
    return AppScrollbar.forContent<T>(
      list: list,
      controller: localController,
      showLabel: showScrollbarLabel,
      interactive: interactiveScrollbar,
      isAlwaysShown: alwaysShowScrollbar,
      child: CustomScrollView(
        controller: localController,
        physics: physics,
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: sliver<T>(
              contentType: contentType,
              list: list,
              itemBuilder: itemBuilder,
              selectionController: selectionController,
              leading: leading,
              currentTest: currentTest,
              selectedTest: selectedTest,
              songTileVariant: songTileVariant,
              songClickBehavior: songClickBehavior,
              onItemTap: onItemTap,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a sliver list of content.
  ///
  /// There will be no scrollbar, since scrollbar is applied to [ScrollView],
  /// not to slivers.
  ///
  /// Padding is also removed, since it's possible to just wrap it with [SliverPadding].
  @factory
  static MultiSliver sliver<T extends Content>({
    Key? key,
    Type? contentType,
    required List<T> list,
    _ItemBuilder? itemBuilder,
    ContentSelectionController<SelectionEntry>? selectionController,
    Widget? leading,
    _ItemTest? currentTest,
    _ItemTest? selectedTest,
    SongTileVariant songTileVariant = SongTileVariant.albumArt,
    SongClickBehavior songClickBehavior = SongClickBehavior.play,
    VoidCallback? onItemTap,
  }) {
    final selectable = selectionController != null;
    return MultiSliver(
      children: [
        if (leading != null)
          leading,
        contentPick<T, Widget Function()>(
          contentType: contentType,
          song: () => SliverFixedExtentList(
            itemExtent: kSongTileHeight,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = list[index] as Song;
                Widget child;
                if (selectable) {
                  child = SongTile.selectable(
                    index: index,
                    song: item,
                    selectionController: selectionController!,
                    clickBehavior: songClickBehavior,
                    variant: songTileVariant,
                    current: currentTest?.call(index),
                    selected: selectedTest != null
                      ? selectedTest(index)
                      : selectionController.data.contains(SelectionEntry<Song>(
                          data: item,
                          index: index,
                        )),
                    onTap: onItemTap,
                  );
                } else {
                  child = SongTile(
                    song: item,
                    current: currentTest?.call(index),
                    clickBehavior: songClickBehavior,
                    variant: songTileVariant,
                    onTap: onItemTap,
                  );
                }
                return itemBuilder?.call(context, index, child) ?? child;
              },
              childCount: list.length,
            ),
          ),
          album: () => SliverFixedExtentList(
            itemExtent: kAlbumTileHeight,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = list[index] as Album;
                Widget child;
                if (selectable) {
                  child = AlbumTile.selectable(
                    index: index,
                    album: item,
                    current: currentTest?.call(index),
                    onTap: onItemTap,
                    selectionController: selectionController!,
                    selected: selectedTest != null
                      ? selectedTest(index)
                      : selectionController.data.contains(SelectionEntry<Album>(
                          data: item,
                          index: index,
                        )),
                  );
                } else {
                  child = AlbumTile(
                    album: item,
                    onTap: onItemTap,
                    current: currentTest?.call(index),
                  );
                }
                return itemBuilder?.call(context, index, child) ?? child;
              },
              childCount: list.length,
            ),
          ),
        )(),
      ],
    );
  }
}
