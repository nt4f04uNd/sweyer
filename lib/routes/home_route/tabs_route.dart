/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Returns app style used for app bar title.
TextStyle get appBarTitleTextStyle => TextStyle(
  fontWeight: FontWeight.w700,
  color: ThemeControl.theme.textTheme.headline6!.color,
  fontSize: 22.0,
  fontFamily: 'Roboto',
);

/// Needed to change physics of the [TabBarView].
class _TabsScrollPhysics extends AlwaysScrollableScrollPhysics {
  const _TabsScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _TabsScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _TabsScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 80,
    stiffness: 100,
    damping: 1,
  );
}

class TabsRoute extends StatefulWidget {
  const TabsRoute({Key? key}) : super(key: key);

  @override
  TabsRouteState createState() => TabsRouteState();
}

class TabsRouteState extends State<TabsRoute> with TickerProviderStateMixin, SelectionHandlerMixin {
  static const tabBarHeight = 44.0;

  late TabController tabController;

  /// Used in [HomeRouter.drawerCanBeOpened].
  bool tabBarDragged = false;
  static late bool _mainTabsCreated = false;

  @override
  void initState() {
    super.initState();

    assert(() {
      if (!selectionRoute) {
        if (_mainTabsCreated) {
          throw StateError(
            "Several main tabs routes was created twice at the same time, "
            "which is invalid",
          );
        }
        _mainTabsCreated = true;
      }
      return true;
    }());

    initSelectionController(() => ContentSelectionController.create(
      vsync: this,
      context: context,
      ignoreWhen: () => playerRouteController.opened ||
                        HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.tabs),
    ));
  
