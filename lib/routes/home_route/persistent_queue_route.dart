/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

class PersistentQueueRoute extends StatefulWidget {
  PersistentQueueRoute({Key? key, required this.queue})
    : super(key: key);

  final PersistentQueue queue;

  @override
  _PersistentQueueRouteState createState() => _PersistentQueueRouteState();
}

class _PersistentQueueRouteState extends State<PersistentQueueRoute> with SelectionHandler {
  final ScrollController scrollController = ScrollController();
  late AnimationController appBarController;
  late ContentSelectionController<SelectionEntry<Song>> selectionController;
  late List<Song> songs;

  static const _appBarHeight = NFConstants.toolbarHeight - 8.0;
  static const _artSize = 130.0;
  static const _infoSectionTopPadding = 10.0;
  static const _infoSectionBottomPadding = 24.0;
  static const _infoSectionHeight = _artSize + _infoSectionTopPadding + _infoSectionBottomPadding;

  static const _buttonSectionButtonHeight = 38.0;
  static const _buttonSectionBottomPadding = 12.0;
  static const _buttonSectionHeight = _buttonSectionButtonHeight + _buttonSectionBottomPadding;

  /// Amount of pixels user always can scroll.
  static const _alwaysCanScrollExtent = _infoSectionHeight + _buttonSectionHeight;

  bool get isAlbum => widget.queue is Album;
  Album get album {
    assert(isAlbum);
    return widget.queue as Album;
  }

  @override
  void initState() {
    super.initState();
    songs = widget.queue.songs;
    appBarController = AnimationController(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      value: 1.0,
    );
    scrollController.addListener(_handleScroll);
    selectionController = ContentSelectionController.create<Song>(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      context: context,
      closeButton: true,
      counter: true,
      ignoreWhen: () => playerRouteController.opened,
    )
      ..addListener(handleSelection);
  }

  @override
  void dispose() {
    selectionController.dispose();
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / _infoSectionHeight;
  }

  Widget _buildInfo() {
    final l10n = getl10n(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 13.0,
        right: 10.0,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: appBarController,
            child: Container(
              padding: const EdgeInsets.only(
                top: _infoSectionTopPadding,
                bottom: _infoSectionBottomPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ContentArt(
                    size: 130.0,
                    highRes: true,
                    assetScale: 1.5,
                    source: ContentArtSource.persistentQueue(widget.queue),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.queue.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              fontSize: 24.0,
                            ),
                          ),
                          if (isAlbum)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                              ),
                              child: ArtistWidget(
                                artist: album.artist,
                                overflow: TextOverflow.clip,
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.0,
                                  color: ThemeControl.theme.colorScheme.onBackground,
                                ),
                              ),
                            ),
                          if (isAlbum)
                            Text(
                              ContentUtils.appendYearWithDot(l10n.album, album.year),
                              style: TextStyle(
                                color: ThemeControl.theme.textTheme.subtitle2!.color,
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
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: _buttonSectionBottomPadding,
              // Compensate the padding difference up the tree
              right: 3.0
            ),
            child: SizedBox(
              height: _buttonSectionButtonHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ShuffleQueueButton(
                      onPressed: () {
                         ContentControl.setOriginQueue(
                          origin: widget.queue,
                          songs: songs,
                          shuffled: true,
                        );
                        MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                        MusicPlayer.instance.play();
                        playerRouteController.open();
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: PlayQueueButton(
                      onPressed: () {
                        ContentControl.setOriginQueue(origin: widget.queue, songs: songs);
                        MusicPlayer.instance.setSong(songs[0]);
                        MusicPlayer.instance.play();
                        playerRouteController.open();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          /// The height to add at the end of the scroll view to make the top info part of the route
          /// always be fully scrollable, even if there's not enough items for that.
          final additionalHeight = constraints.maxHeight -
            _appBarHeight -
            AppBarBorder.height -
            MediaQuery.of(context).padding.top -
            kSongTileHeight * songs.length;

          return ScrollConfiguration(
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
                        opacity: 1.0 - appBarController.value > 0.35
                          ? 1.0
                          : 0.0,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 400),
                        child: Text(widget.queue.title),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: IgnoreInSelection(
                      controller: selectionController,
                      child: _buildInfo()
                    ),
                  ),

                  SliverStickyHeader(
                    overlapsContent: false,
                    header: AnimatedBuilder(
                      animation: appBarController,
                      builder: (context, child) => AppBarBorder(
                        shown: scrollController.offset > _alwaysCanScrollExtent,
                      ),
                    ),
                    sliver: ContentListView.sliver<Song>(
                      list: songs,
                      selectionController: selectionController,
                      currentTest: (index) => ContentUtils.originIsCurrent(widget.queue) &&
                                              songs[index].sourceId == ContentControl.state.currentSong.sourceId,
                      songTileVariant: SongTileVariant.number,
                      onItemTap: () => ContentControl.setOriginQueue(
                        origin: widget.queue,
                        songs: songs,
                      ),
                    ),
                  ),
                  
                  if (additionalHeight > 0) 
                    SliverToBoxAdapter(
                      child: Container(height: additionalHeight),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
