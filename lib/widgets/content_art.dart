import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Whether running on scoped storage, and should use bytes to load album
/// arts from `MediaStore`.
bool get _useScopedStorage => DeviceInfoControl.instance.sdkInt >= 29;

class ContentArtSource with EquatableMixin {
  const ContentArtSource(Content content) : _content = content;

  const ContentArtSource.song(Song song) : _content = song;

  const ContentArtSource.album(Album album) : _content = album;

  const ContentArtSource.playlist(Playlist playlist) : _content = playlist;

  /// Checks the kind of [PersistentQueue], and respectively either picks [ContentArtSource.album], or [ContentArtSource.playlist].
  const ContentArtSource.persistentQueue(PersistentQueue persistentQueue)
      : assert(persistentQueue is Album || persistentQueue is Playlist),
        _content = persistentQueue;

  const ContentArtSource.artist(Artist artist) : _content = artist;

  const ContentArtSource.origin(SongOrigin origin) : _content = origin;

  final Content _content;

  @override
  List<Object?> get props => [_content];
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
class ContentArt extends StatefulWidget {
  const ContentArt({
    Key? key,
    required this.source,
    this.color,
    this.size,
    this.defaultArtIcon,
    this.defaultArtIconScale = 1.0,
    this.assetScale = 1.0,
    this.assetHighRes = false,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.currentIndicatorScale,
    this.onLoad,
    this.loadAnimationDuration = kArtLoadAnimationDuration,
  }) : super(key: key);

  /// Creates an art for the [SongTile] or [SelectableSongTile].
  const ContentArt.songTile({
    Key? key,
    required this.source,
    this.color,
    this.defaultArtIcon,
    this.defaultArtIconScale = 1.0,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.onLoad,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  })  : size = kSongTileArtSize,
        assetHighRes = false,
        currentIndicatorScale = null,
        super(key: key);

  /// Creates an art for the [PersistentQueueTile].
  /// It has the same image contents scale as [AlbumArt.songTile].
  const ContentArt.persistentQueueTile({
    Key? key,
    required this.source,
    this.color,
    this.defaultArtIcon,
    this.defaultArtIconScale = 1.0,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.onLoad,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  })  : size = kPersistentQueueTileArtSize,
        assetHighRes = false,
        currentIndicatorScale = 1.17,
        super(key: key);

  /// Creates an art for the [ArtistTile].
  /// It has the same image contents scale as [AlbumArt.songTile].
  const ContentArt.artistTile({
    Key? key,
    required this.source,
    this.color,
    this.defaultArtIcon,
    this.defaultArtIconScale = 1.0,
    this.assetScale = 1.0,
    this.borderRadius = kArtistTileArtSize,
    this.current = false,
    this.onLoad,
    this.loadAnimationDuration = kArtListLoadAnimationDuration,
  })  : size = kPersistentQueueTileArtSize,
        assetHighRes = false,
        currentIndicatorScale = 1.1,
        super(key: key);

  /// Creates an art for the [PlayerRoute].
  /// Its image contents scale differs from the [AlbumArt.songTile] and [AlbumArt.PersistentQueueTile].
  const ContentArt.playerRoute({
    Key? key,
    required this.source,
    this.size,
    this.color,
    this.defaultArtIcon,
    this.defaultArtIconScale = 1.0,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.onLoad,
    this.loadAnimationDuration = const Duration(milliseconds: 500),
  })  : assetHighRes = true,
        current = false,
        currentIndicatorScale = null,
        super(key: key);

  final ContentArtSource? source;

  /// Background color for the album art.
  /// By default will use [ThemeControl.instance.colorForBlend].
  final Color? color;

  /// Album art size.
  final double? size;

  /// Icon to show as default image instead of the app logo.
  ///
  /// Will be ignored if [source] is created from [Song], since the song default art
  /// are inteded to use an app logo.
  final IconData? defaultArtIcon;

  /// Scale that will be applied to the [defaultArtIcon].
  final double defaultArtIconScale;

  /// Scale that will be applied to the asset image contents.
  final double assetScale;

  /// Whether the default album art is should be rendered with hight resolution.
  /// Defaults to `false`.
  ///
  /// This changes image contents, so size of it might be different and you probably
  /// want to change [assetScale].
  final bool assetHighRes;

