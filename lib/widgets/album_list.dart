/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sweyer/sweyer.dart';

class AlbumListTab extends StatefulWidget {
  const AlbumListTab({Key key}) : super(key: key);
  @override
  _AlbumListTabState createState() => _AlbumListTabState();
}

class _AlbumListTabState extends State<AlbumListTab>
    with AutomaticKeepAliveClientMixin<AlbumListTab> {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectionController = SelectionControllers.of(context).album;
    final albums = ContentControl.state.albums.values.toList();
    final itemCount = albums.length + 1;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      strokeWidth: 2.5,
      key: _refreshIndicatorKey,
      onRefresh: ContentControl.refetchAlbums,
      notificationPredicate: (notification) {
        // Prevent pull to refresh when scrollbar is dragged.
        return !_scrollbarDragged &&
            selectionController.notInSelection &&
            notification.depth == 0;
      },
      child: JumpingDraggableScrollbar.albums(
        itemCount: itemCount,
        itemScrollController: itemScrollController,
        onDragStart: _handleDragStart,
        onDragEnd: _handleDragEnd,
        labelBuilder: (context, progress, barPadHeight, jumpIndex) {
          return NFScrollLabel(
            text: albums[(jumpIndex - 1).clamp(0.0, albums.length - 1).round()]
                .album[0]
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
                return AlbumSortListHeader(
                  count: itemCount - 1,
                  selectionController: selectionController,
                );
              }
              index--;
              final album = albums[index];
              return AlbumTile.selectable(
                album: album,
                index: index,
                current: album == ContentControl.state.currentSongOrigin ||
                    album == ContentControl.state.queues.persistent,
                selected: selectionController.data.contains(
                  AlbumSelectionEntry(index: index),
                ),
                selectionController: selectionController,
              );
            },
          ),
        ),
      ),
    );
  }
}
