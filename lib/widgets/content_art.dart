/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

const double kSongTileArtSize = 48.0;
const double kPersistentQueueTileArtSize = 64.0;
const double kArtistTileArtSize = 64.0;
const double kArtBorderRadius = 10.0;

/// `3` is the [CircularPercentIndicator.lineWidth] doubled and additional 3 spacing
///
/// `2` is border width
const double kRotatingArtSize = kSongTileArtSize - 6 - 3 - 2;

/// Used for loading some large arts which should be emphasized.
/// For example main content art in album or artist route.
///
/// Used by default [ContentArt] constructor.
const Duration kArtLoadAnimationDuration = Duration(milliseconds: 240);

/// Used for loading arts in lists.
const Duration kArtListLoadAnimationDuration = Duration(milliseconds: 200);

/// Whether to use bytes to load album arts from `MediaStore`.
bool get _useBytes => ContentControl.sdkInt >= 29;

/// Source to load an [ContentArt].
class ContentArtSource {
  /// Creates art for song.
  const ContentArtSource.song(Song song)
    : _content = song;

  const ContentArtSource.album(Album album)
    : _content = album;
  
  const ContentArtSource.playlist(Playlist playlist)
    : _content = playlist;

  /// Checks the kind of [PersistentQueue], and respectively either picks [ContentArtSource.album], or [ContentArtSource.playlist].
  const ContentArtSource.persistentQueue(PersistentQueue persistentQueue)
    : assert(persistentQueue is Album || persistentQueue is Playlist),
      _content = persistentQueue;

  const ContentArtSource.artist(Artist artist)
    : _content = artist;

  final Content _content;
}

/// Image that represents the content art.
/// It can be an album art, placeholder, or some other image.
///
/// How arts are displayed:
/// * [ContentArtSource.song] - just the song art 
/// * [ContentArtSource.album] - the art of the first song in album
/// * [ContentArtSource.playlist] - grid of 4 arts, when playlist length is:
///    * 1 - 4 identical arts
///    * 2 - two arts in the first row, and same two arts on the second, though reversed
///    * 3 - arts of 3 songs, and the last one is of the first song
///    * 4 - just 4 arts of 4 songs
/// 
/// See also:
/// * [_ArtLoader], which loads arts from `MediaStore`
class ContentArt extends StatefulWidget {
  const ContentArt({
    Key? key,
    required this.source,
    this.color,
    this.size,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.highRes = false,
    this.currentIndicatorScale,
    this.loadAnimationDuration = kArtLoadAnimationDuration,
  }) : super(key: key);

  /// Creates an art for the [SongTile] or [SelectableSongTile].
  const ContentArt.songTile({
    Key? key,
    required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  }) : size = kSongTileArtSize,
       highRes = false,
       currentIndicatorScale = null,
       super(key: key);

  /// Creates an art for the [PersistentQueueTile].
  /// It has the same image contents scale as [AlbumArt.songTile].
  const ContentArt.persistentQueueTile({
    Key? key,
    required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  }) : size = kPersistentQueueTileArtSize,
       highRes = false,
       currentIndicatorScale = 1.17,
       super(key: key);

  /// Creates an art for the [ArtistTile].
  /// It has the same image contents scale as [AlbumArt.songTile].
  const ContentArt.artistTile({
    Key? key,
    required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtistTileArtSize,
    this.current = false,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  }) : size = kPersistentQueueTileArtSize,
       highRes = false,
       currentIndicatorScale = 1.1,
       super(key: key);

  /// Creates an art for the [PlayerRoute].
  /// Its image contents scale differs from the [AlbumArt.songTile] and [AlbumArt.PersistentQueueTile].
  const ContentArt.playerRoute({
    Key? key,
    required this.source,
    this.size,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.loadAnimationDuration = const Duration(milliseconds: 500),
  }) : current = false,
       highRes = true,
       currentIndicatorScale = null,
       super(key: key);

  final ContentArtSource? source;

  /// Background color for the album art.
  /// By default will use [ThemeControl.colorForBlend].
  final Color? color;

  /// Album art size.
  final double? size;

  /// Scale that will be applied to the asset image contents.
  final double assetScale;

  /// Album art border radius.
  /// Defaults to [kArtBorderRadius].
  final double borderRadius;

  /// Will show current indicator if true.
  /// When album art does exist, will dim it a bit and overlay the indicator.
  /// Otherwise, will replace the logo placeholder image without dimming the background.
  final bool current;

  /// Whether the album art is should be rendered with hight resolution (like it does in [AlbumArtPlayerRoute]).
  /// Defaults to `false`.
  ///
  /// This changes image placeholder contents, so size of it might be different and you probably
  /// want to change [assetScale].
  final bool highRes;

  /// SCale for the [CurrentIndicator].
  final double? currentIndicatorScale;

  /// Above Android Q and above album art loads from bytes, and performns an animation on load.
  /// This defines the duration of this animation.
  final Duration loadAnimationDuration;

  @override
  _ContentArtState createState() => _ContentArtState();
}