  /// Album art border radius.
  /// Defaults to [kArtBorderRadius].
  final double borderRadius;

  /// Will show current indicator if true.
  /// When album art does exist, will dim it a bit and overlay the indicator.
  /// Otherwise, will replace the logo placeholder image without dimming the background.
  final bool current;

  /// SCale for the [CurrentIndicator].
  final double? currentIndicatorScale;

  /// Called when art is loaded.
  final Function(ui.Image)? onLoad;

  /// Above Android Q and above album art loads from bytes, and performns an animation on load.
  /// This defines the duration of this animation.
  final Duration loadAnimationDuration;

  /// This is the color of the mask background (by RGBs, full color would be `0x1a1a1a`).
  /// It's twice lighter than the shadow color on the mask,
  /// which is `0x001d0d0d`.Used in [getColorToBlendInDefaultArt].
  static const int _defaultArtMask = 0x1a;

  /// Returns the color to be blended in default art.
  ///
  /// The default art asset is a grey-toned mask, so we subtract that mask
  /// to get the color we need to blend to get that original [color].
  static Color getColorToBlendInDefaultArt(Color color) {
    final int r = (((color.value >> 16) & 0xff) - _defaultArtMask).clamp(0, 0xff);
    final int g = (((color.value >> 8) & 0xff) - _defaultArtMask).clamp(0, 0xff);
    final int b = ((color.value & 0xff) - _defaultArtMask).clamp(0, 0xff);
    return Color((0xff << 24) + (r << 16) + (g << 8) + b);
  }

  @override
  _ContentArtState createState() => _ContentArtState();
}

/// Loading state for [_ArtSourceLoader].
enum _SourceLoading {
  /// There's not source to load.
  notLoading,

  /// Source loading is in process.
  loading,

  /// Source has been loaded and ready to be used.
  loaded,
}

/// Signature for function that notifies about updates of [_SourceLoading] state.
typedef OnLoadingChangeCallback = void Function(_SourceLoading);

/// Base class for loading arts for a content.
/// It loads a source of the art and provides it to the [_ContentArtState].

abstract class _ArtSourceLoader {
  _ArtSourceLoader({
    required this.state,
    this.onLoadingChange,
  });

  /// Art state this loader is bound to.
  final _ContentArtState state;

  /// Function that notifies about updates of [_SourceLoading] state.
  /// If none specified [Art._onSourceLoad] will be used.
  final OnLoadingChangeCallback? onLoadingChange;

  /// Loading state.
  _SourceLoading get loading => _loading;
  _SourceLoading _loading = _SourceLoading.notLoading;
  void setLoading(_SourceLoading value) {
    assert(
      _loading != _SourceLoading.loaded,
      "Image has loaded and loader is locked",
    );
    _loading = value;
    final onLoad = onLoadingChange ?? state._onSourceLoad;
    onLoad(value);
  }

  /// Whether art should show some default art, after the loader loads.
  /// It should be invalid to call this method when not [_SourceLoading.loaded].
  bool get showDefault;

  /// Loads the source.
  ///
  /// Commonly, at the start of this method, state should be set to
  /// [_SourceLoading.loading], and then at the end, set to [_SourceLoading.loaded].
  void load();

  /// Cancels the source loading.
  void cancel();

  /// Returns the image built from the loaded source.
  /// May return `null`, when [showDefault] is `true`.
  Widget? getImage(int? cacheSize);
}

/// Always loads the default art.
class _NoSourceLoader extends _ArtSourceLoader {
  _NoSourceLoader(_ContentArtState state) : super(state: state);

  @override
  bool get showDefault => true;

  @override
  void load() {
    if (loading != _SourceLoading.notLoading) {
      return;
    }
    if (state.loadAnimationDuration == Duration.zero) {
      setLoading(_SourceLoading.notLoading);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setLoading(_SourceLoading.notLoading);
      });
    }
  }

  @override
  void cancel() {}

  @override
  Widget? getImage(int? cacheSize) {
    return null;
  }
}

