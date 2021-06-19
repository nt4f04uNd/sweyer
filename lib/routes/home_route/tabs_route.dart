/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';
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
  /// Main route variant shown on top of the [HomeRouter].
  const TabsRoute({Key? key})
    : selectionArguments = null,
      super(key: key);

  /// Route variant used to select items.
  TabsRoute.selection({
    Key? key,
    required this.selectionArguments,
  }) : super(key: key);

  final TabsSelectionArguments? selectionArguments;

  @override
  TabsRouteState createState() => TabsRouteState();
}

class TabsRouteState extends State<TabsRoute> with TickerProviderStateMixin, SelectionHandler {
  static const tabBarHeight = 44.0;

  late TabController tabController;
  late ContentSelectionController selectionController;

  late GlobalKey<NavigatorState> navigatorKey;

  /// Used in [HomeRouter.drawerCanBeOpened].
  bool tabBarDragged = false;
  static late bool _mainTabsCreated = false;

  bool get selection => widget.selectionArguments != null;

  @override
  void initState() {
    super.initState();

    assert(() {
      if (!selection) {
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

    if (selection) {
      navigatorKey = GlobalKey();
      BackButtonInterceptor.add(backButtonInterceptor);
      selectionController = ContentSelectionController.createAlwaysInSelection(
        context: context,
        actionsBuilder: (context) {
          final l10n = getl10n(context);
          return [
            AnimatedBuilder(
              animation: selectionController,
              builder: (context, child) => AppButton(
                text: l10n.done,
                onPressed: selectionController.data.isEmpty ? null : () {
                  widget.selectionArguments!.onSubmit(selectionController.data);
                  Navigator.of(this.context).pop();
                },
              ),
            ),
  
          ];
        },
      );
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        if (mounted) {
          selectionController.overlay = navigatorKey.currentState!.overlay;
          selectionController.activate();
        }
      });
    } else {
      selectionController = ContentSelectionController.create(
        vsync: this,
        context: context,
        ignoreWhen: () => playerRouteController.opened ||
                          HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.tabs),
      );
    }

    selectionController.addListener(handleSelection);
    tabController = TabController(
      vsync: this,
      length: 4,
    );
  }

  @override
  void dispose() {
    assert(() {
      if (!selection)
        _mainTabsCreated = false;
      return true;
    }());
    if (selection)
      BackButtonInterceptor.remove(backButtonInterceptor);
    selectionController.dispose();
    tabController.dispose();
    super.dispose();
  }

  /// Using interceptor for [selection] to gain a priority over the navigator and
  /// internal [SearchRoute] back button listeners, because I want the selection route
  /// to be closed with one back button tap.
  bool backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (stopDefaultButtonEvent)
      return false;
    Navigator.of(context).maybePop();
    BackButtonInterceptor.remove(backButtonInterceptor);
    return true;
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

  
  DateTime? _lastBackPressTime;
  Future<bool> _handlePop() async {
    final navigatorKey = AppRouter.instance.navigatorKey;
    final homeNavigatorKey = HomeRouter.instance.navigatorKey;
    if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
      return true;
    } else if (homeNavigatorKey.currentState != null && homeNavigatorKey.currentState!.canPop()) {
      homeNavigatorKey.currentState!.pop();
      return true;
    } else {
      final now = DateTime.now();
      // Show toast when user presses back button on main route, that
      // asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.instance.showToast(msg: getl10n(context).pressOnceAgainToExit);
        return true;
      }
    }
    return false;
  }

  Widget _buildPage() {
    final theme = ThemeControl.theme;
    final screenWidth = MediaQuery.of(context).size.width;

    final appBar = SelectionAppBar(
      titleSpacing: 0.0,
      elevation: 2.0,
      elevationSelection: 2.0,
      selectionController: selectionController,
      toolbarHeight: kToolbarHeight,
      showMenuButton: !selection,
      leading: selection
        ? NFBackButton(onPressed: () => Navigator.of(context).pop())
        : const NFBackButton(),
      onMenuPressed: () {
        drawerController.open();
      },
      actions: selection ? const [] : [
        NFIconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            ShowFunctions.instance.showSongsSearch();
          },
        ),
      ],
      actionsSelection: !selection
        ? [DeleteSongsAppBarAction<Content>(controller: selectionController)]
        : [NFIconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              navigatorKey.currentState!.push(SearchPageRoute(
                transitionSettings: AppRouter.instance.transitionSettings.grey,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kSongTileHeight),
                  child: SearchRoute(
                    delegate: ContentSearchDelegate(selectionController),
                  ),
                ),
              ));
            },
          )],
      title: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: selection ? const SizedBox.shrink() : Text(
          Constants.Config.APPLICATION_TITLE,
          style: appBarTitleTextStyle,
        ),
      ),
      titleSelection: selection
        ? Text(
            widget.selectionArguments!.title(context),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 10.0),
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
                            _ContentTab<Song>(selectionController: selectionController, selection: selection),
                            _ContentTab<Album>(selectionController: selectionController, selection: selection),
                            _ContentTab<Playlist>(selectionController: selectionController, selection: selection),
                            _ContentTab<Artist>(selectionController: selectionController, selection: selection),
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

  @override
  Widget build(BuildContext context) {
    if (selection)
      return Navigator(
        key: navigatorKey,
        onGenerateInitialRoutes: (context, name) {
          return [PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Padding(
              padding: const EdgeInsets.only(bottom: kSongTileHeight),
              child: _buildPage(),
            ),
          )];
        },
      );
    return _buildPage();
  }
}


