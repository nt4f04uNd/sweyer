import 'package:flutter/cupertino.dart';
import 'package:sweyer/sweyer.dart';

/// Used for selection of [Content].
@immutable
class SelectionEntry<T extends Content> {
  const SelectionEntry({
    required this.data,
    required this.index,
    required this.origin,
  });

  /// Creates a selection entry from a content.
  ///
  /// Default selection entry factory used throughout the app.
  factory SelectionEntry.fromContent({
    required T content,
    required int index,
    required BuildContext context,
  }) {
    switch (content.type) {
      case ContentType.song:
        final song = content as Song;
        return SelectionEntry<Song>(
          data: content,
          index: selectionRouteOf(context) ? ContentControl.instance.state.allSongs.getIndex(song) : index,
          origin: selectionRouteOf(context) && song.origin is DuplicatingSongOriginMixin ? song.origin : null,
        ) as SelectionEntry<T>;
      case ContentType.album:
      case ContentType.playlist:
      case ContentType.artist:
        return SelectionEntry<T>(
          index: index,
          data: content,
          origin: null,
        );
    }
  }

  /// The content data.
  final T data;

  /// Used for comparison and for sorting. When content is being
  /// inserted into queue, it must be sorted by this prior.
  ///
  /// Usually the selection controller is created per one screen with one list.
  /// In this case the index can be taken just as index of item in the list.
  /// Aside from that, for this case when the controller is in selection any
  /// sorting or reordering operations must not happen, otherwise might mix up and
  /// the correct order might be lost.
  ///
  /// But in some cases it's not enough to imply index from the list and we
  /// need to have some source of truth of that index. There might be other
  /// approaches to solve this, but this is the easiest one.
  ///
  /// See also:
  ///  * [SelectableState.selectionRoute] and [SongTile] state for example of custom indexing
  ///  * [ContentUtils.selectionPackAndSort], which is the default way of sorting
  ///    the content for further usage
  final int index;

  /// Might be used to scope the selection to origins.
  ///
  /// See discussion in [SelectableState.selectionRoute] for example.
  final SongOrigin? origin;

  @override
  int get hashCode => Object.hash(data, index, origin);

  @override
  bool operator ==(Object other) {
    // Skip the runtimeType comparison, since I that that entries only compared by
    // actual values, because sometimes generics are missing
    //
    // if (other.runtimeType != runtimeType)
    //   return false;

    return other is SelectionEntry && other.data == data && other.index == index && other.origin == origin;
  }
}