/// Loads local album art for a song.
///
/// Lower Android Q album arts ared displayed directly from the file path
/// of album art from [Song.albumArt].Above though, this path was deprecated due to
/// scoped storage, and now album arts should be fetched with special method in `MediaStore.loadThumbnail`.
/// The [_useBytes] indicates that we are on scoped storage and should use this
/// new method.
/// 
/// Also, sometimes below Android Q, album arts files sometimes become unaccessible,
/// even though they should not. Loader will try to restore them with [Song.albumId]
/// and [ContentChannel.fixAlbumArt].
class _ArtLoader {
  _ArtLoader({
    required this.context,
    required this.song,
    required this.size,
    required this.onUpdate,
  });

  final BuildContext context;
  final Song? song;
  final double? size;
  final VoidCallback onUpdate;

  CancellationSignal? _signal;
  Uint8List? _bytes;
  late File _file;
  bool loaded = false;
  bool _broken = false;

  bool get showDefault => _broken ? _broken : song == null ||
                          !_useBytes && song!.albumArt == null ||
                          _useBytes && loaded && _bytes == null;

  void load() {
    if (song == null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        loaded = true;
        onUpdate();
      });
    } else if (_useBytes) {
      final uri = song!.contentUri;
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        _signal = CancellationSignal();
        _bytes = await ContentChannel.loadAlbumArt(
          uri: uri,
          size: Size.square(size!) * MediaQuery.of(context).devicePixelRatio,
          signal: _signal!,
        );
        loaded = true;
        onUpdate();
      });
    } else {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        final art = song!.albumArt;
        if (art != null) {
          _file = File(art);
          final exists = _file.existsSync();
          _broken = !exists;
          if (_broken) {
            _recreateArt();
          }
        }
        loaded = true;
        onUpdate();
      });
    }
  }

  Future<void> _recreateArt() async {
    final ablumId = song!.albumId;
    if (ablumId != null) {
      await ContentChannel.fixAlbumArt(song!.albumId!);
    }
    _broken = false;
    onUpdate();
  }

  Image? getImage(int? cacheSize) {
    if (_useBytes) {
      return Image.memory(
        _bytes!,
        width: size,
        height: size,
        cacheHeight: cacheSize,
        cacheWidth: cacheSize,
        fit: BoxFit.cover,
      );
    }
    if (!showDefault) {
      return Image.file(
        _file,
        width: size,
        height: size,
        cacheHeight: cacheSize,
        cacheWidth: cacheSize,
        fit: BoxFit.cover,
      );
    }
  }

  void cancel() {
    _signal?.cancel();
  }
}

class _ContentArtState extends State<ContentArt> {
  late List<_ArtLoader> _loaders;

  bool get loaded => _loaders.isEmpty || _loaders.every((el) => el.loaded);
  bool get showDefault => _loaders.isEmpty || _loaders.every((el) => el.showDefault);

  @override
  void initState() { 
    super.initState();
    _init();
  }

  void _init() {
    final content = widget.source?._content;
    if (content == null || content is Song) {
      _loaders = [
        _ArtLoader(
          context: context,
          song: content as Song?,
          size: widget.size,
          onUpdate: _onUpdate,
        ),
      ];
    } else if (content is Album) {
      _loaders = [
        _ArtLoader(
          context: context,
          song: content.firstSong,
          size: widget.size,
          onUpdate: _onUpdate,
        ),
      ];
    } else if (content is Playlist) {
      final songs = content.songs;
      final size = _getSize(true);
      switch (songs.length) {
        case 0:
          _loaders = [
            _ArtLoader(
              context: context,
              song: null,
              size: widget.size,
              onUpdate: _onUpdate,
            ),
          ];
          break;
        case 1:
          final loader = _ArtLoader(
            context: context,
            song: songs.first,
            size: size,
            onUpdate: _onUpdate,
          );
          List.generate(4, (index) => loader);
          break;
        case 2: 
          _loaders = List.generate(2, (index) => _ArtLoader(
            context: context,
            song: songs[index],
            size: size,
            onUpdate: _onUpdate,
          ));
          _loaders.addAll(_loaders.reversed.toList());
          break;
        case 3:
          _loaders = List.generate(3, (index) => _ArtLoader(
            context: context,
            song: songs[index],
            size: size,
            onUpdate: _onUpdate,
          ));
          _loaders.add(_loaders[0]);
          break;
        case 4:
          _loaders = List.generate(4, (index) => _ArtLoader(
            context: context,
            song: songs[index],
            size: size,
            onUpdate: _onUpdate,
          ));
          break;
      }
    } else if (content is Artist) {
      _loaders = [
        _ArtLoader(
          context: context,
          song: null,
          size: widget.size,
          onUpdate: _onUpdate,
        ),
      ];
    }
    for (final loader in _loaders) {
      loader.load();
    }
  }

  void _onUpdate() {
    if (mounted) {
      setState(() { });
    }
  }

