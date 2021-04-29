/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Returns app style used for app bar title.
TextStyle get appBarTitleTextStyle => TextStyle(
  fontWeight: FontWeight.w700,
  color: ThemeControl.theme.textTheme.headline6.color,
  fontSize: 22.0,
  fontFamily: 'Roboto',
);

/// Needed to change physics of the [TabBarView].
class _TabsScrollPhysics extends AlwaysScrollableScrollPhysics {
  const _TabsScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  _TabsScrollPhysics applyTo(ScrollPhysics ancestor) {
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
  const TabsRoute({Key key}) : super(key: key);

  @override
  TabsRouteState createState() => TabsRouteState();
}

class TabsRouteState extends State<TabsRoute> with TickerProviderStateMixin, SelectionHandler {
  static const tabBarHeight = 44.0;
  ContentSelectionController selectionController;
  TabController tabController;
  /// Used in [HomeRouter.drawerCanBeOpened].
  bool tabBarDragged = false;

  @override
  void initState() {
    super.initState();
    selectionController = ContentSelectionController.forContent(
      this,
      ignoreWhen: () => playerRouteController.opened || HomeRouter.instance.routes.last != HomeRoutes.tabs,
    )
      ..addListener(handleSelection)
      ..addStatusListener(handleSelectionStatus);
    tabController = TabController(
      vsync: this,
      length: 4,
    )
      ..addListener(handleSelection);
  }

  @override
  void dispose() {
    selectionController.dispose();
    tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    final l10n = getl10n(context);
    return [
      _TabCollapse(
        index: 0,
        tabController: tabController,
        icon: const Icon(Icons.music_note_rounded),
        label: l10n.tracks,
      ),
      _TabCollapse(
        index: 1,
        tabController: tabController,
        icon: const Icon(Icons.album_rounded),
        label: l10n.albums,
      ),
      _TabCollapse(
        index: 2,
        tabController: tabController,
        icon: const Icon(Icons.queue_music_rounded),
        label: l10n.playlists,
      ),
      _TabCollapse(
        index: 3,
        tabController: tabController,
        icon: const Icon(Icons.person_rounded),
        label: l10n.artists,
      ),
    ];
  }

  
  DateTime _lastBackPressTime;
  Future<bool> _handlePop() async {
    final navigatorKey = AppRouter.instance.navigatorKey;
    final homeNavigatorKey = HomeRouter.instance.navigatorKey;
    if (navigatorKey.currentState != null && navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop();
      return true;
    } else if (homeNavigatorKey.currentState != null && homeNavigatorKey.currentState.canPop()) {
      homeNavigatorKey.currentState.pop();
      return true;
    } else {
      final now = DateTime.now();
      // Show toast when user presses back button on main route, that
      // asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null || now.difference(_lastBackPressTime) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.instance.showToast(msg: getl10n(context).pressOnceAgainToExit);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;

    final appBar = SelectionAppBar(
      titleSpacing: 0.0,
      elevation: 2.0,
      elevationSelection: 2.0,
      selectionController: selectionController,
      toolbarHeight: kToolbarHeight,
      onMenuPressed: () {
        drawerController.open();
      },
      actions: [
        NFIconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            ShowFunctions.instance.showSongsSearch();
          },
        ),
      ],
      actionsSelection: [
        DeleteSongsAppBarAction<Content>(controller: selectionController),
      ],
      title: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Text(
          Constants.Config.APPLICATION_TITLE,
          style: appBarTitleTextStyle,
        ),
      ),
      titleSelection: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: SelectionCounter(controller: selectionController),
      ),
    );

    return NFBackButtonListener(
      onBackButtonPressed: _handlePop,
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
                          Container(),
                          Container(),
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
                                  labelColor: theme.textTheme.headline6.color,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                                  labelStyle: theme.textTheme.headline6.copyWith(
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
    );
  }
}


class _ContentTab<T extends Content> extends StatefulWidget {
  _ContentTab({Key key, @required this.selectionController}) : super(key: key);

  final ContentSelectionController<SelectionEntry> selectionController;

  @override
  _ContentTabState<T> createState() => _ContentTabState();
}