/// Loads song art for [Song]s.
///
/// This class automatically chooses between [_SongScopedStorageArtSourceLoader] and [_SongFileArtSourceLoader],
/// depended on Android version.
class _SongArtSourceLoader extends _ArtSourceLoader {
  _SongArtSourceLoader({
    required this.song,
    required this.size,
    required _ContentArtState state,
  }) : super(state: state) {
    if (song == null) {
      loader = _NoSourceLoader(state);
    } else if (_useScopedStorage) {
      loader = _SongScopedStorageArtSourceLoader(
        song: song!,
        size: size!,
        onLoadingChange: (value) => setLoading(value),
        state: state,
      );
    } else {
      loader = _SongFileArtSourceLoader(
        song: song!,
        size: size,
        onLoadingChange: (value) => setLoading(value),
        state: state,
      );
    }
  }

  final Song? song;
  final double? size;
  late final _ArtSourceLoader loader;

  @override
  bool get showDefault {
    assert(loading != _SourceLoading.loading);
    return loader.showDefault;
  }

  @override
  void load() {
    loader.load();
  }

  @override
  void cancel() {
    loader.cancel();
  }

  @override
  Widget? getImage(int? cacheSize) {
    return loader.getImage(cacheSize);
  }
}

/// Loads local song art with `MediaStore` API, used above Android Q.
///
/// Lower Android Q album arts ared displayed directly from the file path
/// of album art from [Song.albumArt].
///
/// Above Q though, this path was deprecated due to  scoped storage, and now
/// album arts should be fetched with special method in `MediaStore.loadThumbnail`.
///
/// The [_useScopedStorage] indicates that we are on scoped storage and should use this
/// new method.
///
/// See also:
///  * [_SongFileArtSourceLoader], which loads arts from files
///  * [_SongArtSourceLoader], which automatically chooses between this loader and [_SongFileArtSourceLoader],
///    dependent on Android version
class _SongScopedStorageArtSourceLoader extends _ArtSourceLoader {
  _SongScopedStorageArtSourceLoader({
    required this.song,
    required this.size,
    required _ContentArtState state,
    required OnLoadingChangeCallback onLoadingChange,
  }) : super(state: state, onLoadingChange: onLoadingChange);

  final Song song;
  final double size;

  CancellationSignal? _signal;
  Uint8List? _bytes;

  @override
  bool get showDefault {
    assert(loading != _SourceLoading.loading);
    return _bytes == null;
  }

  @override
  void load() {
    if (loading != _SourceLoading.notLoading) {
      return;
    }
    setLoading(_SourceLoading.loading);
    final uri = song.contentUri;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (!state.mounted) {
        return;
      }
      _signal = CancellationSignal();
      try {
        _bytes = await ContentChannel.instance.loadAlbumArt(
          uri: uri,
          size: Size.square(size) * MediaQuery.of(state.context).devicePixelRatio,
          signal: _signal!,
        );
      } on ContentChannelException catch (ex, stack) {
        if (ex != ContentChannelException.io) {
          FirebaseCrashlytics.instance.recordError(
            ex,
            stack,
            reason: 'in _SongScopedStorageArtSourceLoader.load',
          );
        }
      } finally {
        setLoading(_SourceLoading.loaded);
      }
    });
  }

  @override
  void cancel() {
    _signal?.cancel();
    _signal = null;
  }

  @override
  Widget? getImage(int? cacheSize) {
    if (showDefault) {
      return null;
    }
    return Image.memory(
      _bytes!,
      width: size,
      height: size,
      cacheHeight: cacheSize,
      cacheWidth: cacheSize,
      fit: BoxFit.cover,
      frameBuilder: state.frameBuilder,
    );
  }
}

/// Loads local song art from the file, used below Android Q.
///
/// Also, sometimes below Android Q, album arts files sometimes become unaccessible,
/// even though they should not. This loader will try to restore them with [Song.albumId]
/// and [ContentChannel.fixAlbumArt].
///
/// See also:
///  * [_SongScopedStorageArtSourceLoader], which loads arts in scoped storage
///  * [_SongArtSourceLoader], which automatically chooses between this loader and [_SongScopedStorageArtSourceLoader],
///    dependent on Android version
class _SongFileArtSourceLoader extends _ArtSourceLoader {
  _SongFileArtSourceLoader({
    required this.song,
    required this.size,
    required _ContentArtState state,
    required OnLoadingChangeCallback onLoadingChange,
  }) : super(state: state, onLoadingChange: onLoadingChange);

