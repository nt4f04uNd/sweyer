import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

/// Returns app style used for app bar title.
TextStyle get appBarTitleTextStyle => TextStyle(
      fontWeight: FontWeight.w700,
      color: ThemeControl.instance.theme.textTheme.headline6!.color,
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
  static bool _mainTabsCreated = false;

  ContentType indexToContentType(int index) {
    return ContentType.values[index];
  }

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
          ignoreWhen: () =>
              playerRouteController.opened || HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.tabs),
        ));

    tabController = TabController(
      vsync: this,
      length: 4,
    );
    _updatePrimaryContentType();
    tabController.addListener(() {
      _updatePrimaryContentType();
    });
  }

  @override
  void dispose() {
    assert(() {
      if (!selectionRoute) {
        _mainTabsCreated = false;
      }
      return true;
    }());
    disposeSelectionController();
    tabController.dispose();
    super.dispose();
  }

  void _updatePrimaryContentType() {
    selectionController.primaryContentType = indexToContentType(tabController.index);
  }

  List<Widget> _buildTabs() {
    final l10n = getl10n(context);
    return [
      TabCollapse(
        index: 0,
        tabController: tabController,
        icon: Icon(ContentType.song.icon),
        label: l10n.tracks,
      ),
      TabCollapse(
        index: 1,
        tabController: tabController,
        icon: Icon(ContentType.album.icon),
        label: l10n.albums,
      ),
      TabCollapse(
        index: 2,
        tabController: tabController,
        icon: Icon(ContentType.playlist.icon, size: 28.0),
        label: l10n.playlists,
      ),
      TabCollapse(
        index: 3,
        tabController: tabController,
        icon: Icon(ContentType.artist.icon),
        label: l10n.artists,
      ),
    ];
  }

  /// Callback that must be called before any pop.
  ///
  /// For example we want that player route would be closed first.
  bool _handleNecessaryPop() {
    final selectionController = ContentControl.instance.selectionNotifier.value;
    if (playerRouteController.opened) {
      if (selectionController != null) {
        selectionController.close();
        return true;
      }
      playerRouteController.close();
      return true;
    } else if (drawerController.opened) {
      drawerController.close();
      return true;
      // Don't try to close the alwaysInSelection controller, since it is not possible
    } else if (selectionController != null && !selectionController.alwaysInSelection) {
      selectionController.close();
      return true;
    }
    return false;
  }

  Future<bool> _handlePop() async {
    final navigatorKey = AppRouter.instance.navigatorKey;
    final homeNavigatorKey = homeRouter!.navigatorKey;
    if (_handleNecessaryPop()) {
      return true;
    }
    // When in selection route, the home router should be popped first,
    // opposed to the normal situation, where the main app navigator comes first
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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.instance.theme;
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
      actions: selectionRoute
          ? const []
          : [
              const _ShowOnlyFavoritesButton(),
              searchButton,
            ],
      actionsSelection: selectionRoute
          ? [
              SelectAllSelectionAction(
                controller: selectionController,
                entryFactory: (Content content, index) => SelectionEntry.fromContent(
                  content: content,
                  index: index,
                  context: context,
                ),
                getAll: () => ContentControl.instance.getContent(
                  selectionController.primaryContentType!,
                  filterFavorite: FavoritesControl.instance.showOnlyFavorites,
                ),
              ),
              const _ShowOnlyFavoritesButton(),
              searchButton,
            ]
          : [
              DeleteSongsAppBarAction<Content>(
                controller: selectionController,
              ),
              SelectAllSelectionAction(
                controller: selectionController,
                entryFactory: (Content content, index) => SelectionEntry.fromContent(
                  content: content,
                  index: index,
                  context: context,
                ),
                getAll: () => ContentControl.instance.getContent(
                  selectionController.primaryContentType!,
                  filterFavorite: FavoritesControl.instance.showOnlyFavorites,
                ),
              ),
            ],
      title: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: selectionRoute
            ? const SizedBox.shrink()
            : Text(
                constants.Config.applicationTitle,
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

    return BackButtonListener(
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
                        stream: PlaybackControl.instance.onSongChange,
                        builder: (context, snapshot) => StreamBuilder(
                            stream: ContentControl.instance.onContentChange,
                            builder: (context, snapshot) => ScrollConfiguration(
                                  behavior: const GlowlessScrollBehavior(),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: tabBarHeight),
                                    child: TabBarView(
                                      controller: tabController,
                                      physics: const _TabsScrollPhysics(),
                                      children: [
                                        for (final contentType in ContentType.values)
                                          _ContentTab(
                                            contentType: contentType,
                                            selectionController: selectionController,
                                          ),
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
                          canvasColor: theme.colorScheme.secondary,
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

class _ShowOnlyFavoritesButton extends StatelessWidget {
  const _ShowOnlyFavoritesButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: FavoritesControl.instance.onShowOnlyFavorites,
      builder: (context, onShowOnlyFavorites, child) => HeartButton(
        active: onShowOnlyFavorites,
        onPressed: FavoritesControl.instance.toggleShowOnlyFavorites,
      ),
    );
  }
}

class _ContentTab extends StatefulWidget {
  const _ContentTab({
    Key? key,
    required this.contentType,
    required this.selectionController,
  }) : super(key: key);

  final ContentType contentType;
  final ContentSelectionController selectionController;

  @override
  _ContentTabState createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab>
    with AutomaticKeepAliveClientMixin<_ContentTab>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  bool get showLabel {
    final contentType = widget.contentType;
    final SortFeature feature = ContentControl.instance.state.sorts.get(contentType).feature;
    switch (contentType) {
      case ContentType.song:
        return feature == SongSortFeature.title;
      case ContentType.album:
        return feature == AlbumSortFeature.title;
      case ContentType.playlist:
        return feature == PlaylistSortFeature.name;
      case ContentType.artist:
        return feature == ArtistSortFeature.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = getl10n(context);
    final theme = ThemeControl.instance.theme;
    final contentType = widget.contentType;
    return ValueListenableBuilder<bool>(
      valueListenable: FavoritesControl.instance.onShowOnlyFavorites,
      builder: (context, showOnlyFavorites, child) {
        final list = ContentControl.instance.getContent(
          contentType,
          filterFavorite: showOnlyFavorites,
        );
        final showDisabledActions =
            list.isNotEmpty && list.first is Playlist && (list as List<Playlist>).every((el) => el.songIds.isEmpty);
        final selectionController = widget.selectionController;
        final selectionRoute = selectionRouteOf(context);
        return RefreshIndicator(
          key: refreshIndicatorKey,
          strokeWidth: 2.5,
          color: theme.colorScheme.onPrimary,
          backgroundColor: theme.colorScheme.primary,
          onRefresh: ContentControl.instance.refetchAll,
          notificationPredicate: (notification) {
            return selectionController.notInSelection && notification.depth == 0;
          },
          child: showOnlyFavorites && list.isEmpty
              ? Center(child: Text(l10n.nothingHere))
              : ContentListView(
                  contentType: contentType,
                  list: list,
                  showScrollbarLabel: showLabel,
                  selectionController: selectionController,
                  onItemTap: (index) {
                    switch (contentType) {
                      case ContentType.song:
                        QueueControl.instance.resetQueue();
                        break;
                      case ContentType.album:
                      case ContentType.playlist:
                      case ContentType.artist:
                        break;
                    }
                  },
                  leading: Column(
                    children: [
                      if (selectionRoute)
                        ContentListHeader.onlyCount(contentType: contentType, count: list.length)
                      else
                        ContentListHeader(
                          contentType: contentType,
                          count: list.length,
                          selectionController: selectionController,
                          trailing: Padding(
                            padding: const EdgeInsets.only(bottom: 1.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
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
                                          onPressed: showDisabledActions
                                              ? null
                                              : () {
                                                  switch (contentType) {
                                                    case ContentType.song:
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allSongs,
                                                        modified: false,
                                                        shuffled: true,
                                                        shuffleFrom: list as List<Song>,
                                                      );
                                                      break;
                                                    case ContentType.album:
                                                      final shuffleResult =
                                                          ContentUtils.shuffleSongOrigins(list as List<Album>);
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allAlbums,
                                                        shuffled: true,
                                                        songs: shuffleResult.shuffledSongs,
                                                        shuffleFrom: shuffleResult.songs,
                                                      );
                                                      break;
                                                    case ContentType.playlist:
                                                      final shuffleResult =
                                                          ContentUtils.shuffleSongOrigins(list as List<Playlist>);
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allPlaylists,
                                                        shuffled: true,
                                                        songs: shuffleResult.shuffledSongs,
                                                        shuffleFrom: shuffleResult.songs,
                                                      );
                                                      break;
                                                    case ContentType.artist:
                                                      final shuffleResult =
                                                          ContentUtils.shuffleSongOrigins(list as List<Artist>);
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allArtists,
                                                        shuffled: true,
                                                        songs: shuffleResult.shuffledSongs,
                                                        shuffleFrom: shuffleResult.songs,
                                                      );
                                                      break;
                                                  }
                                                  MusicPlayer.instance
                                                      .setSong(QueueControl.instance.state.current.songs[0]);
                                                  MusicPlayer.instance.play();
                                                  playerRouteController.open();
                                                },
                                        ),
                                        AnimatedContentListHeaderAction(
                                          icon: const Icon(Icons.play_arrow_rounded),
                                          onPressed: showDisabledActions
                                              ? null
                                              : () {
                                                  switch (contentType) {
                                                    case ContentType.song:
                                                      QueueControl.instance.resetQueue();
                                                      break;
                                                    case ContentType.album:
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allAlbums,
                                                        songs: ContentUtils.joinSongOrigins(list as List<Album>),
                                                      );
                                                      break;
                                                    case ContentType.playlist:
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allPlaylists,
                                                        songs: ContentUtils.joinSongOrigins(list as List<Playlist>),
                                                      );
                                                      break;
                                                    case ContentType.artist:
                                                      QueueControl.instance.setQueue(
                                                        type: QueueType.allArtists,
                                                        songs: ContentUtils.joinSongOrigins(list as List<Artist>),
                                                      );
                                                      break;
                                                  }
                                                  MusicPlayer.instance
                                                      .setSong(QueueControl.instance.state.current.songs[0]);
                                                  MusicPlayer.instance.play();
                                                  playerRouteController.open();
                                                },
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      if (contentType == ContentType.playlist && !selectionRoute)
                        CreatePlaylistInListAction(enabled: selectionController.notInSelection),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class TabCollapse extends StatelessWidget {
  const TabCollapse({
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
    // TODO: some weird stuff happening if value is 1.6090780263766646e-7, this suggests some issue in the rendering that would needed to be investigated, reproduced and filed to flutter as issue
    return NFTab(
      child: AnimatedBuilder(
        animation: tabController.animation!,
        child: Text(label),
        builder: (context, child) {
          final tabValue = tabController.animation!.value;
          final indexIsChanging = tabController.indexIsChanging;
          double value = 0.0;
          if (tabValue > index - 1 && tabValue <= index) {
            if (!indexIsChanging ||
                indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
              // Animation for next tab.
              value = 1 + (tabController.animation!.value - index);
            }
          } else if (tabValue <= index + 1 && tabValue > index) {
            if (!indexIsChanging ||
                indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
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
                width: 4 *
                    TweenSequence([
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
        },
      ),
    );
  }
}
