/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';

class ArtistRoute extends StatefulWidget {
  ArtistRoute({Key? key, required this.artist}) : super(key: key);

  final Artist artist;

  @override
  _ArtistRouteState createState() => _ArtistRouteState();
}

class _ArtistRouteState extends State<ArtistRoute> with SelectionHandler {
  final ScrollController scrollController = ScrollController();
  late AnimationController appBarController;
  late ContentSelectionController<SelectionEntry<Song>> selectionController;
  late List<Song> songs;
  late List<Album> albums;

  static const _appBarHeight = NFConstants.toolbarHeight - 8.0 + AppBarBorder.height;

  static const _buttonSectionButtonHeight = 38.0;
  static const _buttonSectionBottomPadding = 12.0;
  static const _buttonSectionHeight = _buttonSectionButtonHeight + _buttonSectionBottomPadding;

  /// Amount of pixels user always can scroll.
  double get _alwaysCanScrollExtent => _artScrollExtent + _buttonSectionHeight;

  /// Amount of pixels after art will be fully hidden and appbar will have background color
  /// instead of being transparent.
  double get _artScrollExtent => mediaQuery.size.width - _fullAppBarHeight;

  /// Full size of app bar.
  double get _fullAppBarHeight => _appBarHeight + mediaQuery.padding.top;

  late MediaQueryData mediaQuery;

  @override
  void initState() {
    super.initState();
    songs = widget.artist.songs;
    albums = widget.artist.albums;
    appBarController = AnimationController(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      value: 1.0,
    );
    scrollController.addListener(_handleScroll);
    selectionController = ContentSelectionController.forContent<Song>(
      AppRouter.instance.navigatorKey.currentState!,
      closeButton: true,
      counter: true,
      ignoreWhen: () => playerRouteController.opened,
    ) as ContentSelectionController<SelectionEntry<Song>>
      ..addListener(handleSelection)
      ..addStatusListener(handleSelectionStatus);
  }

  @override
  void dispose() {
    selectionController.dispose();
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / (mediaQuery.size.width - _fullAppBarHeight);
  }

