/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';

final SpringDescription playerRouteSpringDescription = SpringDescription.withDampingRatio(
  mass: 0.01,
  stiffness: 30.0,
  ratio: 2.0,
);

class PlayerRoute extends StatefulWidget {
  const PlayerRoute({Key? key}) : super(key: key);

  @override
  _PlayerRouteState createState() => _PlayerRouteState();
}

class _PlayerRouteState extends State<PlayerRoute>
    with SingleTickerProviderStateMixin, SelectionHandler {
  final _queueTabKey = GlobalKey<_QueueTabState>();
  late List<Widget> _tabs;
  late SlidableController controller;
  late SharedAxisTabController tabController;
  late ContentSelectionController<SelectionEntry<Song>> selectionController;

  Animation? _queueTabAnimation;
  SlideDirection slideDirection = SlideDirection.up;

  @override
  void initState() {
    super.initState();
    selectionController = ContentSelectionController.create<Song>(
      this,
      counter: true,
      closeButton: true,
    )
      ..addListener(handleSelection)
      ..addStatusListener(handleSelectionStatus);
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
    selectionController.dispose();
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
    final systemNavigationBarColorTween = ColorTween(
      begin: Constants.UiTheme.grey.auto.systemNavigationBarColor,
      end: Constants.UiTheme.black.auto.systemNavigationBarColor,
    );
    // Change system UI on expanding/collapsing the player route.
    SystemUiStyleController.setSystemUiOverlay(
      SystemUiStyleController.lastUi.copyWith(
        systemNavigationBarColor: systemNavigationBarColorTween.evaluate(controller),
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
    final backgroundColor = ThemeControl.theme.colorScheme.background;
    return Slidable(
      controller: controller,
      start: 1.0 - kSongTileHeight / screenHeight,
      end: 0.0,
      direction: slideDirection,
      barrier: Container(
        color: ThemeControl.isDark ? Colors.black : Colors.black26,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        body: Stack(
          children: <Widget>[
            SharedAxisTabView(
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
            TrackPanel(
              onTap: controller.open,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends StatefulWidget {
  _QueueTab({
    Key? key,
    required this.selectionController,
  }) : super(key: key);

  final ContentSelectionController<SelectionEntry<Content>> selectionController;

  @override
  _QueueTabState createState() => _QueueTabState();
}

class _QueueTabState extends State<_QueueTab> with SelectionHandler {

  static const double appBarHeight = 81.0;

  /// This is set in parent via global key
  bool opened = false;
  final ScrollController scrollController = ScrollController();

  /// A bool var to disable show/hide in tracklist controller listener when manual [scrollToSong] is performing
  late StreamSubscription<Song> _songChangeSubscription;
  late StreamSubscription<void> _contentChangeSubscription;

  QueueType get type => ContentControl.state.queues.type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      jumpToSong(ContentControl.state.currentSongIndex);
    });

    widget.selectionController.addListener(handleSelection);

    _contentChangeSubscription = ContentControl.state.onContentChange.listen((event) async {
      if (ContentControl.state.allSongs.isNotEmpty) {
        setState(() {/* update ui list as data list may have changed */});
        if (!opened) {
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
            // Jump when tracklist changes (e.g. shuffle happened)
            jumpToSong();
            // Post framing it because we need to be sure that list gets updated before we jump.
          });
        }
      }
    });
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) async {
      setState(() {
        /* update current track indicator */
      });
      if (!opened) {
        // Scroll when track changes
        await scrollToSong();
      }
    });
  }

  @override
  void dispose() {
    widget.selectionController.removeListener(handleSelection);
    _contentChangeSubscription.cancel();
    _songChangeSubscription.cancel();
    super.dispose();
  }

  /// Scrolls to current song.
  ///
  /// If optional [index] is provided - scrolls to it.
  Future<void> scrollToSong([int? index]) async {
    index ??= ContentControl.state.currentSongIndex;
    final extent = index * kSongTileHeight;
    final pixels = scrollController.position.pixels;
    final min = scrollController.position.minScrollExtent;
    final max = scrollController.position.maxScrollExtent;
    final delta = (extent - pixels).abs();
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
    index ??= ContentControl.state.currentSongIndex;
    final min = scrollController.position.minScrollExtent;
    final max = scrollController.position.maxScrollExtent;
    scrollController.jumpTo((index * kSongTileHeight).clamp(min, max));
  }

  /// Jump to song when changing tab to main.
  void jumpOnTabChange() {
    jumpToSong();
  }

  void _handleTitleTap() {
    switch (type) {
      case QueueType.searched:
        final query = ContentControl.state.queues.searchQuery!;
        ShowFunctions.instance.showSongsSearch(
          query: query,
          openKeyboard: false,
        );
        SearchHistory.instance.add(query);
        return;
      case QueueType.origin:
        final origin = ContentControl.state.queues.origin!;
        if (origin is Album)
          HomeRouter.instance.goto(HomeRoutes.factory.content<Album>(origin));
        else if (origin is Playlist)
          HomeRouter.instance.goto(HomeRoutes.factory.content<Playlist>(origin));
        else if (origin is Artist)
          HomeRouter.instance.goto(HomeRoutes.factory.content<Artist>(origin));
        else
          throw StateError('');
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
    if (origin is PersistentQueue)
      return 8.0;
    else if (origin is Artist)
      return kArtistTileArtSize;
    throw UnimplementedError();
  }

  List<TextSpan> _getQueueType(AppLocalizations l10n) {
    final List<TextSpan> text = [];
    switch (ContentControl.state.queues.type) {
      case QueueType.allSongs:
        text.add(TextSpan(text: l10n.allTracks));
        break;
      case QueueType.allAlbums:
        text.add(TextSpan(text: l10n.allAlbums));
        break;
      case QueueType.allPlaylists:
        text.add(TextSpan(text: l10n.allPlaylists));
        break;
      case QueueType.allArtists:
        text.add(TextSpan(text: l10n.allArtists));
        break;
      case QueueType.searched:
        final query = ContentControl.state.queues.searchQuery!;
        text.add(TextSpan(
          text: '${l10n.found} ${l10n.byQuery.toLowerCase()} ',
        ));
        text.add(TextSpan(
          text: '"$query"',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: ThemeControl.theme.colorScheme.onBackground,
          ),
        ));
        break;
      case QueueType.origin:
        final origin = ContentControl.state.queues.origin!;
        if (origin is Album) {
          text.add(TextSpan(text: '${l10n.album} '));
          text.add(TextSpan(
            text: origin.nameDotYear,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ThemeControl.theme.colorScheme.onBackground,
            ),
          ));
        } else if (origin is Playlist) {
          text.add(TextSpan(text: '${l10n.playlist} '));
          text.add(TextSpan(
            text: origin.name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ThemeControl.theme.colorScheme.onBackground,
            ),
          ));
        } else if (origin is Artist) {
          text.add(TextSpan(text: '${l10n.artist} '));
          text.add(TextSpan(
            text: origin.artist,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ThemeControl.theme.colorScheme.onBackground,
            ),
          ));
        } else {
          throw StateError('');
        }
        break;
      case QueueType.arbitrary:
        text.add(TextSpan(text:
          l10n.arbitraryQueueOrigin(ContentControl.state.queues.arbitraryQueueOrigin)
            ?? l10n.arbitraryQueue,
        ));
        break;
    }
    return text;
  }

  Text _buildTitleText(List<TextSpan> text) {
    return Text.rich(
      TextSpan(children: text),
      overflow: TextOverflow.ellipsis,
      style: ThemeControl.theme.textTheme.subtitle2!.copyWith(
        fontSize: 14.0,
        height: 1.0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSongIndex = ContentControl.state.currentSongIndex;
    final l10n = getl10n(context);
    final origin = ContentControl.state.queues.origin;
    final horizontalPadding = origin is Album ? 12.0 : 20.0;
    final topScreenPadding = MediaQuery.of(context).padding.top;
    final appBarHeightWithPadding = appBarHeight + topScreenPadding;
    final fadeAnimation = CurvedAnimation(
      curve: const Interval(0.6, 1.0),
      parent: playerRouteController,
    );
    final appBar = Material(
      elevation: 2.0,
      color: ThemeControl.theme.appBarTheme.color,
      child: Container(
        height: appBarHeight,
        margin: EdgeInsets.only(top: topScreenPadding),
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: 24.0,
          bottom: 0.0,
        ),
        child: FadeTransition(
          opacity: fadeAnimation,
          child: GestureDetector(
            onTap: _handleTitleTap,
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
                            style: ThemeControl.theme.textTheme.headline6!.copyWith(
                              fontSize: 24,
                              height: 1.2,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeInCubic,
                            child: !ContentControl.state.queues.modified
                                ? const SizedBox.shrink()
                                : const Padding(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 18.0,
                                    ),
                                  ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeInCubic,
                            child: !ContentControl.state.queues.shuffled
                                ? const SizedBox.shrink()
                                : const Padding(
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
                          Flexible(child: _buildTitleText(_getQueueType(l10n))),
                          if (origin != null || type == QueueType.searched)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18.0,
                              color: ThemeControl.theme.textTheme.subtitle2!.color,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final list = ContentControl.state.queues.current.songs;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: appBarHeightWithPadding),
            child: ValueListenableBuilder<SelectionController?>(
              valueListenable: ContentControl.state.selectionNotifier,
              builder: (context, value, child) {
                return ContentListView<Song>(
                  list: list,
                  controller: scrollController,
                  selectionController: widget.selectionController,
                  padding: EdgeInsets.only(
                    top: 4.0,
                    bottom: value == null ? 0.0 : kSongTileHeight + 4.0,
                  ),
                  songTileVariant: ContentControl.state.queues.origin is Album
                    ? SongTileVariant.number
                    : SongTileVariant.albumArt,
                  songClickBehavior: SongClickBehavior.playPause,
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
  const _MainTab({Key? key}) : super(key: key);

  @override
  _MainTabState createState() => _MainTabState();
}

class _MainTabState extends State<_MainTab> {
  @override
  Widget build(BuildContext context) {
    final animation = ColorTween(
      begin: ThemeControl.theme.colorScheme.secondary,
      end: ThemeControl.theme.colorScheme.background,
    ).animate(playerRouteController);
    final fadeAnimation = CurvedAnimation(
      curve: const Interval(0.6, 1.0),
      parent: playerRouteController,
    );
    return AnimatedBuilder(
      animation: playerRouteController,
      builder: (context, child) => Scaffold(
        body: child,
        resizeToAvoidBottomInset: false,
        backgroundColor: animation.value,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          leading: FadeTransition(
            opacity: fadeAnimation,
            child: NFIconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              size: 40.0,
              onPressed: playerRouteController.close,
            ),
          ),
          actions: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: ContentControl.devMode,
              builder: (context, value, child) => value
                ? child!
                : const SizedBox.shrink(),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: const _InfoButton(),
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
            const _TrackShowcase(),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Seekbar(),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 40.0,
                    top: 10.0,
                  ),
                  child: _PlaybackButtons(),
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
  const _PlaybackButtons({Key? key}) : super(key: key);
  static const buttonMargin = 18.0;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Row(
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
            size: 50.0,
            iconSize: textScaleFactor * 30.0,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: MusicPlayer.instance.playPrev,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ThemeControl.theme.colorScheme.secondary,
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
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: NFIconButton(
        icon: const Icon(Icons.info_outline_rounded),
        size: 40.0,
        onPressed: () {
          String songInfo = ContentControl.state.currentSong
            .toMap()
            .toString()
            .replaceAll(r', ', ',\n');
          // Remove curly braces
          songInfo = songInfo.substring(1, songInfo.length - 1);
          ShowFunctions.instance.showAlert(
            context,
            title: Text(
              l10n.songInformation,
              textAlign: TextAlign.center,
            ),
            contentPadding: defaultAlertContentPadding.copyWith(top: 4.0),
            content: SelectableText(
              songInfo,
              style: const TextStyle(fontSize: 13.0),
              selectionControls: NFTextSelectionControls(
                backgroundColor: ThemeControl.theme.colorScheme.background,
              ),
            ),
            additionalActions: [
              NFCopyButton(text: songInfo),
            ],
          );
        },
      ),
    );
  }
}

/// A widget that displays all information about current song
class _TrackShowcase extends StatefulWidget {
  const _TrackShowcase({Key? key}) : super(key: key);

  @override
  _TrackShowcaseState createState() => _TrackShowcaseState();
}

class _TrackShowcaseState extends State<_TrackShowcase> {
  late StreamSubscription<Song> _songChangeSubscription;

  @override
  void initState() {
    super.initState();
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) async {
      setState(() {/* update track in ui */});
    });
  }

  @override
  void dispose() {
    _songChangeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ContentControl.state.currentSong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: NFMarquee(
            key: ValueKey(ContentControl.state.currentSong.id),
            fontWeight: FontWeight.w900,
            text: currentSong.title,
            fontSize: 20.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2.0, bottom: 30.0),
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
            builder: (context, constraints) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) {

                // TODO: play more with this
                final Animation<double> scaleAnimation;
                final Animation<double> fadeAnimation;
                // final fadeAnimation = ConstantTween(1.0).animate(animation);
                if (ValueKey(currentSong) == child.key) {
                  scaleAnimation = Tween(
                    begin: 1.2,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                    parent: animation,
                  ));
                  fadeAnimation = fadeAnimation = Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                    reverseCurve:const Interval(0.4, 1.0, curve: Curves.easeIn),
                    parent: animation,
                  ));
                } else {
                  fadeAnimation = Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                    reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                    parent: animation,
                  ));
                  scaleAnimation = Tween(
                    begin: 0.84,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    curve: Curves.easeOut,
                    reverseCurve: Curves.easeIn,
                    parent: animation,
                  ));
                }

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: ContentArt.playerRoute(
                key: ValueKey(currentSong),
                size: constraints.maxWidth,
                source: ContentArtSource.song(currentSong),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