    tabController = TabController(
      vsync: this,
      length: 4,
    );
  }

  @override
  void dispose() {
    assert(() {
      if (!selectionRoute)
        _mainTabsCreated = false;
      return true;
    }());
    disposeSelectionController();
    tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    final l10n = getl10n(context);
    return [
      _TabCollapse(
        index: 0,
        tabController: tabController,
        icon: const Icon(Song.icon),
        label: l10n.tracks,
      ),
      _TabCollapse(
        index: 1,
        tabController: tabController,
        icon: const Icon(Album.icon),
        label: l10n.albums,
      ),
      _TabCollapse(
        index: 2,
        tabController: tabController,
        icon: const Icon(Playlist.icon, size: 28.0),
        label: l10n.playlists,
      ),
      _TabCollapse(
        index: 3,
        tabController: tabController,
        icon: const Icon(Artist.icon),
        label: l10n.artists,
      ),
    ];
  }

  
  DateTime? _lastBackPressTime;
  Future<bool> _handlePop() async {
    final navigatorKey = AppRouter.instance.navigatorKey;
    final homeNavigatorKey = homeRouter!.navigatorKey;

    if (selectionRoute && homeNavigatorKey.currentState!.canPop()) {
      homeNavigatorKey.currentState!.pop();
      return true;
    }
    if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
      return true;
    }
    if (homeNavigatorKey.currentState != null && homeNavigatorKey.currentState!.canPop()) {
      homeNavigatorKey.currentState!.pop();
      return true;
    }

    final now = DateTime.now();
    // Show toast when user presses back button on main route, that
    // asks from user to press again to confirm that he wants to quit the app
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ShowFunctions.instance.showToast(msg: getl10n(context).pressOnceAgainToExit);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;
    final screenWidth = MediaQuery.of(context).size.width;
    final searchButton = NFIconButton(
      icon: const Icon(Icons.search_rounded),
      onPressed: () {
        ShowFunctions.instance.showSongsSearch(context);
      },
    );

    final appBar = SelectionAppBar(
      titleSpacing: 0.0,
      elevation: 2.0,
      elevationSelection: 2.0,
      selectionController: selectionController,
      toolbarHeight: kToolbarHeight,
      showMenuButton: !selectionRoute,
      leading: selectionRoute
        ? NFBackButton(onPressed: () => AppRouter.instance.navigatorKey.currentState!.pop())
        : const NFBackButton(),
      onMenuPressed: () {
        drawerController.open();
      },
      actions: selectionRoute ? const [] : [searchButton],
      actionsSelection: !selectionRoute
        ? [DeleteSongsAppBarAction<Content>(controller: selectionController)]
        : [searchButton],
      title: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: selectionRoute ? const SizedBox.shrink() : Text(
          Constants.Config.APPLICATION_TITLE,
          style: appBarTitleTextStyle,
        ),
      ),
      titleSelection: selectionRoute
        ? Text(
            homeRouter!.selectionArguments!.title(context),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: SelectionCounter(controller: selectionController),
          ),
    );

    return NFBackButtonListener(
      onBackButtonPressed: _handlePop,
      child: Material(
        color: theme.colorScheme.background,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: Stack(
                  children: [
                    StreamBuilder(
                      stream: ContentControl.state.onSongChange,
                      builder: (context, snapshot) => 
                    StreamBuilder(
                      stream: ContentControl.state.onContentChange,
                      builder: (context, snapshot) => 
                    ScrollConfiguration(
                      behavior: const GlowlessScrollBehavior(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: tabBarHeight),
                        child: TabBarView(
                          controller: tabController,
                          physics: const _TabsScrollPhysics(),
                          children: [
                            _ContentTab<Song>(selectionController: selectionController),
                            _ContentTab<Album>(selectionController: selectionController),
                            _ContentTab<Playlist>(selectionController: selectionController),
                            _ContentTab<Artist>(selectionController: selectionController),
                          ],
                        ),
                      ),
                    ))),
                    Positioned(
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Theme(
                        data: theme.copyWith(
                          splashFactory: NFListTileInkRipple.splashFactory,
                          canvasColor:theme.colorScheme.secondary,
                        ),
                        child: ScrollConfiguration(
                          behavior: const GlowlessScrollBehavior(),
                          child: SizedBox(
                            height: tabBarHeight,
                            width: screenWidth,
                            child: Material(
                              elevation: 4.0,
                              color: theme.colorScheme.background,
                              child: GestureDetector(
                                onPanDown: (_) {
                                  tabBarDragged = true;
                                },
                                onPanCancel: () {
                                  tabBarDragged = false;
                                },
                                onPanEnd: (_) {
                                  tabBarDragged = false;
                                },
                                child: Center(
                                  child: NFTabBar(         
                                    isScrollable: true,
                                    controller: tabController,
                                    indicatorWeight: 5.0,
                                    indicator: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(3.0),
                                        topRight: Radius.circular(3.0),
                                      ),
                                    ),
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    labelColor: theme.textTheme.headline6!.color,
                                    indicatorSize: TabBarIndicatorSize.label,
                                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                                    labelStyle: theme.textTheme.headline6!.copyWith(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    tabs: _buildTabs(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: appBar,
            ),
          ],
        ),
      ),
    );
  }
}


class _ContentTab<T extends Content> extends StatefulWidget {
  _ContentTab({
    Key? key,
    required this.selectionController,
  }) : super(key: key);

  final ContentSelectionController selectionController;

  @override
  _ContentTabState<T> createState() => _ContentTabState();
}

class _ContentTabState<T extends Content> extends State<_ContentTab<T>> with AutomaticKeepAliveClientMixin<_ContentTab<T>>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final key = GlobalKey<RefreshIndicatorState>();

  bool get showLabel {
    final SortFeature feature = ContentControl.state.sorts.getValue<T>().feature;
    return contentPick<T, bool>(
      song: feature == SongSortFeature.title,
      album: feature == AlbumSortFeature.title,
      playlist: feature == PlaylistSortFeature.name,
      artist: feature == ArtistSortFeature.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ThemeControl.theme;
    final list = ContentControl.getContent<T>();
    final showDisabledActions = list.isNotEmpty && list.first is Playlist && (list as List<Playlist>).every((el) => el.songIds.isEmpty);
    final selectionController = widget.selectionController;
    final selectionRoute = selectionRouteOf(context);
    return RefreshIndicator(
      key: key,
      strokeWidth: 2.5,
      color: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
      onRefresh: ContentControl.refetchAll,
      notificationPredicate: (notification) {
        return selectionController.notInSelection &&
               notification.depth == 0;
      },
      child: ContentListView<T>(
        list: list,
        showScrollbarLabel: showLabel,
        selectionController: selectionController,
        onItemTap: contentPick<T, ValueSetter<int>>(
          song: (index) => ContentControl.resetQueue,
          album: (index) {},
          playlist: (index) {},
          artist: (index) {},
        ),
        leading: Column(
          children: [
            if (selectionRoute)
              ContentListHeader<T>.onlyCount(count: list.length)
            else
              ContentListHeader<T>(
                count: list.length,
                selectionController: selectionController,
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: 1.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder:(Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.centerRight,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: list.isEmpty || selectionRoute
                      ? const SizedBox(
                          width: ContentListHeaderAction.size * 2,
                          height: ContentListHeaderAction.size,
                        )
                      : Row(
                          children: [
                            AnimatedContentListHeaderAction(
                              icon: const Icon(Icons.shuffle_rounded),
                              onPressed: showDisabledActions ? null : () {
                                  contentPick<T, VoidCallback>(
                                  song: () {
                                    ContentControl.setQueue(
                                      type: QueueType.allSongs,
                                      modified: false,
                                      shuffled: true,
                                      shuffleFrom: list as List<Song>,
                                    );
                                  },
                                  album: () {
                                    final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Album>);
                                    ContentControl.setQueue(
                                      type: QueueType.allAlbums,
                                      shuffled: true,
                                      songs: shuffleResult.shuffledSongs,
                                      shuffleFrom: shuffleResult.songs,
                                    );
                                  },
                                  playlist: () {
                                    final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Playlist>);
                                    ContentControl.setQueue(
                                      type: QueueType.allPlaylists,
                                      shuffled: true,
                                      songs: shuffleResult.shuffledSongs,
                                      shuffleFrom: shuffleResult.songs,
                                    );
                                  },
                                  artist: () {
                                    final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Artist>);
                                    ContentControl.setQueue(
                                      type: QueueType.allArtists,
                                      shuffled: true,
                                      songs: shuffleResult.shuffledSongs,
                                      shuffleFrom: shuffleResult.songs,
                                    );
                                  },
                                )();
                                MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                                MusicPlayer.instance.play();
                                playerRouteController.open();
                              },
                            ),
                            AnimatedContentListHeaderAction(
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: showDisabledActions ? null : () {
                                contentPick<T, VoidCallback>(
                                  song: () => ContentControl.resetQueue(),
                                  album: () => ContentControl.setQueue(
                                    type: QueueType.allAlbums,
                                    songs: ContentUtils.joinSongOrigins(list as List<Album>),
                                  ),
                                  playlist: () => ContentControl.setQueue(
                                    type: QueueType.allPlaylists,
                                    songs: ContentUtils.joinSongOrigins(list as List<Playlist>),
                                  ),
                                  artist: () => ContentControl.setQueue(
                                    type: QueueType.allArtists,
                                    songs: ContentUtils.joinSongOrigins(list as List<Artist>),
                                  ),
                                )();
                                MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                                MusicPlayer.instance.play();
                                playerRouteController.open();
                              },
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            if (T == Playlist && !selectionRoute)
              const CreatePlaylistInListAction(),
          ],
        ),
      )
    );
  }
}

class _TabCollapse extends StatelessWidget {
  const _TabCollapse({
    Key? key,
    required this.index,
    required this.tabController,
    required this.label,
    required this.icon,
  }) : super(key: key);

  final int index;
  final TabController tabController;
  final String label; 
  final Icon icon; 

  @override
  Widget build(BuildContext context) {
    // TODO: some wierd stuff happening if value is 1.6090780263766646e-7, this suggests some issue in the rendering that would needed to be investigated, reproduced and filed to flutter as issue
    return NFTab(
      child: AnimatedBuilder(
        animation: tabController.animation!,
        child: Text(label),
        builder: (context, child) {
          final tabValue = tabController.animation!.value;
          final indexIsChanging = tabController.indexIsChanging;
          double value = 0.0;
          if (tabValue > index - 1 && tabValue <= index) {
            if (!indexIsChanging || indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
              // Animation for next tab.
              value = 1 + (tabController.animation!.value - index);
            }
          } else if (tabValue <= index + 1 && tabValue > index) {
            if (!indexIsChanging || indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
              // Animation for previous tab.
              value = 1 - (tabController.animation!.value - index);
            }
          }
          value = value.clamp(0.0, 1.0);
          return Row(
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  heightFactor: 1.0 - value,
                  widthFactor: 1.0 - value,
                  child: icon,
                ),
              ),
              // Create a space while animating in-between icon and label, but don't keep it,
              // otherwise symmetry is ruined.
              SizedBox( 
                width: 4 * TweenSequence([
                  TweenSequenceItem(
                    tween: Tween(begin: 0.0, end: 1.0),
                    weight: 1,
                  ),
                  TweenSequenceItem(
                    tween: ConstantTween(1.0),
                    weight: 2,
                  ),
                  TweenSequenceItem(
                    tween: Tween(begin: 1.0, end: 0.0),
                    weight: 1,
                  ),
                ]).transform(value),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
