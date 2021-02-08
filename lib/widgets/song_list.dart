/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sweyer/sweyer.dart';

class SongsTab extends StatefulWidget {
  SongsTab({Key key}) : super(key: key);
  @override
  _SongsTabState createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin<SongsTab> {
  // This mixin doesn't allow widget to redraw
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ItemScrollController itemScrollController = ItemScrollController();
  bool _scrollbarDragged = false;

  void _handleDragStart(double progress, double barPadHeight) {
    _scrollbarDragged = true;
  }

  void _handleDragEnd(double progress, double barPadHeight) {
    _scrollbarDragged = false;
  }

  /// Performs tracks refetch
  Future<void> _handleRefreshSongs() async {
    await Future.wait([
      ContentControl.refetchSongs(),
      ContentControl.refetchAlbums(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectionController = SelectionControllers.of(context).song;
    final songs = ContentControl.state.queues.all.songs;
    final itemCount = songs.length + 1;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      strokeWidth: 2.5,
      key: _refreshIndicatorKey,
      onRefresh: _handleRefreshSongs,
      notificationPredicate: (notification) {
        // Prevent pull to refresh when scrollbar is dragged.
        return !_scrollbarDragged &&
            selectionController.notInSelection &&
            notification.depth == 0;
      },
      child: JumpingDraggableScrollbar.songs(
        itemCount: itemCount,
        itemScrollController: itemScrollController,
        onDragStart: _handleDragStart,
        onDragEnd: _handleDragEnd,
        labelBuilder: (context, progress, barPadHeight, jumpIndex) {
          return NFScrollLabel(
            text: songs[(jumpIndex - 1).clamp(0.0, songs.length - 1).round()]
                .title[0]
                .toUpperCase(),
          );
        },
        child: SingleTouchRecognizerWidget(
          child: ScrollablePositionedList.builder(
            itemScrollController: itemScrollController,
            itemCount: itemCount,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SongSortListHeader(
                  count: itemCount - 1,
                  selectionController: selectionController,
                );
              }
              index--;
              final song = songs[index];
              return SongTile.selectable(
                index: index,
                song: song,
                selectionController: selectionController,
                selected: selectionController.data.contains(
                  SongSelectionEntry(index: index),
                ),
                current:
                    song.sourceId == ContentControl.state.currentSong.sourceId,
                onTap: () => ContentControl.setQueue(
                  type: QueueType.all,
                  modified: false,
                  shuffled: false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget to render current queue in player right right tab
///
/// Stateful because I need its state is needed to use global key
class PlayerRouteQueue extends StatefulWidget {
  PlayerRouteQueue({
    Key key,
    @required this.initialAlignment,
    @required this.initialScrollIndex,
    @required this.itemScrollController,
    @required this.selectionController,
  })  : assert(initialAlignment != null),
        assert(initialScrollIndex != null),
        assert(itemScrollController != null),
        assert(selectionController != null),
        super(key: key);
  final double initialAlignment;
  final int initialScrollIndex;
  final ItemScrollController itemScrollController;
  final NFSelectionController<SongSelectionEntry> selectionController;
  @override
  _PlayerRouteQueueState createState() => _PlayerRouteQueueState();
}

class _PlayerRouteQueueState extends State<PlayerRouteQueue> {
  @override
  Widget build(BuildContext context) {
    final songs = ContentControl.state.queues.current.songs;
    final currentSongIndex = ContentControl.state.currentSongIndex;
    return SingleTouchRecognizerWidget(
      child: NFScrollbar(
        child: ScrollablePositionedList.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 4.0),
          itemScrollController: widget.itemScrollController,
          itemCount: songs.length,
          initialScrollIndex: widget.initialScrollIndex,
          initialAlignment: widget.initialAlignment,
          itemBuilder: (context, index) {
            return SongTile(
              song: songs[index],
              variant: ContentControl.state.queues.persistent is Album
                  ? SongTileVariant.number
                  : SongTileVariant.albumArt,
              current: index == currentSongIndex,
              clickBehavior: SongClickBehavior.playPause,
            );

            // TODO: THIS
            //
            // return SongTile.selectable(
            //   song: songs[index],
            //   index: index,
            //   selectionController: widget.selectionController,
            //   variant: ContentControl.state.queues.persistent is Album
            //       ? SongTileVariant.number
            //       : SongTileVariant.albumArt,
            //   selected: widget.selectionController.data.contains(
            //     SongSelectionEntry(index: index),
            //   ),
            //   current: index == currentSongIndex,
            //   clickBehavior: SongClickBehavior.playPause,
            // );
          },
        ),
      ),
    );
  }
}