  final Song song;
  final double? size;

  late File _file;

  @override
  bool get showDefault {
    assert(loading != _SourceLoading.loading);
    return song.albumArt == null;
  }

  @override
  void load() {
    if (loading != _SourceLoading.notLoading) {
      return;
    }
    setLoading(_SourceLoading.loading);
    if (state.loadAnimationDuration == Duration.zero) {
      _loadFile();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _loadFile();
      });
    }
  }

  @override
  void cancel() {}

  void _loadFile() {
    if (!state.mounted) {
      return;
    }
    final art = song.albumArt;
    bool broken = false;
    if (art != null) {
      _file = File(art);
      final exists = _file.existsSync();
      broken = !exists;
      if (broken) {
        _recreateArt();
      }
    }
    if (!broken) {
      setLoading(_SourceLoading.loaded);
    }
  }

  Future<void> _recreateArt() async {
    final ablumId = song.albumId;
    if (ablumId != null) {
      await ContentChannel.instance.fixAlbumArt(song.albumId!);
    }
    setLoading(_SourceLoading.loaded);
  }

  @override
  Widget? getImage(int? cacheSize) {
    if (showDefault) {
      return null;
    }
    return Image.file(
      _file,
      width: size,
      height: size,
      cacheHeight: cacheSize,
      cacheWidth: cacheSize,
      fit: BoxFit.cover,
      frameBuilder: state.frameBuilder,
    );
  }
}

/// Makes a call to the backend which searches an for artist art
/// on Genius.
///
/// Unknown artist will be ignored and set as not loading immediately.
class _ArtistGeniusArtSourceLoader extends _ArtSourceLoader {
  _ArtistGeniusArtSourceLoader({
    required this.artist,
    required this.size,
    required _ContentArtState state,
  }) : super(state: state);

  final Artist artist;
  final double? size;

  String? _url;

  @override
  bool get showDefault {
    assert(loading != _SourceLoading.loading);
    return _url == null;
  }

  @override
  void load() {
    if (loading != _SourceLoading.notLoading) {
      return;
    }
    if (artist.isUnknown) {
      setLoading(_SourceLoading.notLoading);
      return;
    }
    setLoading(_SourceLoading.loading);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (!state.mounted) {
        return;
      }
      try {
        final info = await artist.fetchInfo();
        _url = info.imageUrl;
      } catch (ex, stack) {
        FirebaseCrashlytics.instance.recordError(
          ex,
          stack,
          reason: 'in _ArtistGeniusArtSourceLoader.load',
        );
      } finally {
        setLoading(_SourceLoading.loaded);
      }
    });
  }

  @override
  void cancel() {}

  @override
  Widget? getImage(int? cacheSize) {
    if (showDefault) {
      return null;
    }
    return Image(
      image: ResizeImage.resizeIfNeeded(cacheSize, cacheSize, CachedNetworkImageProvider(_url!)),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stacktrace) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stacktrace,
          reason: 'in _ArtistGeniusArtSourceLoader.getImage',
        );
        return state._buildDefault();
      },
      frameBuilder: state.frameBuilder,
    );
  }
}

// TODO: end the abstraction of Art and ContentArt
// I started it, but it's consumed a lot of time and I left it unended
//
// What needs to be done is that there should be a clean widget Art,
// all specifics regarding source and how widget is exactly rendered should be either:
//  * factored out to delegates (like this class)
//  * or implemented as derived widgets from [Art], like [ContentArt]
//
/// Loading the art consists of three stages:
///
///  1. Load the source - this part is delegated to [_ArtSourceLoader].
///
///     During this stage, art displays either:
///      * current indicator, if it's current
///      * an empty box otherwise
///
///  2. Load the image from source.
///
///     When the traversal happens from the first stage to this, the art is
///     revealed with animation.
///
///  3. Optionally, if [Art.onLoad] was provided, send the loaded art widget
///     to it.
///
class _ContentArtState extends State<ContentArt> {
  late List<_ArtSourceLoader> _loaders;
  GlobalKey? globalKey;

