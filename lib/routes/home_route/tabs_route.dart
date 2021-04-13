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

class TabsRouteState extends State<TabsRoute>
  with TickerProviderStateMixin, SelectionHandler {
  ContentMap<ContentSelectionController> selectionControllersMap;
  TabController tabController;
  StreamSubscription<Song> _songChangeSubscription;
  StreamSubscription<void> _contentChangeSubscription;

  SelectionController get selectionController {
    switch (tabController.index) {
      case 0:
        return selectionControllersMap.getValue<Song>();
      case 1:
        return selectionControllersMap.getValue<Album>();
      default:
        throw UnimplementedError();
    }
  }

  _ContentTab<T> buildContentTab<T extends Content>() {
    return _ContentTab<T>(
      selectionController: selectionControllersMap.getValue<T>()
          as ContentSelectionController<SelectionEntry<T>>
      );
  }

  @override
  void initState() {
    super.initState();
    selectionControllersMap = ContentMap({
      Song: ContentSelectionController.forContent<Song>(this),
      Album: ContentSelectionController.forContent<Album>(this),
    });
    tabController = TabController(
      vsync: this,
      length: 2,
    );
    for (final controller in selectionControllersMap.values) {
      controller.addListener(handleSelection);
      controller.addStatusListener(handleSelectionStatus);
    }
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) {
      setState(() {/* update current track indicator */});
    });
    _contentChangeSubscription = ContentControl.state.onContentChange.listen((event) {
      setState(() {/* update to display possible changes in the list */});
    });
    tabController.addListener(() {
      setState(() {/* update to change currently used selection controller */});
    });
  }

  @override
  void dispose() {
    for (final controller in selectionControllersMap.values) {
      controller.dispose();
    }
    tabController.dispose();
    _contentChangeSubscription.cancel();
    _songChangeSubscription.cancel();
    super.dispose();
  }

  List<NFTab> _buildTabs() {
    final l10n = getl10n(context);
    return [
      NFTab(text: l10n.tracks),
      NFTab(text: l10n.albums),
    ];
  }

  
  DateTime _lastBackPressTime;
  Future<bool> _handlePop() async {
    final navigatorKey = HomeRouter.instance.navigatorKey;
    if (navigatorKey.currentState != null && navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop();
      return true;
    } else {
      final now = DateTime.now();
      // Show toast when user presses back button on main route, that
      // asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.instance.showToast(msg: getl10n(context).pressOnceAgainToExit);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appBar = PreferredSize(
      preferredSize: const Size.fromHeight(kNFAppBarPreferredSize),
      child: SelectionAppBar(
        titleSpacing: 0.0,
        elevation: 0.0,
        elevationSelection: 0.0,
        selectionController: selectionController,
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
          if (selectionController is ContentSelectionController<SelectionEntry<Song>>)
            DeleteSongsAppBarAction<Song>(controller: selectionController),
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
      ),
    );

    return NFBackButtonListener(
      onBackButtonPressed: _handlePop,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: kNFAppBarPreferredSize + 4.0,
              ),
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: const GlowlessScrollBehavior(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: ContentControl.state.albums.isNotEmpty ? 44.0 : 0.0,
                      ),
                      child: ContentControl.state.albums.isEmpty
                          ? buildContentTab<Song>()
                          : TabBarView(
                              controller: tabController,
                              physics: selectionController.inSelection
                                  ? const NeverScrollableScrollPhysics()
                                  : const _TabsScrollPhysics(),
                              children: [
                                buildContentTab<Song>(),
                                buildContentTab<Album>(),
                              ],
                            ),
                    ),
                  ),
                  if (ContentControl.state.albums.isNotEmpty)
                    IgnorePointer(
                      ignoring: selectionController.inSelection,
                      child: Theme(
                        data: ThemeControl.theme.copyWith(
                          splashFactory: NFListTileInkRipple.splashFactory,
                        ),
                        child: Material(
                          elevation: 2.0,
                          color: ThemeControl.theme.appBarTheme.color,
                          child: NFTabBar(
                            controller: tabController,
                            indicatorWeight: 5.0,
                            indicator: BoxDecoration(
                              color: ThemeControl.theme.colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3.0),
                                topRight: Radius.circular(3.0),
                              ),
                            ),
                            labelColor: ThemeControl.theme.textTheme.headline6.color,
                            indicatorSize: TabBarIndicatorSize.label,
                            unselectedLabelColor: ThemeControl.theme.colorScheme.onSurface.withOpacity(0.6),
                            labelStyle: ThemeControl.theme.textTheme.headline6.copyWith(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                            ),
                            tabs: _buildTabs(),
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

  final ContentSelectionController<SelectionEntry<T>> selectionController;

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
        leading: ContentListHeader<T>(
          count: list.length,
          selectionController: selectionController,
          trailing: Padding(
            padding: const EdgeInsets.only(bottom: 1.0, right: 10.0),
            child: Row(
              children: [
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
                        );
                      },
                    )();
                    MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                    MusicPlayer.instance.play();
                    playerRouteController.open();
                  },
                ),
                ContentListHeaderAction(
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: () {
                     contentPick<T, VoidCallback>(
                      song: () {
                        ContentControl.setQueue(
                          type: QueueType.all,
                          modified: false,
                          shuffled: true,
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
                          songs: songs..shuffle(),
                          shuffled: true,
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
        onItemTap: ContentControl.resetQueue,
      )
    );
  }
}
