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
const double kAlbumTileArtSize = 64.0;
const double kArtBorderRadius = 10.0;

/// `3` is the [CircularPercentIndicator.lineWidth] doubled and additional 3 spacing
///
/// `2` is border width
const double kRotatingArtSize = kSongTileArtSize - 6 - 3 - 2;

const Duration _kLoadAnimationDuration = Duration(milliseconds: 340);

//  TODO: comments
class AlbumArtSource {
  const AlbumArtSource({
    @required this.path,
    @required this.contentUri,
    @required this.albumId,
  }) : _none = false;

  const AlbumArtSource.none()
    : _none = true,
      path = null,
      contentUri = null,
      albumId = null;

  final bool _none;
  final String path;
  final String contentUri;
  final int albumId;
}

class AlbumArt extends StatefulWidget {
  const AlbumArt({
    Key key,
    @required this.source,
    this.color,
    this.size,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.highRes = false,
    this.currentIndicatorScale,
    this.loadAnimationDuration = _kLoadAnimationDuration,
  }) : super(key: key);

  /// Creates an art for the [SongTile] or [SelectableSongTile].
  const AlbumArt.songTile({
    Key key,
    @required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.loadAnimationDuration = _kLoadAnimationDuration,
  }) : size = kSongTileArtSize,
       highRes = false,
       currentIndicatorScale = null,
       super(key: key);

  /// Creates an art for the [ALbumTile].
  /// It has the same image contents scale as [AlbumArt.songTile].
  const AlbumArt.albumTile({
    Key key,
    @required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
    this.loadAnimationDuration = _kLoadAnimationDuration,
  }) : size = kAlbumTileArtSize,
       highRes = false,
       currentIndicatorScale = 1.17,
       super(key: key);

  /// Creates an art for the [PlayerRoute].
  /// Its image contents scale differs from the [AlbumArt.songTile] and [AlbumArt.albumTile].
  const AlbumArt.playerRoute({
    Key key,
    @required this.source,
    @required this.size,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.loadAnimationDuration = _kLoadAnimationDuration,
  }) : current = false,
       highRes = true,
       currentIndicatorScale = null,
       super(key: key);

  final AlbumArtSource source;

  /// Background color for the album art.
  /// By default will use [ThemeControl.colorForBlend].
  final Color color;

  /// Album art size.
  final double size;

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

  // TODO: doc
  final double currentIndicatorScale;

  /// Above Android Q and above album art loads from bytes, and performns an animation on load.
  /// This defines the duration of this animation.
  final Duration loadAnimationDuration;

  @override
  _AlbumArtState createState() => _AlbumArtState();
}

class _AlbumArtState extends State<AlbumArt> {
  // TODO: dedup this code to a separate base class

  bool get useBytes => ContentControl.sdkInt >= 29;
  CancellationSignal signal;
  Uint8List bytes;
  bool loaded = false;

  @override
  void initState() { 
    super.initState();
    _load();
  }

  void _load() {
    if (useBytes) {
      final uri =  widget.source.contentUri;
      assert(uri != null);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        signal = CancellationSignal();
        bytes = await ContentChannel.loadAlbumArt(
          uri: uri,
          size: Size.square(widget.size) * MediaQuery.of(context).devicePixelRatio,
          signal: signal,
        );
        if (mounted) {
          setState(() {
            loaded = true;
          });
        }
      });
    }
  } 

  @override
  void didUpdateWidget(covariant AlbumArt oldWidget) {
    if (oldWidget.source?.contentUri != widget.source?.contentUri) {
      _load();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() { 
    signal?.cancel();
    super.dispose();
  }

  Widget _buildCurrentIndicator() {
    return widget.currentIndicatorScale == null
        ? const CurrentIndicator()
        : Transform.scale(
            scale: widget.currentIndicatorScale,
            child: const CurrentIndicator(),
          );
  }

  bool recreated = false;
  Future<void> _recreateArt() async {
    recreated = true;
    await ContentChannel.fixAlbumArt(widget.source.albumId);
    if (mounted) {
      setState(() { });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    File file; 
    bool showDefault = widget.source == null ||
                       widget.source._none ||
                       !useBytes && widget.source.path == null ||
                       useBytes && loaded && bytes == null;
    if (!showDefault && !useBytes) {
      file = File(widget.source.path);
      final exists = file.existsSync();
      showDefault = !exists;
      if (!exists && !recreated) {
        _recreateArt();
      }
    }
    if (useBytes && !loaded) {
      if (widget.current) {
        child = Container(
          alignment: Alignment.center,
          width: widget.size,
          height: widget.size,
          child: _buildCurrentIndicator(),
        );
      } else {
        child = SizedBox(
          width: widget.size,
          height: widget.size,
        );
      }
    } else if (showDefault) {
      if (widget.current) {
        child = Container(
          alignment: Alignment.center,
          color: ThemeControl.theme.colorScheme.primary,
          width: widget.size,
          height: widget.size,
          child: _buildCurrentIndicator(),
        );
      } else {
        child = Image.asset(
          widget.highRes
              ? Constants.Assets.ASSET_LOGO_MASK
              : Constants.Assets.ASSET_LOGO_THUMB_INAPP,
          width: widget.size,
          height: widget.size,
          color: widget.color != null
              ? getColorForBlend(widget.color)
              : ThemeControl.colorForBlend,
          colorBlendMode: BlendMode.plus,
          fit: BoxFit.cover,
        );
        if (widget.assetScale != 1.0) {
          child = Transform.scale(scale: widget.assetScale, child: child);
        }
      }
    } else {
      Image image;
      if (useBytes) {
        image = Image.memory(
          bytes,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        );
      } else {
        image = Image.file(
          file,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        );
      }
      if (widget.current) {
        child = Stack(
          children: [
            image,
            Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.5),
              width: widget.size,
              height: widget.size,
              child: _buildCurrentIndicator(),
            ),
          ],
        );
      } else {
        child = image;
      }
    }

    child = ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(widget.borderRadius),
      ),
      child: child,
    );

    if (!useBytes)
      return child;
    return AnimatedSwitcher(
      duration: widget.loadAnimationDuration,
      switchInCurve: Curves.easeOut,
      child: Container(
        key: ValueKey("${widget.source?.contentUri}_$loaded"),
        child: child
      ),
    );
  }
}