  bool get loaded => _loaders.isEmpty || _loaders.every((el) => el.loading != _SourceLoading.loading);
  bool get showDefault => _loaders.isEmpty || _loaders.every((el) => el.showDefault);

  /// Min duration for [loadAnimationDuration].
  static Duration get _minDuration => _useScopedStorage ? const Duration(milliseconds: 100) : Duration.zero;

  Duration get loadAnimationDuration =>
      widget.loadAnimationDuration < _minDuration ? _minDuration : widget.loadAnimationDuration;

  @override
  void initState() {
    super.initState();
    if (widget.onLoad != null) {
      globalKey = GlobalKey();
    }
    _init();
  }

  void _init() {
    _delivered = false;
    final content = widget.source?._content;
    if (content == null) {
      _loaders = [_NoSourceLoader(this)];
    } else if (content is Song) {
      _loaders = [
        _SongArtSourceLoader(
          state: this,
          song: content,
          size: widget.size,
        ),
      ];
    } else if (content is Album) {
      _loaders = [
        _SongArtSourceLoader(
          state: this,
          song: content.firstSong,
          size: widget.size,
        ),
      ];
    } else if (content is Playlist) {
      final songs = content.songs;
      final size = _getSize(true);
      switch (songs.length) {
        case 0:
          final loader = _SongArtSourceLoader(
            state: this,
            song: null,
            size: size,
          );
          _loaders = List.generate(4, (index) => loader);
          break;
        case 1:
          final loader = _SongArtSourceLoader(
            state: this,
            song: songs.first,
            size: size,
          );
          _loaders = List.generate(4, (index) => loader);
          break;
        case 2:
          _loaders = List.generate(
            2,
            (index) => _SongArtSourceLoader(
              state: this,
              song: songs[index],
              size: size,
            ),
          );
          _loaders.addAll(_loaders.reversed.toList());
          break;
        case 3:
          _loaders = List.generate(
            3,
            (index) => _SongArtSourceLoader(
              state: this,
              song: songs[index],
              size: size,
            ),
          );
          _loaders.add(_loaders[0]);
          break;
        case 4:
        default:
          _loaders = List.generate(
            4,
            (index) => _SongArtSourceLoader(
              state: this,
              song: songs[index],
              size: size,
            ),
          );
          break;
      }
    } else if (content is Artist) {
      _loaders = [
        _ArtistGeniusArtSourceLoader(
          state: this,
          artist: content,
          size: widget.size,
        ),
      ];
    } else {
      throw UnimplementedError();
    }
    for (final loader in _loaders) {
      loader.load();
    }
  }

  bool _delivered = false;
  void _onSourceLoad(_SourceLoading loading) {
    if (mounted) {
      if (loading == _SourceLoading.notLoading) {
        _deliverLoad();
      }
      setState(() {});
    }
  }

