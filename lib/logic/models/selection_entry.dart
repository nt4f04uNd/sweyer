/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:equatable/equatable.dart';
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

  /// The content data.
  final T data;

  /// Used for comparison and for sorting. When content is being
  /// inserted into queue, it must be sorted by this prior.
  ///
  /// Usually the selection controller is created per one screen with one list.
  /// In this case the index can be taken just as index of item in the list.
  /// Aside from that, for this case when the controller is in selection any
  /// sorting or reordering operatins must not happen, otherwise might mixup and
  /// the correct order might be lost.
  ///
  /// But in some cases it's not enough to imply index from the list and we
  /// need to have some source of truth of that index. There might be other
  /// approaches to solve this, but this is the easiest one.
  ///
  /// See also:
  ///  * [SelectableState.selectionRoute] and [SongTile] state for example of custom indexing
  ///  * [ContentUtils.selectionSortAndPack], which is the default way of sorting
  ///    the content for further usage
  final int index;

  /// If song origin is [DuplicatingSongOriginMixin], this will be non-null.
  ///
  /// See discussion in [SelectableState.selectionRoute] for example.
  final SongOrigin? origin;

  @override
  bool operator ==(Object other) {
    // Skip the runtimeType comparison, since I that that entries only compared by
    // actual values, because sometimes generics are missing
    //
    // if (other.runtimeType != runtimeType)
    //   return false;
  
    return other is SelectionEntry 
        && other.data == data
        && other.index == index
        && other.origin == origin;
  }

  @override
  int get hashCode => hashValues(data, index, origin);
}
