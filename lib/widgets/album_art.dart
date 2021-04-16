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
const double kAlbumTileArtSize = 70.0;
const double kArtBorderRadius = 10.0;

/// `3` is the [CircularPercentIndicator.lineWidth] doubled and additional 3 spacing
///
/// `2` is border width
const double kRotatingArtSize = kSongTileArtSize - 6 - 3 - 2;

class AlbumArtSource {
  const AlbumArtSource._(this.data, this.albumId);
  const AlbumArtSource.none(String data, {@required int albumId}) : this._(data, albumId);
  const AlbumArtSource.path(String data, {@required int albumId}) : this._(data, albumId);
  const AlbumArtSource.memory(Uint8List data, {@required int albumId}) : this._(data, albumId);
  final Object data;
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
  }) : super(key: key);

  /// Creates an art for the [SongTile] or [SelectableSongTile].
  const AlbumArt.songTile({
    Key key,
    @required this.source,
    this.color,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
    this.current = false,
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
  }) : size = kAlbumTileArtSize,
       highRes = false,
       currentIndicatorScale = 1.17,
       super(key: key);

  /// Creates an art for the [PlayerRoute].
  /// Its image contents scale differs from the [AlbumArt.songTile] and [AlbumArt.albumTile].
  const AlbumArt.playerRoute({
    Key key,
    @required this.source,
    this.color,
    this.size,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
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
  /// NOTE that this changes image placeholder contents, so size of not might be different and you probably
  /// want to change [assetScale].
  final bool highRes;

  final double currentIndicatorScale;


  @override
  _AlbumArtState createState() => _AlbumArtState();
}

class _AlbumArtState extends State<AlbumArt> {
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
    Uint8List bytes;
    bool showDefault;
    if (widget.source == null || widget.source.data == null) {
      showDefault = true;
    } else {
      final data = widget.source.data;
      if (data is String) {
        file = File(data);
        final exists = file.existsSync();
        showDefault = !exists;
        if (!exists && !recreated) {
          _recreateArt();
        }
      } else if (data is Uint8List) {
        bytes = data;
        showDefault = bytes.isEmpty;
      } else {
        throw UnimplementedError();
      }
    }
    if (showDefault) {
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
      if (file != null) {
        image = Image.file(
          file,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        );
      } else if (bytes != null) {
        image = Image.memory(
          bytes,
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

    return ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(widget.borderRadius),
      ),
      child: child,
    );
  }
}

/// Widget that shows rotating album art.
/// Used in bottom track panel and starts rotating when track starts playing.
class AlbumArtRotating extends StatefulWidget {
  const AlbumArtRotating({
    Key key,
    @required this.path,
    @required this.initRotating,
    this.color,
    this.initRotation = 0.0,
  })  : assert(initRotating != null),
        assert(initRotation >= 0 && initRotation <= 1.0),
        super(key: key);

  final String path;

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
    Widget image;
    if (widget.path == null || !File(widget.path).existsSync()) {
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
      image = Image.file(
        File(widget.path),
        width: kRotatingArtSize,
        height: kRotatingArtSize,
        fit: BoxFit.cover,
      );
    }
    return AnimatedBuilder(
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
  }
}