  Widget frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (frame == 0 && loaded) {
      _deliverLoad();
    }
    return child;
  }

  /// Finally reveals the art and delivers the [ContentArt.onLoad] event, if listener was
  /// provided.
  ///
  /// For each widget that can be return from build method:
  ///  * if that widget is an image - the [frameBuilder] should be provided to it, so when it's ready,
  ///    this method would be called to reveal it
  ///  * otherwise it should be called manually (see _deliverLoad call in [build])
  ///
  /// It's an error to call this method, when [loaded] is not true.
  Future<void> _deliverLoad() async {
    assert(loaded);
    if (!_delivered) {
      _delivered = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          setState(() {
            /* rebuild to change animated switcher child */
          });
        }
      });
      if (widget.onLoad != null) {
        /// Schedule two build phazes, don't know exactly why, but one throws with
        /// `debugNeedsPaint` assertion fail.
        ///
        /// And the third is for the called above `setState`, because calling it
        /// will cause image to be rebuilt to trigger [AnimatiedSwitcher] animation.
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              if (!mounted) {
                return;
              }
              final object = globalKey!.currentContext!.findRenderObject()!;
              final RenderRepaintBoundary boundary;
              if (object is RenderStack) {
                boundary = (object.lastChild! as RenderAnimatedOpacity).child! as RenderRepaintBoundary;
              } else if (object is RenderPositionedBox) {
                boundary = object.child! as RenderRepaintBoundary;
              } else {
                throw StateError('');
              }
              final image = await boundary.toImage();
              widget.onLoad!(image);
            });
          });
        });
      }
    }
  }

  void _update() {
    for (final loader in _loaders) {
      loader.cancel();
    }
    _init();
  }

  double? _devicePixelRatio;

  @override
  void didChangeDependencies() {
    final newPixelRatio = MediaQuery.of(context).devicePixelRatio;
    // Reload arts when on scoped storage, as they are using the pixel ratio size at the stage
    // of loading.
    if (_useScopedStorage && _devicePixelRatio != null && _devicePixelRatio != newPixelRatio) {
      _update();
    }
    _devicePixelRatio = newPixelRatio;
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant ContentArt oldWidget) {
    final oldContent = oldWidget.source?._content;
    final content = widget.source?._content;
    if (oldContent != content ||
        oldContent is Album && content is Album && oldContent.firstSong != content.firstSong ||
        oldContent is Playlist && content is Playlist && !listEquals(oldContent.songIds, content.songIds)) {
      _update();
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
    return forPlaylist && widget.size != null ? widget.size! / 2 : widget.size;
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
    final int? _cacheSize = (cacheSize == null ? cacheSize : cacheSize * widget.assetScale)?.round();
    Widget child;
    if (widget.defaultArtIcon != null && widget.source?._content is! Song?) {
      // We should show the art now.
      _deliverLoad();
      final theme = ThemeControl.instance.theme;
      child = Container(
        alignment: Alignment.center,
        color: theme.colorScheme.primary,
        width: widget.size,
        height: widget.size,
        child: Icon(
          widget.defaultArtIcon,
          color: theme.colorScheme.onPrimary,
          size: 32.0,
        ),
      );
      if (widget.defaultArtIconScale != 1.0) {
        child = Transform.scale(scale: widget.defaultArtIconScale, child: child);
      }
    } else {
      child = Image.asset(
        widget.assetHighRes ? Constants.Assets.ASSET_LOGO_MASK : Constants.Assets.ASSET_LOGO_THUMB_INAPP,
        width: size,
        height: size,
        cacheWidth: _cacheSize,
        cacheHeight: _cacheSize,
        color: widget.color != null
            ? ContentArt.getColorToBlendInDefaultArt(widget.color!)
            : ThemeControl.instance.colorForBlend,
        colorBlendMode: BlendMode.plus,
        frameBuilder: frameBuilder,
        fit: BoxFit.cover,
      );
      if (widget.assetScale != 1.0) {
        child = Transform.scale(scale: widget.assetScale, child: child);
        if (forPlaylist) {
          child = ClipRRect(child: child);
        }
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
          color: ThemeControl.instance.theme.colorScheme.primary,
          width: widget.size,
          height: widget.size,
        );
        currentIndicator = _buildCurrentIndicator();
        // We should show the art now.
        _deliverLoad();
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
                // TODO: there's unwanted 1 pixel gap, remove the transform that is used as workaround when this is resolved https://github.com/flutter/flutter/issues/14288
                Transform.scale(scale: 1.01, child: _loaders[0].getImage(cacheSize) ?? defaultArt!),
                Transform.scale(scale: 1.01, child: _loaders[1].getImage(cacheSize) ?? defaultArt!),
              ],
            ),
            Row(
              children: [
                Transform.scale(scale: 1.01, child: _loaders[2].getImage(cacheSize) ?? defaultArt!),
                Transform.scale(scale: 1.01, child: _loaders[3].getImage(cacheSize) ?? defaultArt!),
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

    child = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.all(
          Radius.circular(widget.borderRadius),
        ),
        child: child,
      ),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          if (loadAnimationDuration == Duration.zero)
            Center(
              key: globalKey,
              child: child,
            )
          else
            Center(
              child: AnimatedSwitcher(
                key: globalKey,
                duration: loadAnimationDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _delivered ? child : Opacity(opacity: 0, child: child),
              ),
            ),
          if (currentIndicator != null) Center(child: currentIndicator),
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
  })  : assert(initRotation >= 0 && initRotation <= 1.0),
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
