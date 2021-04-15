/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class AlbumRoute extends StatefulWidget {
  AlbumRoute({Key key, @required this.album})
      : assert(album != null),
        super(key: key);

  final Album album;

  @override
  _AlbumRouteState createState() => _AlbumRouteState();
}

class _AlbumRouteState extends State<AlbumRoute> with TickerProviderStateMixin, SelectionHandler {
  final ScrollController scrollController = ScrollController();
  AnimationController appBarController;
  ContentSelectionController<SelectionEntry<Song>> selectionController;
  List<Song> songs;

  static const _appBarHeight = kNFAppBarPreferredSize - 8.0;
  static const _albumArtSize = 130.0;
  static const _albumSectionTopPadding = 10.0;
  static const _albumSectionBottomPadding = 24.0;
  static const _albumSectionHeight = _albumArtSize + _albumSectionTopPadding + _albumSectionBottomPadding;

  static const _buttonSectionButtonHeight = 38.0;
  static const _buttonSectionBottomPadding = 12.0;
  static const _buttonSectionHeight = _buttonSectionButtonHeight + _buttonSectionBottomPadding;

  /// Amount of pixels user always can scroll.
  static const _alwaysCanScrollExtent = _albumSectionHeight + _buttonSectionHeight;

  @override
  void initState() {
    super.initState();
    songs = widget.album.songs;
    appBarController = AnimationController(vsync: this, value: 1.0);
    scrollController.addListener(_handleScroll);
    selectionController = ContentSelectionController.forContent<Song>(
      this,
      closeButton: true,
      counter: true,
    )
      ..addListener(handleSelection)
      ..addStatusListener(handleSelectionStatus);
  }

  @override
  void dispose() {
    selectionController.dispose();
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / _albumSectionHeight;
  }

  Widget _buildAlbumInfo() {
    final l10n = getl10n(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 13.0,
        right: 10.0,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: appBarController,
            child: Container(
              padding: const EdgeInsets.only(
                top: _albumSectionTopPadding,
                bottom: _albumSectionBottomPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AlbumArt(
                    size: 130.0,
                    highRes: true,
                    assetScale: 1.4,
                    path: widget.album.albumArt,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.album.album,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              fontSize: 24.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                            ),
                            child: ArtistWidget(
                              artist: widget.album.artist,
                              overflow: TextOverflow.clip,
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.0,
                                color: ThemeControl.theme.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Text(
                            '${l10n.album} • ${widget.album.year}',
                            style: TextStyle(
                              color: ThemeControl.theme.textTheme.subtitle2.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: _buttonSectionBottomPadding),
            child: SizedBox(
              height: _buttonSectionButtonHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _AlbumPlayButton(
                      text: l10n.shuffleContentList,
                      icon: const Icon(Icons.shuffle_rounded, size: 22.0),
                      color: Constants.Theme.contrast.auto,
                      textColor: ThemeControl.theme.colorScheme.background,
                      splashColor: Constants.Theme.glowSplashColorOnContrast.auto,
                      onPressed: () {
                         ContentControl.setPersistentQueue(
                          queue: widget.album,
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
                    child: _AlbumPlayButton(
                      text: l10n.playContentList,
                      icon: const Icon(Icons.play_arrow_rounded, size: 28.0),
                      onPressed: () {
                        ContentControl.setPersistentQueue(queue: widget.album, songs: songs);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.theme;
  
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // TODO: add comment how this is working
          final height = constraints.maxHeight -
            _appBarHeight -
            kSongTileHeight * songs.length -
            AppBarBorder.height -
            MediaQuery.of(context).padding.top;

          return ScrollConfiguration(
            behavior: const GlowlessScrollBehavior(),
            child: StreamBuilder(
              stream: ContentControl.state.onSongChange,
              builder: (context, snapshot) => CustomScrollView(
                controller: scrollController,
                slivers: [
                  AnimatedBuilder(
                    animation: appBarController,
                    child: NFBackButton(
                      onPressed: () {
                        selectionController.close();
                        Navigator.of(context).pop();
                      },
                    ),
                    builder: (context, child) => SliverAppBar(
                      pinned: true,
                      elevation: 0.0,
                      automaticallyImplyLeading: false,
                      toolbarHeight: _appBarHeight,
                      leading: child,
                      titleSpacing: 0.0,
                      backgroundColor: appBarController.isDismissed
                          ? theme.colorScheme.background
                          : theme.colorScheme.background.withOpacity(0.0),
                      title: AnimatedOpacity(
                        opacity: 1.0 - appBarController.value > 0.35
                          ? 1.0
                          : 0.0,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 400),
                        child: Text(widget.album.album),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: IgnoreInSelection(
                      controller: selectionController,
                      child: _buildAlbumInfo()
                    ),
                  ),

                  SliverStickyHeader(
                    overlapsContent: false,
                    header: AnimatedBuilder(
                      animation: appBarController,
                      builder: (context, child) => AppBarBorder(
                        shown: scrollController.offset > _alwaysCanScrollExtent,
                      ),
                    ),
                    sliver: ContentListView.sliver<Song>(
                      list: songs,
                      selectionController: selectionController,
                      // TODO: leading: leading,
                      currentTest: (index) => ContentControl.state.queues.persistent == widget.album &&
                                    songs[index].sourceId == ContentControl.state.currentSong.sourceId,
                      songTileVariant: SongTileVariant.number,
                      onItemTap: () => ContentControl.setPersistentQueue(
                        queue: widget.album,
                        songs: songs,
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: height <= 0
                      ? const SizedBox.shrink()
                      : Container(height: height),
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

/// A button with text and icon.
class _AlbumPlayButton extends StatelessWidget {
  const _AlbumPlayButton({
    Key key,
    @required this.text,
    @required this.icon,
    @required this.onPressed,
    this.color,
    this.textColor,
    this.splashColor,
  }) : super(key: key);

  final String text;
  final Icon icon;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final Color splashColor;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeControl.theme.copyWith(
        splashFactory: NFListTileInkRipple.splashFactory,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        // ignore: missing_required_param
        style: const ElevatedButton().defaultStyleOf(context).copyWith(
          backgroundColor: MaterialStateProperty.all(color),
          foregroundColor: MaterialStateProperty.all(textColor),
          overlayColor: MaterialStateProperty.resolveWith((_) => splashColor ?? Constants.Theme.glowSplashColor.auto),
          splashFactory: NFListTileInkRipple.splashFactory,
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          textStyle: MaterialStateProperty.resolveWith((_) => TextStyle(
            fontFamily: ThemeControl.theme.textTheme.headline1.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.0,
          )),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 1.0),
              child: Text(text),
            ),
            const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }
}