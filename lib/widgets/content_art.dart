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
// const double kArtBorderRadius = 10.0;
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

  const ContentArtSource.origin(SongOrigin origin)
    : _content = origin;

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
///  * [ContentArtLoader], which loads arts from `MediaStore`
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
    this.onLoad,
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
    this.onLoad,
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
    this.onLoad,
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
    this.onLoad,
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
    this.onLoad,
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

  /// Called when art is loaded.
  final VoidCallback? onLoad;

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
class ContentArtLoader {
  ContentArtLoader._({
    required _ContentArtState state,
    required this.song,
    required this.size,
    required VoidCallback onLoad,
  }) : _state = state,
       _onLoad = onLoad;

  final Song? song;
  final double? size;
  final _ContentArtState _state;
  final VoidCallback _onLoad;

  CancellationSignal? _signal;
  Uint8List? _bytes;
  late File _file;
  bool loaded = false;

  bool get showDefault => song == null ||
                          !_useBytes && song!.albumArt == null ||
                          _useBytes && loaded && _bytes == null;

  void _load() {
    assert(
      !loaded,
      "Art loader can be loaded only once",
    );
    if (song == null) {
      if (_state.loadAnimationDuration == Duration.zero) {
        loaded = true;
      } else {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          _commitLoad();
        });
      }
    } else if (_useBytes) {
      final uri = song!.contentUri;
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        if (!_state.mounted)
          return;
        _signal = CancellationSignal();
        _bytes = await ContentChannel.loadAlbumArt(
          uri: uri,
          size: Size.square(size!) * MediaQuery.of(_state.context).devicePixelRatio,
          signal: _signal!,
        );
        _commitLoad();
      });
    } else {
      if (_state.loadAnimationDuration == Duration.zero) {
        _loadFile();
      } else {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          _loadFile();
        });
      }
    }
  }

  void _commitLoad() {
    assert(
      !loaded,
      "Art loader can be loaded only once",
    );
    loaded = true;
    _onLoad();
  }

  void _loadFile() {
    if (!_state.mounted)
      return;
    final art = song!.albumArt;
    bool broken = false;
    if (art != null) {
      _file = File(art);
      final exists = _file.existsSync();
      broken = !exists;
      if (broken)
        _recreateArt();
    }
    if (!broken)
      _commitLoad();
  }

  Future<void> _recreateArt() async {
    final ablumId = song!.albumId;
    if (ablumId != null)
      await ContentChannel.fixAlbumArt(song!.albumId!);
    _commitLoad();
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
  late List<ContentArtLoader> _loaders;

  bool get loaded => _loaders.isEmpty || _loaders.every((el) => el.loaded);
  bool get showDefault => _loaders.isEmpty || _loaders.every((el) => el.showDefault);

  /// Min duration for [loadAnimationDuration].
  static Duration get _minDuration => _useBytes
    ? const Duration(milliseconds: 100)
    : Duration.zero;

  Duration get loadAnimationDuration => widget.loadAnimationDuration < _minDuration
    ? _minDuration
    : widget.loadAnimationDuration;

  @override
  void initState() { 
    super.initState();
    _init();
  }

  void _init() {
    _dirty = true;
    final content = widget.source?._content;
    if (content == null || content is Song) {
      _loaders = [
        ContentArtLoader._(
          state: this,
          song: content as Song?,
          size: widget.size,
          onLoad: _onLoad,
        ),
      ];
    } else if (content is Album) {
      _loaders = [
        ContentArtLoader._(
          state: this,
          song: content.firstSong,
          size: widget.size,
          onLoad: _onLoad,
        ),
      ];
    } else if (content is Playlist) {
      final songs = content.songs;
      final size = _getSize(true);
      switch (songs.length) {
        case 0:
          _loaders = [
            ContentArtLoader._(
              state: this,
              song: null,
              size: widget.size,
              onLoad: _onLoad,
            ),
          ];
          break;
        case 1:
          final loader = ContentArtLoader._(
            state: this,
            song: songs.first,
            size: size,
            onLoad: _onLoad,
          );
          List.generate(4, (index) => loader);
          break;
        case 2: 
          _loaders = List.generate(2, (index) => ContentArtLoader._(
            state: this,
            song: songs[index],
            size: size,
            onLoad: _onLoad,
          ));
          _loaders.addAll(_loaders.reversed.toList());
          break;
        case 3:
          _loaders = List.generate(3, (index) => ContentArtLoader._(
            state: this,
            song: songs[index],
            size: size,
            onLoad: _onLoad,
          ));
          _loaders.add(_loaders[0]);
          break;
        case 4:
          _loaders = List.generate(4, (index) => ContentArtLoader._(
            state: this,
            song: songs[index],
            size: size,
            onLoad: _onLoad,
          ));
          break;
      }
    } else if (content is Artist) {
      _loaders = [
        ContentArtLoader._(
          state: this,
          song: null,
          size: widget.size,
          onLoad: _onLoad,
        ),
      ];
    }
    for (final loader in _loaders) {
      loader._load();
    }
  }

  bool _dirty = true;
  void _onLoad() {
    if (mounted) {
      setState(() { });
    }
  }
  void _deliverLoad(int? frame, RawImage child) {
    // RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
    // ui.Image image = await boundary.toImage();
    // ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // Uint8List pngBytes = byteData.buffer.asUint8List();
    // print(pngBytes);
    // final image = 
    // if (_dirty) {
    //   widget.onLoad?.call(child.key);
    //   _dirty = false;
    // }
  }

  void _update() {
    for (final loader in _loaders)
      loader.cancel();
    _init();
  }

  double? _devicePixelRatio;

  @override
  void didChangeDependencies() {
    final newPixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (_devicePixelRatio != null && _devicePixelRatio != newPixelRatio)
      _update();
    _devicePixelRatio = newPixelRatio;
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant ContentArt oldWidget) {
    if (oldWidget.source?._content != widget.source?._content)
      _update();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() { 
    for (final loader in _loaders)
      loader.cancel();
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
      frameBuilder:(
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        // _deliverLoad();
        print('wqfqfw $frame');
        return child;
      },
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
          if (loadAnimationDuration == Duration.zero)
            Center(child: child)
          else
            Center(
              child: AnimatedSwitcher(
                duration: loadAnimationDuration,
                switchInCurve: Curves.easeOut,
                child: RepaintBoundary(
                  key: ValueKey(loaded),
                  child: child,
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
