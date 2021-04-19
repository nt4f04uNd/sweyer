/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';

/// A model for the `albums` table.
/// This table is currently only used for storing the [SongsSort] for songs inside the album.
///
/// Inside the album, we can't have [SongsSortFeature.album].
class SqlAlbum {
  SqlAlbum({
    @required this.id,
    @required this.sort,
  })  : assert(id != null),
        assert(sort.feature != SongSortFeature.album);

  final int id;
  final SongSort sort;
}