  Widget _buildInfo() {
    return Column(
      children: [
        FadeTransition(
          opacity: appBarController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  ContentArt(
                    highRes: true,
                    size: mediaQuery.size.width,
                    borderRadius: 0.0,
                    source: ContentArtSource.artist(widget.artist),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      ),
                    ),
                  ),
                  Positioned.fill(
                    bottom: 40.0,
                    child: Align(
                      alignment: Alignment.bottomCenter, 
                      child: Text(
                        widget.artist.artist,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          fontSize: 42.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Expanded(
              //   child: Padding(
              //     padding: const EdgeInsets.only(left: 14.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           widget.queue.title,
              //           maxLines: 2,
              //           overflow: TextOverflow.ellipsis,
              //           style: const TextStyle(
              //             fontWeight: FontWeight.w900,
              //             height: 1.1,
              //             fontSize: 24.0,
              //           ),
              //         ),
              //         if (isAlbum)
              //           Padding(
              //             padding: const EdgeInsets.only(
              //               top: 8.0,
              //             ),
              //             child: ArtistWidget(
              //               artist: album.artist,
              //               overflow: TextOverflow.clip,
              //               textStyle: TextStyle(
              //                 fontWeight: FontWeight.w900,
              //                 fontSize: 15.0,
              //                 color: ThemeControl.theme.colorScheme.onBackground,
              //               ),
              //             ),
              //           ),
              //         if (isAlbum)
              //           Text(
              //             '${l10n.album} • ${album.year}',
              //             style: TextStyle(
              //               color: ThemeControl.theme.textTheme.subtitle2!.color,
              //               fontWeight: FontWeight.w900,
              //               fontSize: 14.0,
              //             ),
              //           ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: _buttonSectionBottomPadding),
          child: SizedBox(
            height: _buttonSectionButtonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ShuffleQueueButton(
                    onPressed: () {
                      // todo: this
                      ContentControl.setQueue(
                        // queue: widget.queue,
                        type: QueueType.arbitrary,
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
                      // todo: this
                      ContentControl.setQueue(
                        // queue: widget.queue,
                        type: QueueType.arbitrary,
                        songs: songs,
                      );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;
    final l10n = getl10n(context);
    mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // TODO: add comment how this is working
          final height = constraints.maxHeight -
            _fullAppBarHeight -
            kSongTileHeight * songs.length;

          return ScrollConfiguration(
            behavior: const GlowlessScrollBehavior(),
            child: StreamBuilder(
              stream: ContentControl.state.onSongChange,
              builder: (context, snapshot) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: IgnoreInSelection(
                            controller: selectionController,
                            child: _buildInfo(),
                          ),
                        ),

                      
                        if (songs.isNotEmpty)
                          SliverToBoxAdapter(
                            child: ContentSection<Song>(
                              list: songs,
                              selectionController: selectionController,
                              maxPreviewCount: 5,
                              onHeaderTap: songs.length <= 5 ? null : () {
                                Navigator.of(context).push(StackFadeRouteTransition(
                                  child: _ContentListRoute<Song>(list: songs),
                                  transitionSettings: AppRouter.instance.transitionSettings.greyDismissible,
                                ));
                              },
                              contentTileTapHandler: <T extends Content>(Type t) {
                                ContentControl.setQueue(
                                  // todo: this
                                  type: QueueType.arbitrary,
                                  // queue: widget.queue,
                                  songs: songs,
                                );
                              },
                            ),
                          ),
                        if (albums.isNotEmpty)
                          MultiSliver(
                            children: [
                              ContentSection<Album>.custom(
                                list: albums,
                                onHeaderTap: songs.length <= 5 ? null : () {
                                  Navigator.of(context).push(StackFadeRouteTransition(
                                    child: _ContentListRoute<Song>(list: songs),
                                    transitionSettings: AppRouter.instance.transitionSettings.greyDismissible,
                                  ));
                                },
                                child: SizedBox(
                                  height: 240.0,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: albums.length,
                                    itemBuilder: (context, index) {
                                      return ContentArt(
                                        size: 240.0,
                                        highRes: true,
                                        assetScale: 1.4,
                                        source: ContentArtSource.album(albums[index]),
                                      );
                                    },
                                    separatorBuilder: (BuildContext context, int index) { 
                                      return const SizedBox(width: 16.0);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.0),
                            ],
                          ),
                        
                        SliverToBoxAdapter(
                          child: height <= 0
                            ? const SizedBox.shrink()
                            : Container(height: height),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    bottom: null,
                    child: AnimatedBuilder(
                      animation: appBarController,
                      child: NFBackButton(
                        onPressed: () {
                          selectionController.close();
                          Navigator.of(context).pop();
                        },
                      ),
                      builder: (context, child) => SizedBox(
                        height: _fullAppBarHeight,
                        child:  AppBar(
                          elevation: 0.0,
                          automaticallyImplyLeading: false,
                          leading: child,
                          titleSpacing: 0.0,
                          backgroundColor: appBarController.isDismissed
                              ? theme.colorScheme.background
                              : theme.colorScheme.background.withOpacity(0.0),
                          title: AnimatedOpacity(
                            opacity: 1.0 - appBarController.value > 0.85
                              ? 1.0
                              : 0.0,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 400),
                            child: Text(widget.artist.artist),
                          ),
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(AppBarBorder.height),
                            child: scrollController.offset < _artScrollExtent
                              ? const SizedBox.shrink()
                              : AppBarBorder(
                                  shown: scrollController.offset > _alwaysCanScrollExtent,
                                ),
                          ),
                        ),
                      ),
                    ),
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

class _ContentListRoute<T extends Content> extends StatelessWidget {
  const _ContentListRoute({Key? key, required this.list}) : super(key: key);

  final List<T> list;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contentsPluralWithCount<T>(list.length)),
        leading: const NFBackButton(),
      ),
      body: ContentListView<T>(
        list: list,
      ),
    );
  }
}