  @override
  void didUpdateWidget(covariant ContentArt oldWidget) {
    if (oldWidget.source?._content != widget.source?._content) {
      _init();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() { 
    for (final loader in _loaders) {
      loader.cancel();
    }
    super.dispose();
  }

  /// Returns a size for image.
  double? _getSize([bool forPlaylist = false]) {
    return forPlaylist && widget.size != null
      ? widget.size! / 2
      : widget.size;
  }

  /// Returns a cache size for image.
  int? _getCacheSize([bool forPlaylist = false, double? size]) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio.round();
    size ??= _getSize(forPlaylist);
    return (size == null ? size : size * devicePixelRatio)?.round();
  }

  Widget _buildCurrentIndicator() {
    return widget.currentIndicatorScale == null
        ? const CurrentIndicator()
        : Transform.scale(
            scale: widget.currentIndicatorScale!,
            child: const CurrentIndicator(),
          );
  }

  Widget _buildDefault([bool forPlaylist = false, int? cacheSize]) {
    final size = _getSize(forPlaylist);
    cacheSize ??= _getCacheSize(forPlaylist, size);
    final int? _cacheSize = (
      cacheSize == null
      ? cacheSize
      : cacheSize * widget.assetScale
    )?.round();
    Widget child = Image.asset(
      widget.highRes
          ? Constants.Assets.ASSET_LOGO_MASK
          : Constants.Assets.ASSET_LOGO_THUMB_INAPP,
      width: size,
      height: size,
      cacheWidth: _cacheSize,
      cacheHeight: _cacheSize,
      color: widget.color != null
          ? getColorForBlend(widget.color!)
          : ThemeControl.colorForBlend,
      colorBlendMode: BlendMode.plus,
      fit: BoxFit.cover,
    );
    if (widget.assetScale != 1.0) {
      child = Transform.scale(scale: widget.assetScale, child: child);
      if (forPlaylist) {
        child = ClipRRect(child: child);
      }
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    assert(_loaders.isEmpty || _loaders.length == 1 || _loaders.length == 4);
    Widget child;
    Widget? currentIndicator;
    if (!loaded) {
      child = SizedBox(
        width: widget.size,
        height: widget.size,
      );
      if (widget.current) {
        currentIndicator = Container(
          alignment: Alignment.center,
          width: widget.size,
          height: widget.size,
          child: _buildCurrentIndicator(),
        );
      }
    } else if (showDefault) {
      if (widget.current) {
        child = Container(
          alignment: Alignment.center,
          color: ThemeControl.theme.colorScheme.primary,
          width: widget.size,
          height: widget.size,
        );
        currentIndicator = _buildCurrentIndicator();
      } else {
        child = _buildDefault();
      }
    } else {
      Widget arts;
      if (_loaders.length == 1) {
        arts = _loaders.first.getImage(_getCacheSize()) ?? _buildDefault();
      } else {
        Widget? defaultArt;
        final cacheSize = _getCacheSize(true);
        if (_loaders.any((el) => el.showDefault)) {
          defaultArt = _buildDefault(true, cacheSize);
        }
        arts = Column(
          children: [
            Row(
              children: [
                _loaders[0].getImage(cacheSize) ?? defaultArt!,
                _loaders[1].getImage(cacheSize) ?? defaultArt!,
              ],
            ),
            Row(
              children: [
                _loaders[2].getImage(cacheSize) ?? defaultArt!,
                _loaders[3].getImage(cacheSize) ?? defaultArt!,
              ],
            ),
          ],
        );
      }
      if (widget.current) {
        child = Stack(
          children: [
            arts,
            Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.5),
              width: widget.size,
              height: widget.size,
            ),
          ],
        );
        currentIndicator = _buildCurrentIndicator();
      } else {
        child = arts;
      }
    }

    child = ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(widget.borderRadius),
      ),
      child: child,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: widget.loadAnimationDuration,
              switchInCurve: Curves.easeOut,
              child: Container(
                key: ValueKey(loaded),
                child: child
              ),
            ),
          ),
          if (currentIndicator != null)
            Center(child: currentIndicator),
        ],
      ),
    );
  }
}

/// Widget that shows rotating album art.
/// Used in bottom track panel and starts rotating when track starts playing.
class AlbumArtRotating extends StatefulWidget {
  const AlbumArtRotating({
    Key? key,
    required this.source,
    required this.initRotating,
    this.initRotation = 0.0,
  }) : assert(initRotation >= 0 && initRotation <= 1.0),
       super(key: key);

  final ContentArtSource source;

  /// Should widget start rotate on mount or not
  final bool initRotating;

  /// From 0.0 to 1.0
  /// Will be set as animation controller initial value
  final double initRotation;

  @override
  AlbumArtRotatingState createState() => AlbumArtRotatingState();
}

class AlbumArtRotatingState extends State<AlbumArtRotating> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    controller.value = widget.initRotation;
    if (widget.initRotating) {
      rotate();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Starts rotating, for use with global keys
  void rotate() {
    controller.repeat();
  }

  /// Stops rotating, for use with global keys
  void stopRotating() {
    controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      child: ContentArt(
        source: widget.source,
        size: kRotatingArtSize,
        borderRadius: kRotatingArtSize,
      ),
      animation: controller,
      builder: (context, child) => RotationTransition(
        turns: controller,
        child: child,
      ),
    );
  }
}
