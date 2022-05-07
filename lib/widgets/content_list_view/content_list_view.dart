export 'add_to_selection_button.dart';
export 'artist_tile.dart';
export 'content_tile.dart';
export 'in_list_action.dart';
export 'list_header.dart';
export 'persistent_queue_tile.dart';
export 'song_tile.dart';

import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';

/// Signature used for [ContentListView.currentTest], [ContentListView.selected] and
/// other similar callbacks.
///
/// The argument [index] is index of the item.
typedef _ItemTest = bool Function(int index);

/// Signature used for [ContentListView.backgroundColorBuilder].
///
/// The argument [index] is index of the item.
typedef _ColorBuilder = Color Function(int index);

/// Signature used for [ContentListView.itemBuilder].
///
/// The [item] is the prebuilt item tile widget.
typedef _ItemBuilder = Widget Function(BuildContext context, int index, Widget item);

/// Renders a list of content.
///
/// Picks some value based on the provided `T` type of [Content].
class ContentListView<T extends Content> extends StatelessWidget {
  /// Creates a content list with automatically applied draggable scrollbar.
  const ContentListView({
    Key? key,
    this.contentType,
    required this.list,
    this.itemBuilder,
    this.itemTrailingBuilder,
    this.controller,
    this.selectionController,
    this.leading,
    this.currentTest,
    this.selectedTest,
    this.longPressSelectionGestureEnabledTest,
    this.handleTapInSelectionTest,
    this.onItemTap,
    this.backgroundColorBuilder,
    this.enableDefaultOnTap = true,
    this.songTileVariant = kSongTileVariant,
    this.songTileClickBehavior = kSongTileClickBehavior,
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

  /// Builds an item trailing.
  final IndexedWidgetBuilder? itemTrailingBuilder;

  /// Viewport scroll controller.
  final ScrollController? controller;

  /// If specified, list will be built as [ContentTile.selectable],
  /// otherwise [ContentTile] is used.
  final ContentSelectionController? selectionController;

  /// A widget to build before all items.
  final Widget? leading;

  /// Returned value is passed to [ContentTile.current].
  final _ItemTest? currentTest;

  /// Returned value is passed to [ContentTile.selected].
  final _ItemTest? selectedTest;

  /// Returned value is passed to [ContentTile.longPressSelectionGestureEnabled].
  final _ItemTest? longPressSelectionGestureEnabledTest;

  /// Returned value is passed to [ContentTile.handleTapInSelection].
  final _ItemTest? handleTapInSelectionTest;

  /// Callback to be called on item tap.
  final ValueSetter<int>? onItemTap;

  /// Builds a background color for an item.
  final _ColorBuilder? backgroundColorBuilder;

  /// Passed to [Song.enableDefaultOnTap].
  final bool enableDefaultOnTap;

  /// Passed to [SongTile.variant].
  final SongTileVariant songTileVariant;

  /// Passed to [SongTile.clickBehavior].
  final SongTileClickBehavior songTileClickBehavior;

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
      contentType: contentType,
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
              itemTrailingBuilder: itemTrailingBuilder,
              selectionController: selectionController,
              leading: leading,
              currentTest: currentTest,
              selectedTest: selectedTest,
              longPressSelectionGestureEnabledTest: longPressSelectionGestureEnabledTest,
              handleTapInSelectionTest: handleTapInSelectionTest,
              songTileVariant: songTileVariant,
              songTileClickBehavior: songTileClickBehavior,
              onItemTap: onItemTap,
              backgroundColorBuilder: backgroundColorBuilder,
              enableDefaultOnTap: enableDefaultOnTap,
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
  /// 
  /// See also:
  ///  * [reorderableSliver] which creates a reorderable sliver
  @factory
  static MultiSliver sliver<T extends Content>({
    Key? key,
    Type? contentType,
    required List<T> list,
    _ItemBuilder? itemBuilder,
    IndexedWidgetBuilder? itemTrailingBuilder,
    ContentSelectionController? selectionController,
    Widget? leading,
    _ItemTest? currentTest,
    _ItemTest? selectedTest,
    _ItemTest? longPressSelectionGestureEnabledTest,
    _ItemTest? handleTapInSelectionTest,
    SongTileVariant songTileVariant = kSongTileVariant,
    SongTileClickBehavior songTileClickBehavior = kSongTileClickBehavior,
    ValueSetter<int>? onItemTap,
    _ColorBuilder? backgroundColorBuilder,
    bool enableDefaultOnTap = true,
  }) {
    return MultiSliver(
      children: [
        if (leading != null)
          leading,
        SliverFixedExtentList(
          itemExtent: ContentTile.getHeight<T>(contentType),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = list[index];
              final child = ContentTile<T>(
                contentType: contentType,
                content: item,
                selectionIndex: index,
                selected: selectedTest != null
                  ? selectedTest(index)
                  : selectionController?.data.contains(SelectionEntry<T>.fromContent(
                      content: item,
                      index: index,
                      context: context,
                    ))
                  ?? false,
                longPressSelectionGestureEnabled: longPressSelectionGestureEnabledTest?.call(index) ?? true,
                handleTapInSelection: handleTapInSelectionTest?.call(index) ?? true,
                selectionController: selectionController,
                trailing: itemTrailingBuilder?.call(context, index),
                current: currentTest?.call(index),
                onTap: onItemTap == null ? null : () => onItemTap(index),
                backgroundColor: backgroundColorBuilder == null ? Colors.transparent : backgroundColorBuilder(index),
                enableDefaultOnTap: enableDefaultOnTap,
                songTileVariant: songTileVariant,
                songTileClickBehavior: songTileClickBehavior,
              );
              return itemBuilder?.call(context, index, child) ?? child;
            },
            childCount: list.length,
          ),
        ),
      ],
    );
  }

