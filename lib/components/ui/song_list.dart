/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class SongsListTab extends StatefulWidget {
  SongsListTab({
    Key key,
    @required this.selectionController,
  }) : super(key: key);

  final SelectionController selectionController;

  @override
  _SongsListTabState createState() => _SongsListTabState();
}

class _SongsListTabState extends State<SongsListTab>
    with AutomaticKeepAliveClientMixin<SongsListTab> {
  // This mixin doesn't allow widget to redraw
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<RefreshIndicatorState> _songsRefreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
  }

  /// Performs tracks refetch
  Future<void> _handleRefreshSongs() async {
    await ContentControl.refetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final songs = ContentControl.state.getPlaylist(PlaylistType.global).songs;

    return CustomRefreshIndicator(
      color: Constants.AppTheme.refreshIndicatorArrow.auto(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      key: _songsRefreshIndicatorKey,
      onRefresh: _handleRefreshSongs,
      child: SingleTouchRecognizerWidget(
        child: SMMDefaultDraggableScrollbar(
          controller: _scrollController,
          alwaysVisibleScrollThumb:
              ContentControl.state.currentSortFeature == SortFeature.title,
          labelContentBuilder: ContentControl.state.currentSortFeature !=
                  SortFeature.title
              ? null
              : (offsetY) {
                  int idx = ((offsetY - 32.0) / kSMMSongTileHeight).round();
                  if (idx >= songs.length) {
                    idx = songs.length - 1;
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        // TODO: refactor and move to separate widget
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                        width: 22.0,
                        margin: const EdgeInsets.only(left: 4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          songs[idx].title[0].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16.0,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Text(
                        "  —  ",
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: Text(
                            songs[idx].title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
          child: ListView.builder(
            // physics: const SMMBouncingScrollPhysics(),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: songs.length,
            padding: const EdgeInsets.only(bottom: 34.0, top: 4.0),
            itemBuilder: (context, index) {
              return SelectableSongTile(
                song: songs[index],
                selectionController: widget.selectionController,
                // Specify object key that can be changed to re-render song tile
                key:
                    ValueKey(index + widget.selectionController.switcher.value),
                selected: widget.selectionController.selectionSet
                    .contains(songs[index].id),
                playing: songs[index].id == ContentControl.state.currentSongId,
                onTap: ContentControl.resetPlaylists,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget to render current playlist in player right right tab
///
/// Stateful because I need its state is needed to use global key
class PlayerRoutePlaylist extends StatefulWidget {
  PlayerRoutePlaylist({
    Key key,
  }) : super(key: key);

  @override
  PlayerRoutePlaylistState createState() => PlayerRoutePlaylistState();
}

class PlayerRoutePlaylistState extends State<PlayerRoutePlaylist> {
  final ItemScrollController itemScrollController = ItemScrollController();

  final ScrollController frontScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    int initialScrollIndex;
    final int length = ContentControl.state.currentPlaylist.length;
    final int currentSongIndex = ContentControl.state.currentSongIndex;
    if (length > 11) {
      initialScrollIndex =
          currentSongIndex > length - 6 ? length - 6 : currentSongIndex;
    } else
      initialScrollIndex = 0;

    final songs = ContentControl.state.currentPlaylist.songs;

    return Container(
      child: SingleTouchRecognizerWidget(
        child: SMMScrollbar(
          child: ScrollablePositionedList.builder(
            // physics: const SMMBouncingScrollPhysics(),
            physics: const AlwaysScrollableScrollPhysics(),
            frontScrollController: frontScrollController,
            itemScrollController: itemScrollController,
            itemCount: length,
            // padding: const EdgeInsets.only(bottom: 10, top: 5),
            initialScrollIndex: initialScrollIndex,
            itemBuilder: (context, index) {
              // print("udx $index");
              return SongTile(
                song: songs[index],
                playing: index == currentSongIndex,
                pushToPlayerRouteOnClick: false,
              );
            },
          ),
        ),
      ),
    );
  }
}
