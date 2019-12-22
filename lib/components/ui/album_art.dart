/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Album art general widget
/// Shows placeholder or art, depending on provided path
class AlbumArt extends StatelessWidget {
  final String path;

  /// Whether to use large variant (used in playerRoute)
  final bool isLarge;

  /// Creates round album art if true
  final bool round;
  AlbumArt(
      {Key key, @required this.path, this.isLarge: false, this.round: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: path != null
            ? AlbumArtPic(path: path, isLarge: isLarge, round: round)
            : AlbumArtPlaceholder(isLarge: isLarge, round: round));
  }
}

/// Show album art picture
class AlbumArtPic extends StatelessWidget {
  final String path;
  final bool isLarge;
  final bool round;
  const AlbumArtPic(
      {Key key,
      @required this.path,
      @required this.isLarge,
      @required this.round})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var file = File(path);
    if (!file.existsSync()) {
      return AlbumArtPlaceholder(
        isLarge: isLarge,
        round: round,
      );
    }
    return LayoutBuilder(builder: (context, constraint) {
      double size = isLarge
          ? constraint.maxWidth - 80
          : round // Reduce the size of art if using round
              ? constraint.maxHeight -
                  6 -
                  3 // The `CircularPercentIndicator` `lineWidth` doubled and additional 3 spacing
                  -
                  2 // Border width
              : constraint.maxHeight;
      return ClipRRect(
        borderRadius: BorderRadius.all(
            Radius.circular(round ? constraint.maxHeight : 10)),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.fill,
          frameBuilder: (context, child, frame, wasAsynchronouslyLoaded) {
            if (frame == null) // If frame is null - show placeholder
              return AlbumArtPlaceholder(
                isLarge: false,
                round: false,
              );
            return child;
          },
        ),
      );
    });
  }
}

/// Show note asset placeholder
class AlbumArtPlaceholder extends StatelessWidget {
  final bool isLarge;
  final bool round;
  const AlbumArtPlaceholder({
    Key key,
    @required this.isLarge,
    @required this.round,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      double size = isLarge
          ? constraint.maxWidth - 80
          : round // Reduce the size of art if using round
              ? constraint.maxHeight -
                  6 -
                  3 // The `CircularPercentIndicator` `lineWidth` doubled and additional 3 spacing
                  -
                  2 // Border width
              : constraint.maxHeight;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isLarge
              ? Constants.AppTheme.albumArtLarge.auto(context)
              : round
                  ? Constants.AppTheme.albumArtSmallRound.auto(context)
                  : Constants.AppTheme.albumArtSmall.auto(context),
          borderRadius: BorderRadius.all(Radius.circular(round ? 500 : 10)),
        ),
        padding: isLarge ? EdgeInsets.all(70) : EdgeInsets.all(round ? 8 : 10),
        child: LayoutBuilder(builder: (context, constraint) {
          return isLarge
              ? SvgPicture.asset(
                  'assets/images/icons/note_rounded.svg',
                )
              : Image.asset('assets/images/placeholder_thumb.png');
          // : Image.asset('assets/images/placeholder_thumb_old.png');
        }),
      );
    });
  }
}

/// Widget that shows rotating album art
/// Used in bottom track panel and starts rotating when track starts playing
class RotatingAlbumArt extends StatefulWidget {
  RotatingAlbumArt({
    Key key,
    @required this.path,
    @required this.initIsRotating,
    this.initRotation = 0.0,
  })  : assert(initIsRotating != null),
        assert(initRotation >= 0 && initRotation <= 1.0),
        super(key: key);

  final String path;

  /// Should widget start rotate on mount or not
  final bool initIsRotating;

  /// From 0.0 to 1.0
  /// Will be set as animation controller initial value
  final double initRotation;

  @override
  RotatingAlbumArtState createState() => RotatingAlbumArtState();
}

class RotatingAlbumArtState extends State<RotatingAlbumArt>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 15), vsync: this);
    _controller.value = widget.initRotation ?? 0;

    _controller
      ..addListener(() {
        setState(() {});
      });

    if (widget.initIsRotating)
      rotate();
    else
      stopRotating();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Starts rotating, for use with global keys
  void rotate() {
    _controller.repeat();
  }

  /// Stops rotating, for use with global keys
  void stopRotating() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _controller.value * 2 * math.pi,
      child: Container(
        child: AlbumArt(
          path: widget.path,
          round: true,
        ),
      ),
    );
  }
}