  /// Returns a sliver reorderable list of content.
  ///
  /// There will be no scrollbar, since scrollbar is applied to [ScrollView],
  /// not to slivers.
  ///
  /// Padding is also removed, since it's possible to just wrap it with [SliverPadding].
  /// 
  /// See also:
  ///  * [sliver] which creates a not reorderable sliver
  @factory
  static MultiSliver reorderableSliver<T extends Content>({
    Key? key,
    Type? contentType,
    required List<T> list,
    required ReorderCallback onReorder,
    bool reorderingEnabled = true,
    _ItemBuilder? itemBuilder,
    IndexedWidgetBuilder? itemTrailingBuilder,
    ContentSelectionController? selectionController,
    Widget? leading,
    _ItemTest? currentTest,
    _ItemTest? selectedTest,
    _ItemTest? longPressSelectionGestureEnabledTest,
    _ItemTest? handleTapInSelectionTest,
    SongTileVariant songTileVariant = kSongTileVariant,
    SongTileClickBehavior songTileClickBehavior = kSongTileClickBehavior,
    ValueSetter<int>? onItemTap,
    _ColorBuilder? backgroundColorBuilder,
    bool enableDefaultOnTap = true,
  }) {
    return MultiSliver(
      children: [
        if (leading != null)
          leading,
        SliverReorderableList(
          // TODO: itemExtent is broken https://github.com/flutter/flutter/issues/84901
          // itemExtent: ContentTile.getHeight<T>(contentType),
          itemCount: list.length,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final item = list[index];
            final child = ReorderableDelayedDragStartListener(
              key: ValueKey(item.id),
              enabled: reorderingEnabled,
              index: index,
              child: ContentTile<T>(
                contentType: contentType,
                content: item,
                selectionIndex: index,
                selected: selectedTest != null
                  ? selectedTest(index)
                  : selectionController?.data.contains(SelectionEntry<T>.fromContent(
                      content: item,
                      index: index,
                      context: context,
                    ))
                  ?? false,
                longPressSelectionGestureEnabled: longPressSelectionGestureEnabledTest?.call(index)
                  ?? !reorderingEnabled,
                handleTapInSelection: handleTapInSelectionTest?.call(index)
                  ?? !reorderingEnabled,
                selectionController: selectionController,
                current: currentTest?.call(index),
                onTap: onItemTap == null ? null : () => onItemTap(index),
                enableDefaultOnTap: enableDefaultOnTap,
                backgroundColor: backgroundColorBuilder == null
                  ? ThemeControl.instance.theme.colorScheme.background
                  : backgroundColorBuilder(index),
                songTileVariant: songTileVariant,
                songTileClickBehavior: songTileClickBehavior,
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return EmergeAnimation(
                      animation: animation,
                      child: FadeTransition(
                        opacity: CurveTween(
                          curve: const Interval(0.4, 1.0),
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: !reorderingEnabled
                    ? itemTrailingBuilder?.call(context, index) ?? const SizedBox.shrink()
                    : ReorderableDragStartListener(
                        enabled: reorderingEnabled,
                        index: index,
                        child: const Icon(
                          Icons.drag_handle,
                          size: 30.0,
                        ),
                      ),
                ),
              ),
            );
            return itemBuilder?.call(context, index, child) ?? child;
          },
        ),
      ],
    );
  }
}
