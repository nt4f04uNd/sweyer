/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

const double kSMMLargeAlbumArtMargins = 80.0;
const double kSMMSmallArtSize = 48.0;
const Duration kSMMLargeAlbumFadeDuration = Duration(milliseconds: 180);
const Duration kSMMSmallAlbumFadeDuration = Duration(milliseconds: 570);
const Duration kSMMRotatingAlbumFadeDuration = Duration(milliseconds: 100);

/// `3` is The [CircularPercentIndicator.lineWidth] doubled and additional 3 spacing
///
/// `2` is Border width
const double kRotatingArtSize = kSMMSmallArtSize - 6 - 3 - 2;

/// Abstract class widget every album art should extend instead of [StatefulWidget] to be able to use [_AlbumArtStateMixin]
abstract class _AlbumArtWidget extends StatefulWidget {
  _AlbumArtWidget({Key key}) : super(key: key);

  /// Path to album art
  /// If null is passed, album art should handle this and show placeholder
  String get path;
}

/// Mixin that uses [StatefulWidget] [initState] to check album art path and fetch it if needed
mixin _AlbumArtStateMixin<T extends _AlbumArtWidget> on State<T> {
  /// Loading future to use then in future builder
  // Future<Uint8List> loading;
  CancelableOperation<Uint8List> loadingOperation;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    loadingOperation = CancelableOperation.fromFuture(loadArt(widget.path));
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    loadingOperation.cancel();
  }

  /// Fetches art by path
  Future<Uint8List> loadArt(String path) async {
    // Call loading promise if path is not null
    if (path != null) {
      File file = File(path);
      if (await file.exists()) return file.readAsBytes();
    }
    return null;
  }
}

//***************************************** Album arts (actual pictures) ******************************************

/// Large album art to display in player route
///
/// Has size [constraints] minus [kSMMLargeAlbumArtMargins]
///
/// Shows placeholder or art, depending on provided path
///
/// With [onTap] will generate draw ripples on taps
class AlbumArtPlayerRoute extends StatelessWidget {
  AlbumArtPlayerRoute({
    Key key,
    @required this.path,
    this.onTap,
  }) : super(key: key);

  final String path;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      double size = constraint.maxWidth - kSMMLargeAlbumArtMargins;
      if (path == null || !File(path).existsSync()) {
        return AlbumPlaceholderLarge(size: size);
      } else {
        return ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(10.0),
          ),
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.fill,
          ),
        );
      }
    });
  }
}

/// TODO: make a special class for album arts page, that will work the same as album art small
class AlbumArtLarge extends StatelessWidget {
  AlbumArtLarge({
    Key key,
    @required this.path,
    this.size,
    this.placeholderLogoFactor = 0.5,
    this.onTap,
  }) : super(key: key);

  final String path;
  final double size;
  final double placeholderLogoFactor;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    if (path == null || !File(path).existsSync()) {
      return AlbumPlaceholderLarge(
        size: size,
        logoFactor: placeholderLogoFactor,
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(10.0),
        ),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.fill,
        ),
      );
    }
  }
}

/// Album art to display in albums page, for example
///
/// Pretty the same as [AlbumArt], but can be tappable
class AlbumArtTappable extends StatelessWidget {
  AlbumArtTappable({
    Key key,
    @required this.path,
    this.size,
    this.placeholderLogoFactor = 0.5,
    this.onTap,
  }) : super(key: key);

  final String path;
  final double size;
  final double placeholderLogoFactor;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          // child: AlbumPlaceholderLarge(size: 240.0),
          child: AlbumArtLarge(
            path: path,
            size: size,
            placeholderLogoFactor: placeholderLogoFactor,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: SMMInkWell(
              onTap: onTap,
              splashColor:
                  ThemeControl.isLight ? Colors.white24 : Colors.white12,
              borderRadius: const BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// class AlbumArtSmall extends StatelessWidget {
//   const AlbumArtSmall({Key key, @required this.path}) : super(key: key);

//   final String path;
//   @override
//   Widget build(BuildContext context) {
//     if (path == null) {
//       return const AlbumPlaceholderSmall();
//     } else {
//       return ClipRRect(
//         borderRadius: const BorderRadius.all(
//           Radius.circular(10),
//         ),
//         child: Image.file(
//           File(path),
//           width: kSMMSmallArtSize,
//           height: kSMMSmallArtSize,
//           fit: BoxFit.fill,
//         ),
//       );
//     }
//   }
// }

class AlbumArtSmall extends _AlbumArtWidget {
  AlbumArtSmall({
    Key key,
    @required this.path,
  }) : super(key: key);

  @override
  final String path;

  @override
  _AlbumArtSmallState createState() => _AlbumArtSmallState();
}

class _AlbumArtSmallState extends State<AlbumArtSmall>
// with _AlbumArtStateMixin
{
  @override
  Widget build(BuildContext context) {
    if (widget.path == null || !File(widget.path).existsSync()) {
      return const AlbumPlaceholderSmall();
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(10.0),
        ),
        child: Image.file(
          File(widget.path),
          width: kSMMSmallArtSize,
          height: kSMMSmallArtSize,
          fit: BoxFit.fill,
        ),
      );

      // return FutureBuilder<bool>(
      //     future: checkOperation.value,
      //     builder: (context, snapshot) {
      //       if (snapshot.hasError) {
      //         return const AlbumPlaceholderSmall();
      //       } else {
      //         return snapshot.connectionState == ConnectionState.waiting ||
      //                 snapshot.connectionState == ConnectionState.done &&
      //                     (!snapshot.hasData || !snapshot.data)
      //             ? const AlbumArtEmptySpace()
      //             : ClipRRect(
      //                 borderRadius: const BorderRadius.all(
      //                   Radius.circular(10.0),
      //                 ),
      //                 child: Image.file(
      //                   File(widget.path),
      //                   width: kSMMSmallArtSize,
      //                   height: kSMMSmallArtSize,
      //                   fit: BoxFit.fill,
      //                 ),
      //               );
      //       }
      //     });
    }
  }
}

//***************************************** Album placeholders and other fake images ******************************************

class AlbumPlaceholderLarge extends StatelessWidget {
  const AlbumPlaceholderLarge({
    Key key,
    @required this.size,
    this.logoFactor = 0.5,
  })  : assert(size != null),
        assert(logoFactor >= 0.0 && logoFactor <= 1.0),
        super(key: key);

