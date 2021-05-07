/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class ArtistRoute extends StatefulWidget {
  ArtistRoute({Key? key, required this.artist}) : super(key: key);

  final Artist artist;

  @override
  _ArtistRouteState createState() => _ArtistRouteState();
}

class _ArtistRouteState extends State<ArtistRoute> with SingleTickerProviderStateMixin, SelectionHandler {
  final ScrollController scrollController = ScrollController();
  late AnimationController appBarController;
  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonAnimation;
  late ContentSelectionController selectionController;
  late List<Song> songs;
  late List<Album> albums;

  static const _appBarHeight = NFConstants.toolbarHeight - 8.0 + AppBarBorder.height;

  static const _buttonSectionButtonHeight = 38.0;
  static const _buttonSectionBottomPadding = 12.0;
  static const _buttonSectionHeight = _buttonSectionButtonHeight + _buttonSectionBottomPadding;

  static const _albumsSectionHeight = 280.0;

  /// Amount of pixels user always can scroll.
  double get _alwaysCanScrollExtent => (_artScrollExtent + _buttonSectionHeight).ceilToDouble();

  /// Amount of pixels after art will be fully hidden and appbar will have background color
  /// instead of being transparent.
  double get _artScrollExtent => mediaQuery.size.width - _fullAppBarHeight;

  /// Full size of app bar.
  double get _fullAppBarHeight => _appBarHeight + mediaQuery.padding.top;

  /// Whether the title is visible.
  bool get _appBarTitleVisible => 1.0 - appBarController.value > 0.85;

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
    backButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    backButtonAnimation = CurvedAnimation(
      parent: backButtonAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    scrollController.addListener(_handleScroll);
    selectionController = ContentSelectionController.forContent(
      AppRouter.instance.navigatorKey.currentState!,
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
    backButtonAnimationController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / _artScrollExtent;
    if (1.0 - appBarController.value > 0.5) {
      backButtonAnimationController.forward();
    } else {
      backButtonAnimationController.reverse();
    }
  }

  Widget _buildInfo() {
    final l10n = getl10n(context);
    final theme = ThemeControl.theme;
    final artSize = mediaQuery.size.width;
    final totalDuration = Duration(milliseconds: songs.fold(0, (prev, el) => prev + el.duration));
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;
    final buffer = StringBuffer();
    if (hours > 0) {
      if (hours.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(hours);
      buffer.write(':');
    }
    if (minutes > 0) {
      if (minutes.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(minutes);
      buffer.write(':');
    }
    if (seconds > 0) {
      if (seconds.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(seconds);
    }
    final summary = ContentUtils.joinDot([
      l10n.contentsPluralWithCount<Song>(songs.length),
      l10n.contentsPluralWithCount<Album>(albums.length),
      buffer,
    ]);
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
                    size: artSize,
                    borderRadius: 0.0,
                    source: ContentArtSource.artist(widget.artist),
                  ),
                  Positioned.fill(
                    top: artSize / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, theme.colorScheme.background],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      ),
                    ),
                  ),
                  Positioned.fill(
                    bottom: 22.0,
                    left: 13.0,
                    right: 13.0,
                    child: Align(
                      alignment: Alignment.bottomCenter, 
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ContentUtils.localizedArtist(widget.artist.artist, l10n),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                              color: Constants.Theme.contrast.auto,
                              fontSize: 36.0,
                            ),
                          ),
                          const SizedBox(height: 7.0),
                          Text(
                            summary,
                            style: TextStyle(
                              fontSize: 16.0,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              // color: theme.colorScheme.onSurface,
                              color: Constants.Theme.contrast.auto,
                            ),
                          ),
                        ],
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
          padding: const EdgeInsets.only(
            bottom: _buttonSectionBottomPadding,
            left: 13.0,
            right: 13.0,
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
                      // todo: this
                      ContentControl.setQueue(
                        // queue: widget.queue,
                        type: QueueType.arbitrary,
                        shuffleFrom: songs,
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
                        shuffled: false,
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
          /// The height to add at the end of the scroll view to make the top info part of the route
          /// always be fully scrollable, even if there's not enough content for that.
          var additionalHeight = constraints.maxHeight -
            _fullAppBarHeight -
            kSongTileHeight * math.min(songs.length, 5) -
            48.0;

          if (albums.isNotEmpty) {
            additionalHeight -= _albumsSectionHeight + 48.0;
          }

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
                              onHeaderTap: selectionController.inSelection || songs.length <= 5 ? null : () {
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
                                onHeaderTap: selectionController.inSelection ? null : () {
                                  Navigator.of(context).push(StackFadeRouteTransition(
                                    child: _ContentListRoute<Album>(list: albums),
                                    transitionSettings: AppRouter.instance.transitionSettings.greyDismissible,
                                  ));
                                },
                                child: SizedBox(
                                  height: _albumsSectionHeight,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: albums.length,
                                    itemBuilder: (context, index) {
                                      return PersistentQueueTile<Album>.selectable(
                                        queue: albums[index],
                                        index: index,
                                        selected: selectionController.data
                                          .firstWhereOrNull((el) => el.data == albums[index]) != null,
                                        selectionController: selectionController,
                                        grid: true,
                                        gridShowYear: true,
                                      );
                                    },
                                    separatorBuilder: (BuildContext context, int index) { 
                                      return const SizedBox(width: 16.0);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        
                        if (additionalHeight > 0)
                          SliverToBoxAdapter(
                            child: Container(height: additionalHeight),
                          ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    bottom: null,
                    child: AnimatedBuilder(
                      animation: appBarController,
                      child: AnimatedBuilder(
                        animation: backButtonAnimationController,
                        builder: (context, child) {
                          final colorAnimation = ColorTween(
                            begin: Colors.white,
                            end: theme.iconTheme.color,
                          ).animate(backButtonAnimation);

                          final splashColorAnimation = ColorTween(
                            begin: Constants.Theme.glowSplashColor.auto,
                            end: theme.splashColor,
                          ).animate(backButtonAnimation);

                          return NFIconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: colorAnimation.value,
                            splashColor: splashColorAnimation.value,
                            onPressed: () {
                              selectionController.close();
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                      builder: (context, child) => SizedBox(
                        height: _fullAppBarHeight,
                        child: AppBar(
                          elevation: 0.0,
                          automaticallyImplyLeading: false,
                          leading: child,
                          titleSpacing: 0.0,
                          backgroundColor: appBarController.isDismissed
                              ? theme.colorScheme.background
                              : theme.colorScheme.background.withOpacity(0.0),
                          title: AnimatedOpacity(
                            opacity: _appBarTitleVisible
                              ? 1.0
                              : 0.0,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              ContentUtils.localizedArtist(widget.artist.artist, l10n),
                            ),
                          ),
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(AppBarBorder.height),
                            child: scrollController.offset <= _artScrollExtent
                              ? const SizedBox(height: 1)
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
      body: ContentSelectionControllerCreator<T>(
        builder: (context, selectionController, child) => ContentListView<T>(
          list: list,
          selectionController: selectionController,
        ),
      ),
    );
  }
}