class _ContentTab<T extends Content> extends StatefulWidget {
  _ContentTab({
    Key? key,
    required this.selection,
    required this.selectionController,
  }) : super(key: key);

  final bool selection;
  final ContentSelectionController<SelectionEntry>? selectionController;

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

  Widget _buildCreatePlaylist() {
    final l10n = getl10n(context);
    return InListContentAction.persistentQueue(
      onTap: _handleCreatePlaylist,
      icon: Icons.add_rounded,
      text: l10n.newPlaylist,
    );
  }

  Future<void> _handleCreatePlaylist() async {
    final l10n = getl10n(context);
    final theme = ThemeControl.theme;
    final TextEditingController controller = TextEditingController();
    final AnimationController animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    controller.addListener(() {
      if (controller.text.trim().isNotEmpty)
        animationController.forward();
      else
        animationController.reverse();
    });
    final animation = ColorTween(
      begin: theme.disabledColor,
      end: theme.colorScheme.onSecondary,
    ).animate(CurvedAnimation(
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
      parent: animationController,
    ));
    bool submitted = false;
    Future<void> submit(BuildContext context) async {
      if (!submitted) {
        submitted = true;
        await ContentControl.createPlaylist(controller.text);
        Navigator.of(context).maybePop();
      }
    }
    await ShowFunctions.instance.showDialog(
      context,
      ui: Constants.UiTheme.modalOverGrey.auto,
      title: Text(l10n.newPlaylist),
      content: Builder(
        builder: (context) => AppTextField(
          autofocus: true,
          controller: controller,
          onSubmit: (value) {
            submit(context);
          },
          onDispose: () {
            controller.dispose();
            animationController.dispose();
          },
        ),
      ),
      buttonSplashColor: Constants.Theme.glowSplashColor.auto,
      acceptButton: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => IgnorePointer(
          ignoring: const IgnoringStrategy(
            dismissed: true,
            reverse: true,
          ).ask(animation),
          child: NFButton(
            text: l10n.create,
            textStyle: TextStyle(color: animation.value),
            splashColor: Constants.Theme.glowSplashColor.auto,
            onPressed: () async {
              submit(context);
            },
          ),
        ),
      ),
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
      onRefresh: ContentControl.refetchAll,
      backgroundColor: ThemeControl.theme.colorScheme.primary,
      notificationPredicate: (notification) {
        return selectionController!.notInSelection &&
               notification.depth == 0;
      },
      child: ContentListView<T>(
        list: list,
        showScrollbarLabel: showLabel,
        selectionController: selectionController,
        onItemTap: contentPick<T, VoidCallback>(
          song: ContentControl.resetQueue,
          album: () {},
          playlist: () {},
          artist: () {},
        ),
        leading: Column(
          children: [
            if (widget.selection)
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
                    child: list.isEmpty || widget.selection
                      ? const SizedBox(
                          width: ContentListHeaderAction.size * 2,
                          height: ContentListHeaderAction.size,
                        )
                      : Row(
                        children: [
                          ContentListHeaderAction(
                            icon: const Icon(Icons.shuffle_rounded),
                            onPressed: () {
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
                          ContentListHeaderAction(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () {
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
            if (T == Playlist && !widget.selection)
              _buildCreatePlaylist(),
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
              // Animation for previos tab.
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
