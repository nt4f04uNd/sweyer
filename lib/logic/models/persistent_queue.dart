/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';

/// Represents some persistent queue on user device that has 
/// a unique [id].
/// 
/// May be:
/// * album
/// * playlist
/// * favorites
/// * etc.
/// 
/// See also:
/// * [QueueType] which is a type of currently playing queue.
abstract class PersistentQueue extends SongOrigin {
  const PersistentQueue({ required this.id });

  /// A unique ID of this queue.
  @override
  final int id;

  /// Whether the queue can be played.
  bool get playable;

  @override
  List<Object> get props => [id];
}
