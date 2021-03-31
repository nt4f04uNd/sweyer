/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

class AlbumRoute extends StatefulWidget {
  AlbumRoute({Key key, @required this.album})
      : songs = album.songs,
        assert(album != null),
        super(key: key);

  final Album album;
  final List<Song> songs;

  @override
  _AlbumRouteState createState() => _AlbumRouteState();
}

class _AlbumRouteState extends State<AlbumRoute>
    with TickerProviderStateMixin, SongSelectionMixin {
  final ScrollController scrollController = ScrollController();
  AnimationController appBarController;

  static const _appBarHeight = kNFAppBarPreferredSize - 8.0;
  static const _albumArtSize = 130.0;
  static const _albumSectionTopPadding = 10.0;
  static const _albumSectionBottomPadding = 20.0;
  static const _albumSectionHeight = _albumArtSize + _albumSectionTopPadding + _albumSectionBottomPadding;

  @override
  void initState() {
    super.initState();
    appBarController = AnimationController(vsync: this, value: 1.0);
    scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  void handleSongSelection() {
    setState(() {
      /*  update appbar and tiles on selection
      primarily needed to update the selection number in [SelectionAppBar] */
    });
  }

  @override
  void handleSongSelectionStatus(AnimationStatus status) {
    setState(() {/* update appbar and tiles on selection status */});
  }

  void _handleScroll() {
    appBarController.value =
        1.0 - scrollController.offset / _albumSectionHeight;
  }

  Widget _buildAlbumInfo() {
    final l10n = getl10n(context);
    return FadeTransition(
      opacity: appBarController,
      child: Container(
        padding: const EdgeInsets.only(
          top: _albumSectionTopPadding,
          bottom: _albumSectionBottomPadding,
          left: 13.0,
          right: 10.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AlbumArt(
              size: 130.0,
              highRes: true,
              assetScale: 1.4,
              path: widget.album.albumArt,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.album.album,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontSize: 24.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                      ),
                      child: ArtistWidget(
                        artist: widget.album.artist,
                        overflow: TextOverflow.clip,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.0,
                          color: ThemeControl.theme.colorScheme.onBackground,
                        ),
                      ),
                    ),
                    Text(
                      '${l10n.album} • ${widget.album.year}',
                      style: TextStyle(
                        color: ThemeControl.theme.textTheme.subtitle2.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;
    final length = widget.songs.length;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => ScrollConfiguration(
          behavior: const GlowlessScrollBehavior(),
          child: StreamBuilder(
            stream: ContentControl.state.onSongChange,
            builder: (context, snapshot) => CustomScrollView(
              controller: scrollController,
              slivers: [
                AnimatedBuilder(
                  animation: appBarController,
                  child: const NFBackButton(),
                  builder: (context, child) => SliverAppBar(
                    pinned: true,
                    elevation: 0.0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: _appBarHeight,
                    leading: child,
                    titleSpacing: 0.0,
                    backgroundColor: appBarController.isDismissed
                        ? theme.colorScheme.background
                        : theme.colorScheme.background.withOpacity(0.0),
                    title: AnimatedOpacity(
                      opacity: 1.0 - appBarController.value > 0.2 ? 1.0 : 0.0,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 400),
                      child: Text(widget.album.album),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildAlbumInfo()),
                SliverStickyHeader(
                  overlapsContent: false,
                  header: AnimatedBuilder(
                    animation: appBarController,
                    builder: (context, child) => AppBarBorder(
                      shown: scrollController.offset > _albumSectionHeight,
                    ),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == length) {
                          final height = constraints.maxHeight -
                              _appBarHeight -
                              kSongTileHeight * length -
                              AppBarBorder.height -
                              MediaQuery.of(context).padding.top;
                          if (height <= 0) return const SizedBox.shrink();
                          return Container(height: height);
                        }
                        final song = widget.songs[index];
                        return SongTile(
                          song: song,
                          variant: SongTileVariant.number,
                          currentTest: () => ContentControl.state.queues.persistent == widget.album &&
                                             song.sourceId == ContentControl.state.currentSong.sourceId,
                          onTap: () => ContentControl.setQueue(
                            type: QueueType.persistent,
                            persistentQueue: widget.album,
                            songs: widget.songs,
                            modified: false,
                            shuffled: false,
                          ),
                        );

                        // TODO: THIS
                        //
                        // return SongTile.selectable(
                        //   song: song,
                        //   index: index,
                        //   variant: SongTileVariant.number,
                        //   selectionController: songSelectionController,
                        //   selected: songSelectionController.data.contains(
                        //     SongSelectionEntry(index: index),
                        //   ),
                        //   current: ContentControl.state.queues.persistent == widget.album &&
                        //            song.sourceId == ContentControl.state.currentSong.sourceId,
                        //   onTap: () => ContentControl.setQueue(
                        //     type: QueueType.persistent,
                        //     persistentQueue: widget.album,
                        //     songs: widget.songs,
                        //     modified: false,
                        //     shuffled: false,
                        //   ),
                        // );
                      },
                      childCount: length + 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
