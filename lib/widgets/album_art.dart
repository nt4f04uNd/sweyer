/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:io';

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

class AlbumArt extends StatelessWidget {
  const AlbumArt({
    Key key,
    @required this.path,
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
    @required this.path,
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
    @required this.path,
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
    @required this.path,
    this.color,
    this.size,
    this.assetScale = 1.0,
    this.borderRadius = kArtBorderRadius,
  }) : current = false,
       highRes = true,
       currentIndicatorScale = null,
       super(key: key);

  final String path;

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

  Widget _buildCurrentIndicator() {
    return currentIndicatorScale == null
        ? const CurrentIndicator()
        : Transform.scale(
            scale: currentIndicatorScale,
            child: const CurrentIndicator(),
          );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path == null || !File(path).existsSync()) {
      if (current) {
        child = Container(
          alignment: Alignment.center,
          color: ThemeControl.theme.colorScheme.primary,
          width: size,
          height: size,
          child: _buildCurrentIndicator(),
        );
      } else {
        child = Image.asset(
          highRes
              ? Constants.Assets.ASSET_LOGO_MASK
              : Constants.Assets.ASSET_LOGO_THUMB_INAPP,
          width: size,
          height: size,
          color: color != null
              ? getColorForBlend(color)
              : ThemeControl.colorForBlend,
          colorBlendMode: BlendMode.plus,
          fit: BoxFit.cover,
        );
        if (assetScale != 1.0) {
          child = Transform.scale(scale: assetScale, child: child);
        }
      }
    } else {
      final image = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
      if (current) {
        child = Stack(
          children: [
            image,
            Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.5),
              width: size,
              height: size,
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
        Radius.circular(borderRadius),
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
      image = Container(
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