  /// The container size.
  final double size;

  /// A factor applied to a note logo to reduce it's size inside the container.
  ///
  /// Must be in range from 0.0 to 1.0
  final double logoFactor;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArt.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      ),
      padding: EdgeInsets.all(size / 2 * (1 - logoFactor)),
      child: SvgPicture.asset(Constants.Paths.ASSET_LOGO_SVG),
    );
  }
}

/// Base container for album art.
///
/// Looks just like a box with rounded corners.
class AlbumArtBaseSmall extends StatelessWidget {
  const AlbumArtBaseSmall({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kSMMSmallArtSize,
      height: kSMMSmallArtSize,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArt.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      ),
      padding: const EdgeInsets.all(9.0),
      child: child,
    );
  }
}

class AlbumPlaceholderSmall extends StatelessWidget {
  const AlbumPlaceholderSmall({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlbumArtBaseSmall(
      child: Image.asset(
        Constants.Paths.ASSET_LOGO_THUMB,
      ),
    );
  }
}

class AlbumArtErrorLarge extends StatelessWidget {
  const AlbumArtErrorLarge({Key key, @required this.size}) : super(key: key);
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArt.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: EdgeInsets.all(size / 4.0),
      child: Icon(
        Icons.error_outline,
        size: size / 4.0,
      ),
    );
  }
}

class AlbumArtErrorSmall extends StatelessWidget {
  const AlbumArtErrorSmall({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlbumArtBaseSmall(
      child: Icon(Icons.error_outline),
    );
  }
}

//***************************************** Rotating arts ******************************************

/// Widget that shows rotating album art
/// Used in bottom track panel and starts rotating when track starts playing
class AlbumArtRotating extends _AlbumArtWidget {
  AlbumArtRotating({
    Key key,
    @required this.path,
    @required this.initIsRotating,
    this.initRotation = 0.0,
  })  : assert(initIsRotating != null),
        assert(initRotation >= 0 && initRotation <= 1.0),
        super(key: key);

  @override
  final String path;

  /// Should widget start rotate on mount or not
  final bool initIsRotating;

  /// From 0.0 to 1.0
  /// Will be set as animation controller initial value
  final double initRotation;

  @override
  AlbumArtRotatingState createState() => AlbumArtRotatingState();
}

class AlbumArtRotatingState extends State<AlbumArtRotating>
    with SingleTickerProviderStateMixin, _AlbumArtStateMixin {
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

    if (widget.initIsRotating) rotate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Future<void> reloadArt(String path) async {
  //   setState(() {
  //     loadingOperation?.cancel();
  //     loadingOperation = CancelableOperation.fromFuture(loadArt(path));
  //   });
  // }

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
    return RotationTransition(
        turns: _controller,
        child: (() {
          if (widget.path == null || !File(widget.path).existsSync()) {
            return const RotatingAlbumPlaceholder();
          } else {
            return ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(kRotatingArtSize),
              ),
              child: Image.file(
                File(widget.path),
                width: kRotatingArtSize,
                height: kRotatingArtSize,
                fit: BoxFit.fill,
              ),
            );

            //   return FutureBuilder<Uint8List>(
            //       future: loadingOperation.value,
            //       builder: (context, snapshot) {
            //         return AnimatedSwitcher(
            //           duration: kSMMRotatingAlbumFadeDuration,
            //           child: snapshot.connectionState ==
            //                       ConnectionState.waiting ||
            //                   snapshot.connectionState == ConnectionState.done &&
            //                       !snapshot.hasData
            //               ? const RotatingAlbumPlaceholder()
            //               : ClipRRect(
            //                   borderRadius: const BorderRadius.all(
            //                     Radius.circular(kRotatingArtSize),
            //                   ),
            //                   child: Image.memory(
            //                     snapshot.data,
            //                     width: kRotatingArtSize,
            //                     height: kRotatingArtSize,
            //                     fit: BoxFit.fill,
            //                   ),
            //                 ),
            //         );
            //       });
          }
        })());
  }
}

class RotatingAlbumPlaceholder extends StatelessWidget {
  const RotatingAlbumPlaceholder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kRotatingArtSize,
      height: kRotatingArtSize,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArtSmallRound.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        Constants.Paths.ASSET_LOGO_THUMB,
      ),
    );
  }
}
