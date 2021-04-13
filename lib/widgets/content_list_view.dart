/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';

/// Renders a list of content.
///
/// Picks some value based on the provided `T` type of [Content].
///
/// Instead of `T`, you can explicitly specify [contentType].
class ContentListView<T extends Content> extends StatelessWidget {
  const ContentListView({
    Key key,
    this.contentType,
    @required this.list,
    this.controller,
    this.selectionController,
    this.leading,
    this.currentTest,
    this.songTileVariant = SongTileVariant.albumArt,
    this.songClickBehavior = SongClickBehavior.play,
    this.onItemTap,
    this.interactiveScrollbar = true,
    this.padding = EdgeInsets.zero,
    this.physics = const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
    this.showScrollbarLabel = false,
  }) : super(key: key);

  /// An explicit content type.
  final Type contentType;

  /// Content list.
  final List<Content> list;
  
  /// Viewport scroll controller.
  final ScrollController controller;

  /// If specified, list will be built as [SongTile.selectable],
  /// otherwise [SongTile] is used (in case if content is [Song]).
  final SelectionController<SelectionEntry<T>> selectionController;

  /// A widget to build before all items.
  final Widget leading;

  /// Passed to [SongTile.currentTest] (in case if content is [Song]).
  ///
  /// The is [index] is index of the song.
  final bool Function(int index) currentTest;

  /// Passed to [SongTile.variant].
  final SongTileVariant songTileVariant;

  /// Passed to [SongTile.clickBehavior].
  final SongClickBehavior songClickBehavior;

  /// Callback to be called on item tap.
  final VoidCallback onItemTap;

  /// Whether the scrollbar is interactive.
  final bool interactiveScrollbar;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// See [ScrollView.physics].
  final ScrollPhysics physics;

  /// Whether to draw a label when scrollbar is dragged.
  final bool showScrollbarLabel;

  @override
  Widget build(BuildContext context) {
    final selectable = selectionController != null;
    final localController = controller ?? ScrollController();
    return Theme(
      data: ThemeControl.theme.copyWith(
        highlightColor: ThemeControl.isDark
          ? const Color(0x40CCCCCC)
          : const Color(0x66BCBCBC),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ContentScrollbar<T>(
          labelBuilder: !showScrollbarLabel
            ? null
            : (context) {
              final item = list[
                (localController.position.pixels / kSongTileHeight - 1)
                .clamp(0.0, list.length - 1).round()
              ];
              return NFScrollLabel(
                text: contentPick<T, String Function()>(
                  song: () => (item as Song).title[0].toUpperCase(),
                  album: () => (item as Album).album[0].toUpperCase(),
                )(),
              );
            },
          interactive: interactiveScrollbar,
          controller: localController,
          child: Theme(
            data: ThemeControl.theme.copyWith(
              highlightColor: Colors.transparent,
            ),
            child: CustomScrollView(
              controller: localController,
              physics: physics,
              slivers: <Widget>[
                SliverPadding(
                  padding: padding,
                  sliver: MultiSliver(
                    children: [
                      if (leading != null)
                        leading,
                      contentPick<T, Widget Function()>(
                        contentType: contentType,
                        song: () => SliverFixedExtentList(
                          itemExtent: kSongTileHeight,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = list[index];
                              final localCurrentTest = currentTest != null
                                ? () => currentTest(index)
                                : null;
                              if (selectable) {
                                return SongTile.selectable(
                                  index: index,
                                  song: item,
                                  selectionController: selectionController,
                                  clickBehavior: songClickBehavior,
                                  variant: songTileVariant,
                                  currentTest: localCurrentTest,
                                  selected: selectionController.data.contains(SelectionEntry<Song>(
                                    data: item,
                                    index: index,
                                  )),
                                  onTap: onItemTap,
                                );
                              }
                              return SongTile(
                                song: item,
                                currentTest: localCurrentTest,
                                clickBehavior: songClickBehavior,
                                variant: songTileVariant,
                                onTap: onItemTap,
                              );
                            },
                            childCount: list.length,
                          ),
                        ),
                        album: () => SliverFixedExtentList(
                          itemExtent: kAlbumTileHeight,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = list[index];
                              final localCurrentTest = currentTest != null
                                ? () => currentTest(index)
                                : null;
                              if (selectable) {
                                return AlbumTile.selectable(
                                  index: index,
                                  album: item,
                                  currentTest: localCurrentTest,
                                  onTap: onItemTap,
                                  selected: selectionController.data.contains(SelectionEntry<Album>(
                                    data: item,
                                    index: index,
                                  )),
                                  selectionController: selectionController,
                                );
                              }
                              return AlbumTile(
                                album: item,
                                onTap: onItemTap,
                                currentTest: localCurrentTest,
                              );
                            },
                            childCount: list.length,
                          ),
                        ),
                      )(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
