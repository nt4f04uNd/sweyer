/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

const Duration kSelectionDuration = Duration(milliseconds: 350);

/// Picks some value based on the provided sort type [T].
V selectionEntryPick<T extends SelectionEntry, V>(
    {@required V song, @required V album}) {
  switch (T) {
    case SongSelectionEntry:
      return song;
    case AlbumSelectionEntry:
      return album;
    default:
      assert(false);
      return null;
  }
}

abstract class SelectionEntry<T> extends Equatable {
  SelectionEntry({this.index, this.data});
  final int index;
  final T data;
  @override
  List<Object> get props => [index];
}

class SongSelectionEntry extends SelectionEntry<Song> {
  SongSelectionEntry({int index, Song song}) : super(index: index, data: song);
  Song get song => data;
}

class AlbumSelectionEntry extends SelectionEntry<Album> {
  AlbumSelectionEntry({int index, Album album})
      : super(index: index, data: album);
  Album get album => data;
}

/// Mixin to easily create a song selection controller.
mixin SongSelectionMixin<T extends StatefulWidget> on State<T> {
  NFSelectionController<SongSelectionEntry> songSelectionController;
  @override
  void initState() {
    super.initState();
    assert(
      this is SingleTickerProviderStateMixin<T> ||
          this is TickerProviderStateMixin<T>,
      'SongSelectionMixin can only be used on ticker providers',
    );
    songSelectionController = NFSelectionController(
      animationController: AnimationController(
        vsync: this as dynamic,
        duration: kSelectionDuration,
      ),
    )
      ..addListener(handleSongSelection)
      ..addStatusListener(handleSongSelectionStatus);
  }

  @override
  void dispose() {
    songSelectionController.dispose();
    super.dispose();
  }

  void handleSongSelection();
  void handleSongSelectionStatus(AnimationStatus status);
}

/// Mixin to easily create an album selection controller.
mixin AlbumSelectionMixin<T extends StatefulWidget> on State<T> {
  NFSelectionController<AlbumSelectionEntry> albumSelectionController;
  @override
  void initState() {
    super.initState();
    assert(
      this is SingleTickerProviderStateMixin<T> ||
          this is TickerProviderStateMixin<T>,
      'AlbumSelectionMixin can only be used on ticker providers',
    );
    albumSelectionController = NFSelectionController(
      animationController: AnimationController(
        vsync: this as dynamic,
        duration: kSelectionDuration,
      ),
    )
      ..addListener(handleAlbumSelection)
      ..addStatusListener(handleAlbumSelectionStatus);
  }

  @override
  void dispose() {
    albumSelectionController.dispose();
    super.dispose();
  }

  void handleAlbumSelection();
  void handleAlbumSelectionStatus(AnimationStatus status);
}
