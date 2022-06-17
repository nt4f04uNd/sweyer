import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Generalizes all content tiles into one widget and exposes
/// common properties of all tiles.
class ContentTile<T extends Content> extends StatelessWidget {
  const ContentTile({
    Key? key,
    required this.contentType,
    required this.content,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.horizontalPadding,
    this.backgroundColor = Colors.transparent,
    this.songTileVariant = kSongTileVariant,
    this.songTileClickBehavior = kSongTileClickBehavior,
    this.selectionIndex,
    this.selected = false,
    this.longPressSelectionGestureEnabled = true,
    this.handleTapInSelection = true,
    this.selectionController,
  }) : super(key: key);

  final ContentType<T> contentType;
  final T content;
  final Widget? trailing;
  final bool? current;
  final VoidCallback? onTap;
  final bool enableDefaultOnTap;
  final double? horizontalPadding;
  final Color backgroundColor;
  final SongTileVariant songTileVariant;
  final SongTileClickBehavior songTileClickBehavior;

  final int? selectionIndex;
  final bool selected;
  final bool longPressSelectionGestureEnabled;
  final bool handleTapInSelection;
  final ContentSelectionController? selectionController;

  static double getHeight(ContentType contentType, double textScaleFactor) {
    switch (contentType) {
      case ContentType.song:
        return kSongTileHeight(textScaleFactor);
      case ContentType.album:
        return kPersistentQueueTileHeight;
      case ContentType.playlist:
        return kPersistentQueueTileHeight;
      case ContentType.artist:
        return kArtistTileHeight;
    }
  }

  bool get selectable => selectionController != null;

  Widget forPersistentQueue<Q extends PersistentQueue>() {
    return !selectable
        ? PersistentQueueTile<Q>(
            queue: content as Q,
            onTap: onTap,
            enableDefaultOnTap: enableDefaultOnTap,
            trailing: trailing,
            current: current,
            horizontalPadding: horizontalPadding,
            backgroundColor: backgroundColor,
          )
        : PersistentQueueTile<Q>.selectable(
            queue: content as Q,
            selectionIndex: selectionIndex!,
            selectionController: selectionController!,
            selected: selected,
            longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
            handleTapInSelection: handleTapInSelection,
            trailing: trailing,
            current: current,
            onTap: onTap,
            enableDefaultOnTap: enableDefaultOnTap,
            horizontalPadding: horizontalPadding,
            backgroundColor: backgroundColor,
          );
  }

  @override
  Widget build(BuildContext context) {
    assert(!selectable || selectable && selectionIndex != null, 'If tile is selectable, an `index` must be provided');
    // TODO: Remove ContentType cast, see https://github.com/dart-lang/language/issues/2315
    // ignore: unnecessary_cast
    switch (contentType as ContentType) {
      case ContentType.song:
        return !selectable
            ? SongTile(
                song: content as Song,
                trailing: trailing,
                current: current,
                onTap: onTap,
                enableDefaultOnTap: enableDefaultOnTap,
                horizontalPadding: horizontalPadding ?? kSongTileHorizontalPadding,
                backgroundColor: backgroundColor,
                variant: songTileVariant,
                clickBehavior: songTileClickBehavior,
              )
            : SongTile.selectable(
                song: content as Song,
                selectionIndex: selectionIndex!,
                selectionController: selectionController,
                selected: selected,
                longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
                handleTapInSelection: handleTapInSelection,
                trailing: trailing,
                current: current,
                onTap: onTap,
                enableDefaultOnTap: enableDefaultOnTap,
                horizontalPadding: horizontalPadding ?? kSongTileHorizontalPadding,
                backgroundColor: backgroundColor,
                variant: songTileVariant,
                clickBehavior: songTileClickBehavior,
              );
      case ContentType.album:
        return forPersistentQueue<Album>();
      case ContentType.playlist:
        return forPersistentQueue<Playlist>();
      case ContentType.artist:
        return !selectable
            ? ArtistTile(
                artist: content as Artist,
                trailing: trailing,
                current: current,
                onTap: onTap,
                enableDefaultOnTap: enableDefaultOnTap,
                horizontalPadding: horizontalPadding,
                backgroundColor: backgroundColor,
              )
            : ArtistTile.selectable(
                artist: content as Artist,
                selectionIndex: selectionIndex!,
                selectionController: selectionController,
                selected: selected,
                longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
                handleTapInSelection: handleTapInSelection,
                trailing: trailing,
                current: current,
                onTap: onTap,
                enableDefaultOnTap: enableDefaultOnTap,
                horizontalPadding: horizontalPadding,
                backgroundColor: backgroundColor,
              );
    }
  }
}

/// Common parts of the UI in content tile implementations.
///
/// TODO: comments
mixin ContentTileComponentsMixin<E extends SelectionEntry, W extends SelectableWidget> on SelectableState<E, W> {
  final checkmarkLargeSize = 28.0;

  Widget buildSelectionCheckmark({bool forceLarge = false, bool forSelectionRoute = false}) {
    if (animation.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }
    return SelectionCheckmark(
      ignorePointer: !forSelectionRoute,
      scaleAnimation: !forSelectionRoute,
      size: forceLarge || forSelectionRoute ? checkmarkLargeSize : 21.0,
      animation: animation,
    );
  }

  Widget buildAddToSelection() {
    Widget builder(Widget child, Animation<double> animation) {
      return ScaleTransition(
        scale: animation,
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 8.0),
      child: GestureDetector(
        onTap: () {
          toggleSelection();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AddToSelectionButton.size,
          width: AddToSelectionButton.size,
          child: AnimationSwitcher(
            animation: animation,
            builder1: builder,
            builder2: builder,
            child1: Material(
              color: Colors.transparent,
              child: AddToSelectionButton(
                onPressed: () {
                  toggleSelection();
                },
              ),
            ),
            child2: buildSelectionCheckmark(forSelectionRoute: true),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
