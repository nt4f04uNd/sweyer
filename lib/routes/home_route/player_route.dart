import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:styled_text/styled_text.dart';

import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';

final SpringDescription playerRouteSpringDescription = SpringDescription.withDampingRatio(
  mass: 0.01,
  stiffness: 30.0,
  ratio: 2.0,
);

class PlayerRoute extends StatefulWidget {
  const PlayerRoute({super.key});

  @override
  _PlayerRouteState createState() => _PlayerRouteState();
}

class _PlayerRouteState extends State<PlayerRoute> with SingleTickerProviderStateMixin, SelectionHandlerMixin {
  final _queueTabKey = GlobalKey<_QueueTabState>();
  late List<Widget> _tabs;
  late SlidableController controller;
  late SharedAxisTabController tabController;

  Animation? _queueTabAnimation;
  SlideDirection slideDirection = SlideDirection.up;

  @override
  void initState() {
    super.initState();
    initSelectionController(
      () => ContentSelectionController.create(
        vsync: this,
        context: context,
        contentType: ContentType.song,
        closeButton: true,
        systemUiOverlayStyle: () => PlayerInterfaceColorStyleControl.instance.systemUiOverlayStyleForSelection,
        actionsBarWrapperBuilder: (context, child) => PlayerInterfaceThemeOverride(child: child),
        additionalPlayActionsBuilder: (context) => const [
          RemoveFromQueueSelectionAction(),
        ],
      ),
      listenStatus: true,
    );

    _tabs = [
      const _MainTab(),
      _QueueTab(
        key: _queueTabKey,
        selectionController: selectionController,
      ),
    ];
    tabController = SharedAxisTabController(length: 2);
    tabController.addListener(() {
      if (tabController.index == 0) {
        _queueTabKey.currentState!.opened = false;
      } else if (tabController.index == 1) {
        _queueTabKey.currentState!.opened = true;
      }
    });
    controller = playerRouteController;
    controller.addListener(_handleControllerChange);
    controller.addStatusListener(_handleControllerStatusChange);
  }

  @override
  void dispose() {
    tabController.dispose();
    disposeSelectionController();
    controller.removeListener(_handleControllerChange);
    controller.removeStatusListener(_handleControllerStatusChange);
    super.dispose();
  }

