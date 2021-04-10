/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

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
  TabsRoute(
    this.tabController, {
    Key key,
  }) : super(key: key);

  final TabController tabController;

  @override
  _TabsRouteState createState() => _TabsRouteState();
}

class _TabsRouteState extends State<TabsRoute> {
  StreamSubscription<Song> _songChangeSubscription;
  StreamSubscription<void> _songListChangeSubscription;
  TabController get tabController => widget.tabController;
  ContentSelectionControllersProvider controllersProvider;

  SelectionController get selectionController {
    switch (tabController.index) {
      case 0:
        return controllersProvider.song;
      case 1:
        return controllersProvider.album;
      default:
        throw UnimplementedError();
    }
  }

  @override
  void initState() {
    super.initState();
    controllersProvider = ContentSelectionControllersProvider.of(context);
    for (final controller in controllersProvider.map.values) {
      controller.addListener(_handleSelection);
      controller.addStatusListener(_handleSelectionStatus);
    }
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) {
      setState(() {/* update current track indicator */});
    });
    _songListChangeSubscription = ContentControl.state.onSongListChange.listen((event) {
      setState(() {/* update to display possible changes in the list */});
    });
    tabController.addListener(() {
      setState(() {/* update to change currently used selection controller */});
    });
  }

  void _handleSelection() {
    setState(() {
      /* update appbar and tiles on selection
      primarily needed to update the selection number in [SelectionAppBar] */
    });
  }

  void _handleSelectionStatus(AnimationStatus _) {
    setState(() {/* update appbar and tiles on selection status */});
  }

  @override
  void dispose() {
    for (final controller in controllersProvider.map.values) {
      controller.removeListener(_handleSelection);
      controller.removeStatusListener(_handleSelectionStatus);
    }
    _songListChangeSubscription.cancel();
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

  void _handleDelete() {
    final controller = controllersProvider.song;
    if (ContentControl.state.sdkInt >= 30) {
      // On Android R the deletion is performed with OS dialog.
      ContentControl.deleteSongs(controller.data.map((e) => e.data.sourceId).toSet());
      controller.close();
    } else {
      // On all versions below show in app dialog.
      final l10n = getl10n(context);
      final count = controller.data.length;
      Song song;
      if (count == 1) {
        song = ContentControl.state.queues.all.byId.getSong(controller.data.first.data.sourceId);
      }
      ShowFunctions.instance.showDialog(
        context,
        title: Text(
          '${l10n.delete} ${count > 1 ? count.toString() + ' ' : ''}${l10n.tracksPlural(count).toLowerCase()}',
        ),
        content: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 15.0),
            children: [
              TextSpan(text: l10n.deletionPromptDescriptionP1),
              TextSpan(
                text: song != null
                    ? '${song.title}?'
                    : l10n.deletionPromptDescriptionP2,
                style: song != null
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
            ],
          ),
        ),
        buttonSplashColor: Constants.AppTheme.glowSplashColor.auto,
        acceptButton: NFButton.accept(
          text: l10n.delete,
          splashColor: Constants.AppTheme.glowSplashColor.auto,
          textStyle: const TextStyle(color: Constants.AppColors.red),
          onPressed: () {
            ContentControl.deleteSongs(controller.data.map((e) => e.data.sourceId).toSet());
            controller.close();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleTextStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: ThemeControl.theme.textTheme.headline6.color,
      fontSize: 22.0,
    );

    /// Not letting to go less 1 to not play animation from 1 to 0.
    final selectionCount = selectionController.data.isNotEmpty ? selectionController.data.length : 1;
    final appBar = PreferredSize(
      preferredSize: const Size.fromHeight(kNFAppBarPreferredSize),
      child: SelectionAppBar(
        titleSpacing: 0.0,
        elevation: 0.0,
        elevationSelection: 0.0,
        selectionController: selectionController,
        onMenuPressed: () {
          getDrawerControllerProvider(context).controller.open();
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
          NFIconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _handleDelete,
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Text(
            Constants.Config.APPLICATION_TITLE,
            style: appBarTitleTextStyle,
          ),
        ),
        titleSelection: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 0),
          child: CountSwitcher(
            childKey: ValueKey(selectionCount),
            valueIncreased: selectionController.lengthIncreased,
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text(
                selectionCount.toString(),
                style: appBarTitleTextStyle,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
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
                        ? _SongsTab()
                        : TabBarView(
                            controller: tabController,
                            physics: selectionController.inSelection
                                ? const NeverScrollableScrollPhysics()
                                : const _TabsScrollPhysics(),
                            children: [
                              _SongsTab(), 
                              _AlbumsTab(),
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
    );
  }
}


class _SongsTab extends StatefulWidget {
  _SongsTab({Key key}) : super(key: key);

  @override
  _SongsTabState createState() => _SongsTabState();
}

class _SongsTabState extends State<_SongsTab> with AutomaticKeepAliveClientMixin<_SongsTab> {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final ItemScrollController itemScrollController = ItemScrollController();
  bool _scrollbarDragged = false;

  void _handleDragStart() {
    _scrollbarDragged = true;
  }

  void _handleDragEnd() {
    _scrollbarDragged = false;
  }

  /// Performs tracks refetch
  Future<void> _handleRefreshSongs() async {
    await Future.wait([
      ContentControl.refetch<Song>(),
      ContentControl.refetch<Album>(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final songs = ContentControl.state.queues.all.songs;
    final controller = ContentSelectionControllersProvider.of(context).song;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      strokeWidth: 2.5,
      key: _refreshIndicatorKey,
      onRefresh: _handleRefreshSongs,
      notificationPredicate: (notification) {
        // Prevent pull to refresh when scrollbar is dragged.
        return !_scrollbarDragged &&
            controller.notInSelection &&
            notification.depth == 0;
      },
      child: SongListView(
        songs: songs,
        itemScrollController: itemScrollController,
        selectionController: controller,
        scrollbar: ScrollbarType.draggable,
        onScrollbarDragStart: _handleDragStart,
        onScrollbarDragEnd: _handleDragEnd,
        leading: SongSortListHeader(
          count: songs.length,
          selectionController: controller,
        ),
        onItemTap: () => ContentControl.setQueue(
          type: QueueType.all,
          modified: false,
          shuffled: false,
        ),
      )
    );
  }
}


class _AlbumsTab extends StatefulWidget {
  _AlbumsTab({Key key}) : super(key: key);

  @override
  _AlbumsTabState createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<_AlbumsTab> with AutomaticKeepAliveClientMixin<_AlbumsTab> {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final ItemScrollController itemScrollController = ItemScrollController();
  bool _scrollbarDragged = false;

  void _handleDragStart() {
    _scrollbarDragged = true;
  }

  void _handleDragEnd() {
    _scrollbarDragged = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final albums = ContentControl.state.albums.values.toList();
    final controller = ContentSelectionControllersProvider.of(context).album;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      strokeWidth: 2.5,
      key: _refreshIndicatorKey,
      onRefresh: () => ContentControl.refetch<Album>(),
      notificationPredicate: (notification) {
        // Prevent pull to refresh when scrollbar is dragged.
        return !_scrollbarDragged &&
            controller.notInSelection &&
            notification.depth == 0;
      },
      child: AlbumListView(
        albums: albums,
        itemScrollController: itemScrollController,
        selectionController: controller,
        scrollbar: ScrollbarType.draggable,
        onScrollbarDragStart: _handleDragStart,
        onScrollbarDragEnd: _handleDragEnd,
        leading: AlbumSortListHeader(
          count: albums.length,
          selectionController: controller,
        ),
      )
    );
  }
}