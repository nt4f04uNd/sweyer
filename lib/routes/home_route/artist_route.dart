/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:math' as math;

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
    selectionController = ContentSelectionController.create(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      context: context,
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
    // ThemeData.estimateBrightnessForColor(color);
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
          child: RepaintBoundary(
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
                                color: Constants.Theme.contrast.auto,
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
                      ContentControl.setOriginQueue(
                        origin: widget.artist,
                        songs: songs,
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
                      ContentControl.setOriginQueue(origin: widget.artist, songs: songs);
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
    // return const ImageColors(
    //     title: 'Image Colors',
    //     image: NetworkImage('https://is3-ssl.mzstatic.com/image/thumb/Music123/v4/94/70/f9/9470f96d-a57c-e9eb-d988-ec3014b0e4f0/888915939307_cover.jpg/400x400bb.jpeg'),
    //     imageSize: Size(256.0, 256.0),
    //   );
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
                                HomeRouter.instance.goto(HomeRoutes.factory.artistContent<Song>(widget.artist, songs));
                              },
                              contentTileTapHandler: <T extends Content>(Type t) {
                                ContentControl.setOriginQueue(
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
                                onHeaderTap: selectionController.inSelection ? null : () {
                                  HomeRouter.instance.goto(HomeRoutes.factory.artistContent<Album>(widget.artist, albums));
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
                        animation: backButtonAnimation,
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
                            child: RepaintBoundary(
                              child: Text(
                              ContentUtils.localizedArtist(widget.artist.artist, l10n),
                            ),
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

class ArtistContentRoute<T extends Content> extends StatelessWidget {
  const ArtistContentRoute({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  final ArtistContentArguments<T> arguments;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final artist = arguments.artist;
    final list = arguments.list;
    return Scaffold(
      appBar: AppBar(
        title: Text(ContentUtils.localizedArtist(artist.artist, l10n)),
        leading: const NFBackButton(),
      ),
      body: ContentSelectionControllerCreator<T>(
        builder: (context, selectionController, child) => StreamBuilder(
          stream: ContentControl.state.onSongChange,
          builder: (context, snapshot) => ContentListView<T>(
            list: list,
            selectionController: selectionController,
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
                            ContentControl.setOriginQueue(
                              origin: artist,
                              shuffled: true,
                              songs: list as List<Song>,
                            );
                          },
                          album: () {
                            final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Album>);
                            ContentControl.setQueue(
                              type: QueueType.allArtists,
                              shuffled: true,
                              songs: shuffleResult.shuffledSongs,
                              shuffleFrom: shuffleResult.songs,
                            );
                            ContentControl.setOriginQueue(
                              origin: artist,
                              shuffled: true,
                              songs: shuffleResult.songs,
                              shuffledSongs: shuffleResult.shuffledSongs,
                            );
                          },
                          playlist: () => throw UnimplementedError(),
                          artist: () => throw UnimplementedError(),
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
                            ContentControl.setOriginQueue(
                              origin: artist,
                              songs: list as List<Song>,
                            );
                          },
                          album: () {
                            final List<Song> songs = [];
                            for (final album in list as List<Album>) {
                              for (final song in album.songs) {
                                song.origin = album;
                                songs.add(song);
                              }
                            }
                            ContentControl.setOriginQueue(
                              origin: artist,
                              songs: songs,
                            );
                          },
                          playlist: () => throw UnimplementedError(),
                          artist: () => throw UnimplementedError(),
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
        ),
      ),
    );
  }
}

// /// A small square of color with an optional label.
// @immutable
// class PaletteSwatch extends StatelessWidget {
//   /// Creates a PaletteSwatch.
//   ///
//   /// If the [paletteColor] has property `isTargetColorFound` as `false`,
//   /// then the swatch will show a placeholder instead, to indicate
//   /// that there is no color.
//   const PaletteSwatch({
//     Key? key,
//     this.color,
//     this.label,
//   }) : super(key: key);

//   /// The color of the swatch.
//   final Color? color;

//   /// The optional label to display next to the swatch.
//   final String? label;

//   @override
//   Widget build(BuildContext context) {
//     // Compute the "distance" of the color swatch and the background color
//     // so that we can put a border around those color swatches that are too
//     // close to the background's saturation and lightness. We ignore hue for
//     // the comparison.
//     final HSLColor hslColor = HSLColor.fromColor(color ?? Colors.transparent);
//     final HSLColor backgroundAsHsl = HSLColor.fromColor(_kBackgroundColor);
//     final double colorDistance = math.sqrt(
//         math.pow(hslColor.saturation - backgroundAsHsl.saturation, 2.0) +
//             math.pow(hslColor.lightness - backgroundAsHsl.lightness, 2.0));

//     Widget swatch = Padding(
//       padding: const EdgeInsets.all(2.0),
//       child: color == null
//           ? const Placeholder(
//               fallbackWidth: 34.0,
//               fallbackHeight: 20.0,
//               color: Color(0xff404040),
//               strokeWidth: 2.0,
//             )
//           : Container(
//               decoration: BoxDecoration(
//                   color: color,
//                   border: Border.all(
//                     width: 1.0,
//                     color: _kPlaceholderColor,
//                     style: colorDistance < 0.2
//                         ? BorderStyle.solid
//                         : BorderStyle.none,
//                   )),
//               width: 34.0,
//               height: 20.0,
//             ),
//     );

//     if (label != null) {
//       swatch = ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 130.0, minWidth: 130.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: <Widget>[
//             swatch,
//             Container(width: 5.0),
//             Text(label!),
//           ],
//         ),
//       );
//     }
//     return swatch;
//   }
// }


// const Color _kBackgroundColor = Color(0xffa0a0a0);
// const Color _kSelectionRectangleBackground = Color(0x15000000);
// const Color _kSelectionRectangleBorder = Color(0x80000000);
// const Color _kPlaceholderColor = Color(0x80404040);

// /// The home page for this example app.
// @immutable
// class ImageColors extends StatefulWidget {
//   /// Creates the home page.
//   const ImageColors({
//     Key? key,
//     this.title,
//     required this.image,
//     this.imageSize,
//   }) : super(key: key);

//   /// The title that is shown at the top of the page.
//   final String? title;

//   /// This is the image provider that is used to load the colors from.
//   final ImageProvider image;

//   /// The dimensions of the image.
//   final Size? imageSize;

//   @override
//   _ImageColorsState createState() {
//     return _ImageColorsState();
//   }
// }

// class _ImageColorsState extends State<ImageColors> {
//   Rect? region;
//   Rect? dragRegion;
//   Offset? startDrag;
//   Offset? currentDrag;
//   PaletteGenerator? paletteGenerator;

//   final GlobalKey imageKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.imageSize != null) {
//       region = Offset.zero & widget.imageSize!;
//     }
//     _updatePaletteGenerator(region);
//   }

//   Future<void> _updatePaletteGenerator(Rect? newRegion) async {
//     paletteGenerator = 
//     setState(() {});
//   }

//   // Called when the user starts to drag
//   void _onPanDown(DragDownDetails details) {
//     final RenderBox box =
//         imageKey.currentContext!.findRenderObject()! as RenderBox;
//     final Offset localPosition = box.globalToLocal(details.globalPosition);
//     setState(() {
//       startDrag = localPosition;
//       currentDrag = localPosition;
//       dragRegion = Rect.fromPoints(localPosition, localPosition);
//     });
//   }

//   // Called as the user drags: just updates the region, not the colors.
//   void _onPanUpdate(DragUpdateDetails details) {
//     setState(() {
//       currentDrag = currentDrag! + details.delta;
//       dragRegion = Rect.fromPoints(startDrag!, currentDrag!);
//     });
//   }

//   // Called if the drag is canceled (e.g. by rotating the device or switching
//   // apps)
//   void _onPanCancel() {
//     setState(() {
//       dragRegion = null;
//       startDrag = null;
//     });
//   }

//   // Called when the drag ends. Sets the region, and updates the colors.
//   Future<void> _onPanEnd(DragEndDetails details) async {
//     final Size? imageSize = imageKey.currentContext?.size;
//     Rect? newRegion;

//     if (imageSize != null) {
//       newRegion = (Offset.zero & imageSize).intersect(dragRegion!);
//       if (newRegion.size.width < 4 && newRegion.size.width < 4) {
//         newRegion = Offset.zero & imageSize;
//       }
//     }

//     await _updatePaletteGenerator(newRegion);
//     setState(() {
//       region = newRegion;
//       dragRegion = null;
//       startDrag = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _kBackgroundColor,
//       appBar: AppBar(
//         title: Text(widget.title ?? ''),
//       ),
//       body: Column(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             // GestureDetector is used to handle the selection rectangle.
//             child: GestureDetector(
//               onPanDown: _onPanDown,
//               onPanUpdate: _onPanUpdate,
//               onPanCancel: _onPanCancel,
//               onPanEnd: _onPanEnd,
//               child: Stack(children: <Widget>[
//                 Image(
//                   key: imageKey,
//                   image: widget.image,
//                   width: widget.imageSize?.width,
//                   height: widget.imageSize?.height,
//                 ),
//                 // This is the selection rectangle.
//                 Positioned.fromRect(
//                     rect: dragRegion ?? region ?? Rect.zero,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           color: _kSelectionRectangleBackground,
//                           border: Border.all(
//                             width: 1.0,
//                             color: _kSelectionRectangleBorder,
//                             style: BorderStyle.solid,
//                           )),
//                     )),
//               ]),
//             ),
//           ),
//           // Use a FutureBuilder so that the palettes will be displayed when
//           // the palette generator is done generating its data.
//           PaletteSwatches(generator: paletteGenerator),
//         ],
//       ),
//     );
//   }
// }