  @override
  void handleSelectionStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      slideDirection = SlideDirection.none;
      tabController.canChange = false;
    } else if (status == AnimationStatus.reverse) {
      slideDirection = SlideDirection.up;
      tabController.canChange = true;
    }
    super.handleSelectionStatus(status);
  }

  void _handleControllerChange() {
    final overlayStyle = PlayerInterfaceColorStyleControl.instance.systemUiOverlayStyle;
    // Change system UI on expanding/collapsing the player route.
    SystemUiStyleController.instance.setSystemUiOverlay(
      SystemUiStyleController.instance.lastUi.copyWith(
        systemNavigationBarColor: overlayStyle.systemNavigationBarColor,
      ),
    );
  }

  void _handleControllerStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      tabController.canChange = true;
      tabController.changeTab(0);
    }
  }

  void _handleQueueTabAnimationStatus(AnimationStatus status) {
    if (tabController.index == 0 && status == AnimationStatus.dismissed) {
      /// When the main tab is fully visible and the queue tab is not,
      /// reset the scroll controller.
      _queueTabKey.currentState!.jumpOnTabChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.secondaryContainer;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    return Slidable(
      controller: controller,
      start: 1.0 - TrackPanel.height(context) / screenHeight,
      end: 0.0,
      direction: slideDirection,
      barrier: Container(
        color: ThemeControl.instance.isDark ? Colors.black : Colors.black26,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        body: Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: playerRouteController,
              builder: (context, child) => AnimationSwitcher(
                animation: playerRouteController,
                child1: Container(
                  color: theme.colorScheme.secondary,
                ),
                child2: const PlayerInterfaceColorWidget(),
              ),
            ),
            PlayerInterfaceThemeOverride(
              child: SharedAxisTabView(
                children: _tabs,
                controller: tabController,
                tabBuilder: (context, animation, secondaryAnimation, child) {
                  if (child is _QueueTab) {
                    if (animation != _queueTabAnimation) {
                      if (_queueTabAnimation != null) {
                        _queueTabAnimation!.removeStatusListener(_handleQueueTabAnimationStatus);
                      }
                      _queueTabAnimation = animation;
                      animation.addStatusListener(
                        _handleQueueTabAnimationStatus,
                      );
                    }
                  }
                  return IgnorePointer(
                    ignoring: child is _QueueTab && animation.status == AnimationStatus.reverse,
                    child: child,
                  );
                },
              ),
            ),
            TrackPanel(onTap: controller.open),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends StatefulWidget {
  const _QueueTab({
    super.key,
    required this.selectionController,
  });

  final ContentSelectionController selectionController;

  @override
  _QueueTabState createState() => _QueueTabState();
}

class _QueueTabState extends State<_QueueTab> with SelectionHandlerMixin {
  static const double baseAppBarHeight = 81.0;

  /// This is set in parent via global key
  bool opened = false;
  final ScrollController scrollController = ScrollController();

  /// A bool var to disable show/hide in track list controller listener when manual [scrollToSong] is performing
  late StreamSubscription<Song> _songChangeSubscription;
  late StreamSubscription<void> _queueChangeSubscription;

  QueueType get type => QueueControl.instance.state.type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      jumpToSong(PlaybackControl.instance.currentSongIndex);
    });

    widget.selectionController.addListener(handleSelection);

    _queueChangeSubscription = QueueControl.instance.onQueueChanged.listen((event) async {
      if (ContentControl.instance.state.allSongs.isNotEmpty) {
        setState(() {/* update ui list as data list may have changed */});
        if (!opened) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            // Jump when track list changes (e.g. shuffle happened)
            jumpToSong();
            // Post framing it because we need to be sure that list gets updated before we jump.
          });
        }
      }
    });
    _songChangeSubscription = PlaybackControl.instance.onSongChange.listen((event) async {
      setState(() {
        /* update current track indicator */
      });
      if (!opened) {
        WidgetsBinding.instance.addPostFrameCallback((timestamp) async {
          if (mounted) {
            // Scroll when track changes
            await scrollToSong();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    widget.selectionController.removeListener(handleSelection);
    _queueChangeSubscription.cancel();
    _songChangeSubscription.cancel();
    super.dispose();
  }

  /// Scrolls to current song.
  ///
  /// If optional [index] is provided - scrolls to it.
  Future<void> scrollToSong([int? index]) async {
    index ??= PlaybackControl.instance.currentSongIndex;
    final extent = index * kSongTileHeight(context);
    final pixels = scrollController.position.pixels;
    final min = scrollController.position.minScrollExtent;
    final max = scrollController.position.maxScrollExtent;
    final delta = (extent - pixels).abs();
    final screenHeight = MediaQuery.of(context).size.height;
    if (delta >= screenHeight) {
      final directionForward = extent > pixels;
      if (directionForward) {
        scrollController.jumpTo((extent - screenHeight * 2).clamp(min, max));
      } else {
        scrollController.jumpTo((extent + screenHeight * 2).clamp(min, max));
      }
    }
    return scrollController.animateTo(
      extent.clamp(min, max),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  /// Jumps to current song.
  ///
  /// If optional [index] is provided - jumps to it.
  void jumpToSong([int? index]) {
    if (!mounted) {
      return;
    }
    index ??= PlaybackControl.instance.currentSongIndex;
    final min = scrollController.position.minScrollExtent;
    final max = scrollController.position.maxScrollExtent;
    scrollController.jumpTo((index * kSongTileHeight(context)).clamp(min, max));
  }

  /// Jump to song when changing tab to main.
  void jumpOnTabChange() {
    jumpToSong();
  }

  void _handleTitleTap() {
    switch (type) {
      case QueueType.searched:
        final query = QueueControl.instance.state.searchQuery!;
        ShowFunctions.instance.showSongsSearch(
          context,
          query: query,
          openKeyboard: false,
        );
        SearchHistory.instance.add(query);
        return;
      case QueueType.origin:
        final origin = QueueControl.instance.state.origin!;
        if (origin is Album || origin is Playlist || origin is Artist) {
          HomeRouter.instance.goto(HomeRoutes.factory.content(origin));
        } else {
          throw UnimplementedError;
        }
        return;
      case QueueType.allSongs:
      case QueueType.allAlbums:
      case QueueType.allPlaylists:
      case QueueType.allArtists:
      case QueueType.arbitrary:
        return;
    }
  }

  double _getBorderRadius(SongOrigin origin) {
    if (origin is PersistentQueue) {
      return 8.0;
    } else if (origin is Artist) {
      return kArtistTileArtSize;
    }
    throw UnimplementedError();
  }

  /// The style that should be used for the queue description text in the app bar.
  TextStyle get _queueDescriptionStyle => Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: 14.0,
        height: 1.0,
        fontWeight: FontWeight.w700,
      );

  Text _buildTitleText(AppLocalizations l10n) {
    final InlineSpan text;
    final Key key;
    switch (QueueControl.instance.state.type) {
      case QueueType.allSongs:
        text = TextSpan(text: l10n.allTracks);
        key = ValueKey(l10n.allTracks);
        break;
      case QueueType.allAlbums:
        text = TextSpan(text: l10n.allAlbums);
        key = ValueKey(l10n.allAlbums);
        break;
      case QueueType.allPlaylists:
        text = TextSpan(text: l10n.allPlaylists);
        key = ValueKey(l10n.allPlaylists);
        break;
      case QueueType.allArtists:
        text = TextSpan(text: l10n.allArtists);
        key = ValueKey(l10n.allArtists);
        break;
      case QueueType.searched:
        final theme = Theme.of(context);
        final query = QueueControl.instance.state.searchQuery!;
        text = WidgetSpan(
          child: StyledText(
            overflow: TextOverflow.ellipsis,
            style: _queueDescriptionStyle,
            // TODO: otherwise this scales twice as much https://github.com/andyduke/styled_text_package/issues/83
            textScaleFactor: 1.0,
            text: l10n.foundByQuery('<query>${l10n.escapeStyled('"$query"')}</query>'),
            tags: {
              'query': StyledTextTag(
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            },
          ),
        );
        key = ValueKey(l10n.foundByQuery(query));
        break;
      case QueueType.origin:
        final theme = Theme.of(context);
        final origin = QueueControl.instance.state.origin!;
        if (origin is Album) {
          text = WidgetSpan(
            child: StyledText(
              overflow: TextOverflow.ellipsis,
              style: _queueDescriptionStyle,
              // TODO: otherwise this scales twice as much https://github.com/andyduke/styled_text_package/issues/83
              textScaleFactor: 1.0,
              text: l10n.albumQueue('<name>${l10n.escapeStyled(origin.nameDotYear)}</name>'),
              tags: {
                'name': StyledTextTag(
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              },
            ),
          );
          key = ValueKey(l10n.albumQueue(origin.nameDotYear));
        } else if (origin is Playlist) {
          final theme = Theme.of(context);
          text = WidgetSpan(
            child: StyledText(
              overflow: TextOverflow.ellipsis,
              style: _queueDescriptionStyle,
              // TODO: otherwise this scales twice as much https://github.com/andyduke/styled_text_package/issues/83
              textScaleFactor: 1.0,
              text: l10n.playlistQueue('<name>${l10n.escapeStyled(origin.name)}</name>'),
              tags: {
                'name': StyledTextTag(
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              },
            ),
          );
          key = ValueKey(l10n.playlistQueue(origin.name));
        } else if (origin is Artist) {
          final theme = Theme.of(context);
          final artist = ContentUtils.localizedArtist(origin.artist, l10n);
          text = WidgetSpan(
            child: StyledText(
              overflow: TextOverflow.ellipsis,
              style: _queueDescriptionStyle,
              // TODO: otherwise this scales twice as much https://github.com/andyduke/styled_text_package/issues/83
              textScaleFactor: 1.0,
              text: l10n.artistQueue('<name>${l10n.escapeStyled(artist)}</name>'),
              tags: {
                'name': StyledTextTag(
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              },
            ),
          );
          key = ValueKey(l10n.artistQueue(artist));
        } else {
          throw UnimplementedError('Unhandled origin: $origin');
        }
        break;
      case QueueType.arbitrary:
        text = TextSpan(text: l10n.arbitraryQueue);
        key = ValueKey(l10n.arbitraryQueue);
        break;
    }
    return Text.rich(
      text,
      key: key,
      overflow: TextOverflow.ellipsis,
      style: _queueDescriptionStyle,
    );
  }

  AnimatedCrossFade _crossFade(bool showFirst, Widget firstChild, Widget secondChild) {
    return AnimatedCrossFade(
      crossFadeState: showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 400),
      layoutBuilder: (Widget topChild, Key topChildKey, Widget bottomChild, Key bottomChildKey) {
        // TODO: remove `layoutBuilder` build when https://github.com/flutter/flutter/issues/82614 is resolved
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              key: bottomChildKey,
              top: 0.0,
              left: 0.0,
              bottom: 0.0,
              child: bottomChild,
            ),
            Positioned(
              key: topChildKey,
              child: topChild,
            ),
          ],
        );
      },
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeOutCubic,
      sizeCurve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      firstChild: firstChild,
      secondChild: secondChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSongIndex = PlaybackControl.instance.currentSongIndex;
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final origin = QueueControl.instance.state.origin;
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final appBarHeight =
        textScaleFactor <= 1.0 ? baseAppBarHeight : baseAppBarHeight / 2 + baseAppBarHeight / 2 * textScaleFactor;
    final topScreenPadding = mediaQuery.padding.top;
    final appBarHeightWithPadding = appBarHeight + topScreenPadding;
    final fadeAnimation = CurvedAnimation(
      curve: const Interval(0.6, 1.0),
      parent: playerRouteController,
    );
    final appBarAnimation = ColorTween(
      begin: Theme.of(HomeRouter.instance.navigatorKey.currentContext!).appBarTheme.backgroundColor,
      end: theme.appBarTheme.backgroundColor,
    ).animate(playerRouteController);
    final appBar = Material(
      elevation: 2.0,
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: appBarAnimation,
        builder: (context, child) => PlayerInterfaceColorWidget(
          color: () => appBarAnimation.value,
          child: child,
        ),
        child: Container(
          height: appBarHeight,
          margin: EdgeInsets.only(top: topScreenPadding),
          padding: const EdgeInsets.only(
            top: 24.0,
            bottom: 0.0,
          ),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: _handleTitleTap,
                child: AnimationSwitcher(
                  animation: CurvedAnimation(
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                    parent: widget.selectionController.animation,
                  ),
                  child2: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10.0,
                      left: 42.0,
                      right: 12.0,
                    ),
                    child: Row(
                      children: [
                        SelectionCounter(controller: widget.selectionController),
                        const Spacer(),
                        SelectAllSelectionAction<Song>(
                          controller: widget.selectionController,
                          entryFactory: (content, index) => SelectionEntry<Song>.fromContent(
                            content: content,
                            index: index,
                            context: context,
                          ),
                          getAll: () => QueueControl.instance.state.current.songs,
                        ),
                      ],
                    ),
                  ),
                  child1: Padding(
                    padding: EdgeInsets.only(
                      left: origin != null ? 12.0 : 20.0,
                      right: 12.0,
                    ),
                    child: Row(
                      children: [
                        if (origin != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, right: 10.0),
                            child: ContentArt(
                              source: ContentArtSource.origin(origin),
                              borderRadius: _getBorderRadius(origin),
                              size: kSongTileArtSize - 8.0,
                            ),
                          ),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: [
                                  Text(
                                    l10n.upNext,
                                    style: theme.textTheme.titleLarge!.copyWith(
                                      fontSize: 24,
                                      height: 1.2,
                                    ),
                                  ),
                                  _crossFade(
                                    !QueueControl.instance.state.modified,
                                    const SizedBox(height: 18.0),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 18.0,
                                      ),
                                    ),
                                  ),
                                  _crossFade(
                                    !QueueControl.instance.state.shuffled,
                                    const SizedBox(height: 20.0),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 2.0),
                                      child: Icon(
                                        Icons.shuffle_rounded,
                                        size: 20.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: AnimatedSwitcher(
                                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                        return Stack(
                                          alignment: Alignment.centerLeft,
                                          children: <Widget>[
                                            ...previousChildren,
                                            if (currentChild != null) currentChild,
                                          ],
                                        );
                                      },
                                      duration: const Duration(milliseconds: 400),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: _buildTitleText(l10n),
                                    ),
                                  ),
                                  if (origin != null || type == QueueType.searched)
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18.0,
                                      color: theme.textTheme.titleSmall!.color,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Column(
                          children: [
                            _SaveQueueAsPlaylistAction(),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final list = QueueControl.instance.state.current.songs;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: appBarHeightWithPadding),
            child: ValueListenableBuilder<SelectionController?>(
              valueListenable: ContentControl.instance.selectionNotifier,
              builder: (context, value, child) {
                return ContentListView(
                  contentType: ContentType.song,
                  list: list,
                  controller: scrollController,
                  selectionController: widget.selectionController,
                  padding: EdgeInsets.only(
                    top: 4.0,
                    bottom: value == null ? 0.0 : kSongTileHeight(context) + 4.0,
                  ),
                  songTileVariant:
                      QueueControl.instance.state.origin is Album ? SongTileVariant.number : SongTileVariant.albumArt,
                  songTileClickBehavior: SongTileClickBehavior.playPause,
                  currentTest: (index) => index == currentSongIndex,
                  alwaysShowScrollbar: true,
                );
              },
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

class _MainTab extends StatefulWidget {
  const _MainTab();

  @override
  _MainTabState createState() => _MainTabState();
}

class _MainTabState extends State<_MainTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fadeAnimation = CurvedAnimation(
      curve: const Interval(0.6, 1.0),
      parent: playerRouteController,
    );
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return AnimatedBuilder(
      animation: playerRouteController,
      builder: (context, child) => Scaffold(
        body: child,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          toolbarHeight: math.max(
            TrackPanel.height(context) - mediaQuery.padding.top,
            theme.appBarTheme.toolbarHeight ?? kToolbarHeight,
          ),
          leading: FadeTransition(
            opacity: fadeAnimation,
            child: RepaintBoundary(
              child: NFIconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                size: 40.0,
                onPressed: playerRouteController.close,
              ),
            ),
          ),
          actions: <Widget>[
            FadeTransition(
              opacity: fadeAnimation,
              child: Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: Prefs.devMode,
                    builder: (context, value, child) => value ? const _InfoButton() : const SizedBox.shrink(),
                  ),
                  const FavoriteButton(),
                  const SizedBox(width: 5.0),
                ],
              ),
            ),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const TrackShowcase(),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Seekbar(),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 40.0 / textScaleFactor,
                    top: 10.0,
                  ),
                  child: const _PlaybackButtons(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackButtons extends StatelessWidget {
  const _PlaybackButtons();
  static const buttonMargin = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: buttonMargin),
      child: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const ShuffleButton(),
            const SizedBox(width: buttonMargin),
            Container(
              padding: const EdgeInsets.only(right: buttonMargin),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0),
              ),
              child: NFIconButton(
                size: textScaleFactor * 50.0,
                iconSize: textScaleFactor * 30.0,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: MusicPlayer.instance.playPrev,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(100.0),
              ),
              child: const Material(
                color: Colors.transparent,
                child: AnimatedPlayPauseButton(
                  iconSize: 26.0,
                  size: 70.0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: buttonMargin),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0),
              ),
              child: NFIconButton(
                size: textScaleFactor * 50.0,
                iconSize: textScaleFactor * 30.0,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: MusicPlayer.instance.playNext,
              ),
            ),
            const SizedBox(width: buttonMargin),
            const LoopButton(),
          ],
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton();

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return NFIconButton(
      icon: const Icon(Icons.info_outline_rounded),
      size: 40.0,
      onPressed: () {
        String songInfo = PlaybackControl.instance.currentSong.toMap().toString().replaceAll(r', ', ',\n');
        // Remove curly braces
        songInfo = songInfo.substring(1, songInfo.length - 1);
        ShowFunctions.instance.showAlert(
          context,
          title: Text(
            l10n.songInformation,
            textAlign: TextAlign.center,
          ),
          contentPadding: defaultAlertContentPadding.copyWith(top: 4.0),
          content: PrimaryScrollController(
            controller: ScrollController(),
            child: Builder(
              builder: (context) {
                return AppScrollbar(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      songInfo,
                      style: const TextStyle(fontSize: 13.0),
                      selectionControls: MaterialTextSelectionControls(),
                    ),
                  ),
                );
              },
            ),
          ),
          additionalActions: [
            IntrinsicWidth(child: CopyButton(text: songInfo)),
          ],
        );
      },
    );
  }
}

/// A widget that displays all information about current song
@visibleForTesting
class TrackShowcase extends StatefulWidget {
  const TrackShowcase({super.key});

  @override
  _TrackShowcaseState createState() => _TrackShowcaseState();
}

class _TrackShowcaseState extends State<TrackShowcase> with TickerProviderStateMixin {
  late StreamSubscription<Song> _songChangeSubscription;
  late AnimationController controller;
  late AnimationController fadeController;
  Widget? art;

  static const defaultDuration = Duration(milliseconds: 160);

  /// When `true`, should use fade animation instead of scale.
  bool get useFade => playerRouteController.value == 0.0;

  OverlayEntry? artOverlayEntry;

  /// We need this so that color thief always can capture a color.
  void _insertArtOverlay(Widget child) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        _removeArtOverlayEntry();
        artOverlayEntry = OverlayEntry(
          builder: (context) => child,
        );
        AppRouter.instance.artOverlayKey.currentState!.insert(artOverlayEntry!);
      }
    });
  }

  void _removeArtOverlayEntry() {
    artOverlayEntry?.remove();
    artOverlayEntry = null;
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: defaultDuration,
    );
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    controller.addStatusListener(_handleStatus);
    _songChangeSubscription = PlaybackControl.instance.onSongChange.listen((event) async {
      if (useFade) {
        fadeController.reset();
        fadeController.forward();
      } else {
        controller.forward();
      }
      setState(() {/* update track in ui */});
    });
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      controller.reverse();
    }
  }

  @override
  void dispose() {
    _removeArtOverlayEntry();
    controller.dispose();
    fadeController.dispose();
    _songChangeSubscription.cancel();
    super.dispose();
  }

  Widget _fade(Widget child) {
    final fadeAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      parent: fadeController,
    ));
    final scaleAnimation = Tween(
      begin: 1.06,
      end: 1.0,
    ).animate(CurvedAnimation(
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeInCubic),
      parent: fadeController,
    ));
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween(
      begin: 1.0,
      end: 0.91,
    ).animate(CurvedAnimation(
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
      parent: controller,
    ));
    final currentSong = PlaybackControl.instance.currentSong;
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: NFMarquee(
            key: ValueKey(currentSong),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            alignment: Alignment.center,
            text: currentSong.title,
            fontSize: 20.0,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 2.0,
            bottom: 30.0 / textScaleFactor,
            right: 20,
            left: 20,
          ),
          child: ArtistWidget(
            artist: currentSong.artist,
            textStyle: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 60.0,
            right: 60.0,
            top: 10.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final newArt = ContentArt.playerRoute(
                  key: ValueKey(currentSong),
                  size: constraints.maxWidth,
                  loadAnimationDuration: Duration.zero,
                  source: ContentArtSource.song(currentSong),
                );
                if (art == null ||
                    controller.status == AnimationStatus.reverse ||
                    controller.status == AnimationStatus.dismissed ||
                    useFade) {
                  art = newArt;
                  _insertArtOverlay(ContentArtLoadBuilder(
                    builder: (onLoad) => ContentArt.playerRoute(
                      key: ValueKey(currentSong),
                      size: constraints.maxWidth,
                      loadAnimationDuration: Duration.zero,
                      source: ContentArtSource.song(currentSong),
                      onLoad: onLoad,
                    ),
                  ));
                }

                return ScaleTransition(
                  scale: animation,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: useFade ? 0.0 : 1.0,
                        child: newArt,
                      ),
                      _fade(art!),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveQueueAsPlaylistAction extends StatefulWidget {
  const _SaveQueueAsPlaylistAction();

  @override
  State<_SaveQueueAsPlaylistAction> createState() => _SaveQueueAsPlaylistActionState();
}

class _SaveQueueAsPlaylistActionState extends State<_SaveQueueAsPlaylistAction> with TickerProviderStateMixin {
  Future<void> _handleTap() async {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final songs = QueueControl.instance.state.current.songs;
    final playlist = await ShowFunctions.instance.showCreatePlaylist(this, context);

    if (playlist != null) {
      bool success = false;
      try {
        await ContentControl.instance.insertSongsInPlaylist(
          index: 0,
          songs: songs,
          playlist: playlist,
        );
        success = true;
      } catch (ex, stack) {
        FirebaseCrashlytics.instance.recordError(
          ex,
          stack,
          reason: 'in _SaveQueueAsPlaylistActionState',
        );
      } finally {
        if (success) {
          final key = GlobalKey<NFSnackbarEntryState>();
          NFSnackbarController.showSnackbar(NFSnackbarEntry(
            globalKey: key,
            important: true,
            child: NFSnackbar(
              leading: Icon(Icons.done_rounded, color: theme.colorScheme.onPrimary),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 0.0,
                bottom: 0.0,
              ),
              title: Text(l10n.saved, style: TextStyle(fontSize: 15.0, color: theme.colorScheme.onPrimary)),
              trailing: AppButton(
                text: l10n.view,
                horizontalPadding: 20.0,
                onPressed: () {
                  key.currentState!.close();
                  HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
                },
              ),
            ),
          ));
        } else {
          NFSnackbarController.showSnackbar(NFSnackbarEntry(
            important: true,
            child: NFSnackbar(
              leading: Icon(Icons.error_outline_rounded, color: theme.colorScheme.onError),
              title: Text(l10n.oopsErrorOccurred, style: TextStyle(fontSize: 15.0, color: theme.colorScheme.onError)),
              color: theme.colorScheme.error,
            ),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return NFIconButton(
      icon: const Icon(Icons.queue_rounded),
      iconSize: 23.0,
      tooltip: l10n.saveQueueAsPlaylist,
      onPressed: _handleTap,
    );
  }
}