/// Widget that shows rotating album art.
/// Used in bottom track panel and starts rotating when track starts playing.
class AlbumArtRotating extends StatefulWidget {
  const AlbumArtRotating({
    Key key,
    @required this.source,
    @required this.initRotating,
    this.color,
    this.initRotation = 0.0,
  })  : assert(initRotating != null),
        assert(initRotation >= 0 && initRotation <= 1.0),
        super(key: key);

  final AlbumArtSource source;

  /// Background color for the album art.
  /// By default will use [ThemeControl.colorForBlend].
  final Color color;

  /// Should widget start rotate on mount or not
  final bool initRotating;

  /// From 0.0 to 1.0
  /// Will be set as animation controller initial value
  final double initRotation;

  @override
  AlbumArtRotatingState createState() => AlbumArtRotatingState();
}

class AlbumArtRotatingState extends State<AlbumArtRotating> with SingleTickerProviderStateMixin {
  AnimationController controller;

  bool get useBytes => ContentControl.sdkInt >= 29;
  CancellationSignal signal;
  Uint8List bytes;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    controller.value = widget.initRotation ?? 0;
    if (widget.initRotating) {
      rotate();
    }
     _load();
  }

  void _load() {
    if (useBytes) {
      final uri =  widget.source.contentUri;
      assert(uri != null);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        signal = CancellationSignal();
        bytes = await ContentChannel.loadAlbumArt(
          uri: uri,
          size: const Size.square(kRotatingArtSize) * MediaQuery.of(context).devicePixelRatio,
          signal: signal,
        );
        if (mounted) {
          setState(() {
            loaded = true;
          });
        }
      });
    }
  } 

  @override
  void didUpdateWidget(covariant AlbumArtRotating oldWidget) {
    if (oldWidget.source?.contentUri != widget.source?.contentUri) {
      _load();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    signal?.cancel();
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

  bool recreated = false;
  Future<void> _recreateArt() async {
    recreated = true;
    await ContentChannel.fixAlbumArt(widget.source.albumId);
    if (mounted) {
      setState(() { });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    File file;
    bool showDefault = widget.source == null ||
                       widget.source._none ||
                       !useBytes && widget.source.path == null ||
                       useBytes && loaded && bytes == null;
    if (!showDefault && !useBytes) {
      file = File(widget.source.path);
      final exists = file.existsSync();
      showDefault = !exists;
      if (!exists && !recreated) {
        _recreateArt();
      }
    }
    if (useBytes && !loaded) {
      image = const SizedBox(
        width: kRotatingArtSize,
        height: kRotatingArtSize,
      );
    } else if (showDefault) {
      image = SizedBox(
        width: kRotatingArtSize,
        height: kRotatingArtSize,
        child: Image.asset(
          Constants.Assets.ASSET_LOGO_THUMB_INAPP,
          color: widget.color != null
              ? getColorForBlend(widget.color)
              : ThemeControl.colorForBlend,
          colorBlendMode: BlendMode.plus,
          fit: BoxFit.cover,
        ),
      );
    } else {
      if (useBytes) {
        image = Image.memory(
          bytes,
          width: kRotatingArtSize,
          height: kRotatingArtSize,
          fit: BoxFit.cover,
        );
      } else {
        image = Image.file(
          file,
          width: kRotatingArtSize,
          height: kRotatingArtSize,
          fit: BoxFit.cover,
        );
      }
    }

    image = AnimatedBuilder(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(kRotatingArtSize),
        ),
        child: image,
      ),
      animation: controller,
      builder: (context, child) => RotationTransition(
        turns: controller,
        child: child,
      ),
    );
    if (!useBytes)
      return image;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOut,
      child: Container(
        key: ValueKey("${widget.source?.contentUri}_$loaded"),
        child: image,
      ),
    );
  }
}