class _ContentTabState<T extends Content> extends State<_ContentTab<T>> with AutomaticKeepAliveClientMixin<_ContentTab<T>> {
  @override
  bool get wantKeepAlive => true;

  final key = GlobalKey<RefreshIndicatorState>();

  bool get showLabel {
    final SortFeature feature = ContentControl.state.sorts.getValue<T>().feature;
    return contentPick<T, bool>(
      song: feature == SongSortFeature.title,
      album: feature == AlbumSortFeature.title,
    );
  }

  Future<void> Function() get onRefresh {
    return contentPick<T, Future<void> Function()>(
      song: () => Future.wait([
        ContentControl.refetch<Song>(),
        ContentControl.refetch<Album>(),
      ]),
      album: () => ContentControl.refetch<Album>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = ContentControl.getContent<T>();
    final selectionController = widget.selectionController;
    return RefreshIndicator(
      key: key,
      strokeWidth: 2.5,
      color: Colors.white,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      onRefresh: onRefresh,
      notificationPredicate: (notification) {
        return selectionController.notInSelection &&
               notification.depth == 0;
      },
      child: ContentListView<T>(
        list: list,
        showScrollbarLabel: showLabel,
        selectionController: selectionController,
        onItemTap: contentPick<T, VoidCallback>(
          song: ContentControl.resetQueue,
        ),
        leading: ContentListHeader<T>(
          count: list.length,
          selectionController: selectionController,
          trailing: Padding(
            padding: const EdgeInsets.only(bottom: 1.0, right: 10.0),
            child: Row(
              children: [
                ContentListHeaderAction(
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: () {
                     contentPick<T, VoidCallback>(
                      song: () {
                        ContentControl.setQueue(
                          type: QueueType.all,
                          modified: false,
                          shuffled: true,
                          shuffleFrom: ContentControl.state.allSongs.songs,
                        );
                      },
                      album: () {
                        final List<Song> songs = [];
                        for (final album in ContentControl.state.albums.values.toList()) {
                          for (final song in album.songs) {
                            song.origin = album;
                            songs.add(song);
                          }
                        }
                        ContentControl.setQueue(
                          type: QueueType.arbitrary,
                          shuffled: true,
                          shuffleFrom: songs,
                          arbitraryQueueOrigin: ArbitraryQueueOrigin.allAlbums,
                        );
                      },
                    )();
                    MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                    MusicPlayer.instance.play();
                    playerRouteController.open();
                  },
                ),
                ContentListHeaderAction(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () {
                    contentPick<T, VoidCallback>(
                      song: () {
                        ContentControl.resetQueue();
                      },
                      album: () {
                        final List<Song> songs = [];
                        for (final album in ContentControl.state.albums.values.toList()) {
                          for (final song in album.songs) {
                            song.origin = album;
                            songs.add(song);
                          }
                        }
                        ContentControl.setQueue(
                          type: QueueType.arbitrary,
                          songs: songs,
                          arbitraryQueueOrigin: ArbitraryQueueOrigin.allAlbums,
                        );
                      },
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
      )
    );
  }
}

class _TabCollapse extends StatelessWidget {
  const _TabCollapse({
    Key key,
    this.index,
    this.tabController,
    this.label,
    this.icon,
  }) : super(key: key);

  final int index;
  final TabController tabController;
  final String label; 
  final Icon icon; 

  @override
  Widget build(BuildContext context) {
    return NFTab(
      child: AnimatedBuilder(
        animation: tabController.animation,
        builder: (context, child) {
          final tabValue = tabController.animation.value;
          final indexIsChanging = tabController.indexIsChanging;
          double value = 0.0;
          if (tabValue > index - 1 && tabValue <= index) {
            if (!indexIsChanging || indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
              // Animation for next tab.
              value = 1 + (tabController.animation.value - index);
            }
          } else if (tabValue <= index + 1 && tabValue > index) {
            if (!indexIsChanging || indexIsChanging && (tabController.index == index || tabController.previousIndex == index)) {
              // Animation for previos tab.
              value = 1 - (tabController.animation.value - index);
            }
          }
          value = value.clamp(0.0, 1.0);
          return Row(
            children: [
              ClipRRect(
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
              ClipRRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Text(label),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}