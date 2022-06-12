import 'dart:async';
// import 'dart:ui' as ui;
import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class ArtistRoute extends StatefulWidget {
  ArtistRoute({Key? key, required this.artist}) : super(key: key);

  final Artist artist;

  @override
  _ArtistRouteState createState() => _ArtistRouteState();
}

class _ArtistRouteState extends State<ArtistRoute> with TickerProviderStateMixin, SelectionHandlerMixin {
  final ScrollController scrollController = ScrollController();
  late AnimationController appBarController;
  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonAnimation;
  late List<Song> songs;
  late List<Album> albums;
  late StreamSubscription<void> _contentChangeSubscription;

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
    _updateContent(false);
    appBarController = AnimationController(
      vsync: this,
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

    initSelectionController(() => ContentSelectionController.create(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      context: context,
      closeButton: true,
      ignoreWhen: () => playerRouteController.opened,
    ));
  
    _contentChangeSubscription = ContentControl.instance.onContentChange.listen(_handleContentChange);
  }

  @override
  void dispose() {
    _contentChangeSubscription.cancel();
    disposeSelectionController();
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

   void _handleContentChange(void event) {
    setState(() {
      _updateContent();
    });
  }

  void _updateContent([bool postFrame = false]) {
    songs = widget.artist.songs;
    albums = widget.artist.albums;
    if (songs.isEmpty && albums.isEmpty) {
      if (postFrame) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            _quitBecauseNotFound();
          }
        });
      } else {
        _quitBecauseNotFound();
      }
    }
  }

  void _quitBecauseNotFound() {
    ContentControl.instance.refetchAll();
    final l10n = getl10n(context);
    ShowFunctions.instance.showToast(msg: l10n.artistNotFound);
    Navigator.of(context).pop();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / _artScrollExtent;
    // ThemeData.estimateBrightnessForColor(color);
    if (1.0 - appBarController.value > 0.5) {
      backButtonAnimationController.forward();
    } else {
      backButtonAnimationController.reverse();
    }
  }

  PaletteGenerator? palette;
  static Future<PaletteGenerator> _isolate(image) => createPalette(image);

  Widget _buildInfo() {
    final l10n = getl10n(context);
    final theme = ThemeControl.instance.theme;
    final artSize = mediaQuery.size.width;
    final summary = ContentUtils.joinDot([
      l10n.contentsPlural<Song>(songs.length),
      if (albums.isNotEmpty)
        l10n.contentsPlural<Album>(albums.length),
      ContentUtils.bulkDuration(songs),
    ]);
    return Column(
      children: [
        FadeTransition(
          opacity: appBarController,
          child: RepaintBoundary(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    ContentArt(
                      assetHighRes: true,
                      size: artSize,
                      borderRadius: 0.0,
                      defaultArtIcon: Artist.icon,
                      defaultArtIconScale: 4.5,
                      // onLoad: (image) async {
                        // palette = await compute<ui.Image, PaletteGenerator>(_isolate, image);
                        // palette = await _isolate(image);
                        // if (mounted) {
                        //   WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                        //     if (mounted) {
                        //       setState(() {});
                        //       _debugOverlay = DebugOverlay(
                        //         (context) => PaletteSwatches(generator: palette),
                        //       );
                        //     }
                        //   });
                        // }
                      // },
                      source: ContentArtSource.artist(widget.artist),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.background.withOpacity(0.0), theme.colorScheme.background],
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
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                      QueueControl.instance.setOriginQueue(
                        origin: widget.artist,
                        songs: songs,
                        shuffled: true,
                      );
                      MusicPlayer.instance.setSong(QueueControl.instance.state.current.songs[0]);
                      MusicPlayer.instance.play();
                      playerRouteController.open();
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: PlayQueueButton(
                    onPressed: () {
                      QueueControl.instance.setOriginQueue(origin: widget.artist, songs: songs);
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
    final theme = ThemeControl.instance.theme;
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
              stream: PlaybackControl.instance.onSongChange,
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
                              onHeaderTap: selectionController.inSelection && !selectionRoute || songs.length <= 5 ? null : () {
                                HomeRouter.of(context).goto(HomeRoutes.factory.artistContent<Song>(widget.artist, songs));
                              },
                              contentTileTapHandler: () {
                                QueueControl.instance.setOriginQueue(
                                  origin: widget.artist,
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
                                onHeaderTap: selectionController.inSelection && !selectionRoute ? null : () {
                                  HomeRouter.of(context).goto(HomeRoutes.factory.artistContent<Album>(widget.artist, albums));
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
                                        selectionIndex: index,
                                        selected: selectionController.data
                                          .firstWhereOrNull((el) => el.data == albums[index]) != null,
                                        selectionController: selectionController,
                                        grid: true,
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
                        animation: backButtonAnimation,
                        builder: (context, child) {
                          final colorAnimation = ColorTween(
                            begin: Colors.white,
                            end: theme.iconTheme.color,
                          ).animate(backButtonAnimation);

                          final splashColorAnimation = ColorTween(
                            begin: Constants.Theme.glowSplashColorOnContrast.auto,
                            end: theme.splashColor,
                          ).animate(backButtonAnimation);

                          return NFIconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: colorAnimation.value,
                            splashColor: splashColorAnimation.value,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                      builder: (context, child) => SizedBox(
                        height: _fullAppBarHeight,
                        child: AppBar(
                          elevation: 0.0,
                          leading: child,
                          automaticallyImplyLeading: false,
                          titleSpacing: 0.0,
                          backgroundColor: appBarController.isDismissed
                            ? theme.colorScheme.background
                            : theme.colorScheme.background.withOpacity(0.0),
                          title: AnimationSwitcher(
                            animation: CurvedAnimation(
                              curve: Curves.easeOutCubic,
                              reverseCurve: Curves.easeInCubic,
                              parent: selectionController.animation,
                            ),
                            child1: AnimatedOpacity(
                              opacity: _appBarTitleVisible
                                ? 1.0
                                : 0.0,
                              curve: Curves.easeOut,
                              duration: const Duration(milliseconds: 400),
                              child: RepaintBoundary(
                                child: Text(
                                  ContentUtils.localizedArtist(widget.artist.artist, l10n),
                                ),
                              ),
                            ),
                            child2: SelectionCounter(controller: selectionController),
                          ),
                          actions: const [],
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
