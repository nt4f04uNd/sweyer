/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sweyer/constants.dart' as Constants;

const double kSMMLargeAlbumArtMargins = 80.0;
const double kSMMSmallArtSize = 48.0;
const Duration kSMMLargeAlbumFadeDuration = Duration(milliseconds: 180);
const Duration kSMMSmallAlbumFadeDuration = Duration(milliseconds: 340);
const Duration kSMMRotatingAlbumFadeDuration = Duration(milliseconds: 100);

/// `3` is The `CircularPercentIndicator` `lineWidth` doubled and additional 3 spacing
///
/// `2` is Border width
const double kRotatingArtSize = kSMMSmallArtSize - 6 - 3 - 2;

/// Abstract class widget every album art should extend instead of `StatefulWidget` to be able to use `_AlbumArtStateMixin`
abstract class _AlbumArtWidget extends StatefulWidget {
  _AlbumArtWidget({Key key}) : super(key: key);

  /// Path to album art
  /// If null is passed, album art should handle this and show placeholder
  String get path;
}

/// Mixin that uses `initState` to check album art path and fetch it if needed
mixin _AlbumArtStateMixin<T extends _AlbumArtWidget> on State<T> {
  /// Loading future to use then in future builder
  Future<Uint8List> loading;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    loading = loadArt(widget.path);
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

/// Large album art to display in player route
///
/// Has size `constraints - kSMMLargeAlbumArtMargins`
///
/// Shows placeholder or art, depending on provided path
class AlbumArtLarge extends StatelessWidget {
  AlbumArtLarge({Key key, @required this.path}) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      double size = constraint.maxWidth - kSMMLargeAlbumArtMargins;
      if (path == null) {
        return AlbumPlaceholderLarge(size: size);
      } else {
        return ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.fill,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return AlbumArtErrorLarge(
                  size: size,
                );
              }
              return child;
            },
          ),
        );
      }
    });
  }
}

// class AlbumArtSmall extends _AlbumArtWidget {
//   AlbumArtSmall({Key key, @required this.path}) : super(key: key);

//   @override
//   final String path;

//   @override
//   _AlbumArtSmallState createState() => _AlbumArtSmallState();
// }

class AlbumArtSmall extends StatelessWidget {
  const AlbumArtSmall({Key key, @required this.path}) : super(key: key);

  final String path;
  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return const AlbumPlaceholderSmall();
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
        child: Image.file(
          File(path),
          width: kSMMSmallArtSize,
          height: kSMMSmallArtSize,
          fit: BoxFit.fill,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return AlbumArtErrorSmall();
            }
            return child;
          },
        ),
      );
    }
  }
}

// class _AlbumArtSmallState extends State<AlbumArtSmall>
//     // with _AlbumArtStateMixin
//     {
//   @override
//   Widget build(BuildContext context) {
//     if (widget.path == null) {
//       return const AlbumPlaceholderSmall();
//     } else {
//       // return FutureBuilder<Uint8List>(
//       //     future: loading,
//       //     builder: (context, snapshot) {
//       //       return AnimatedSwitcher(
//       //         duration: kSMMSmallAlbumFadeDuration,
//       //         child: snapshot.connectionState == ConnectionState.waiting ||
//       //                 snapshot.connectionState == ConnectionState.done &&
//       //                     !snapshot.hasData
//       //             ? const AlbumPlaceholderSmall()
//       //             :
//            return       ClipRRect(
//                       borderRadius: const BorderRadius.all(
//                         Radius.circular(10),
//                       ),
//                       child: Image.memory(
//                         snapshot.data,
//                         width: kSMMSmallArtSize,
//                         height: kSMMSmallArtSize,
//                         fit: BoxFit.fill,
//                       ),
//                     );
//     //         );
//     //       });
//     // }
//   }
// }

/// Widget that shows rotating album art
/// Used in bottom track panel and starts rotating when track starts playing
class RotatingAlbumArt extends _AlbumArtWidget {
  RotatingAlbumArt({
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
  RotatingAlbumArtState createState() => RotatingAlbumArtState();
}

class RotatingAlbumArtState extends State<RotatingAlbumArt>
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

  Future<void> reloadArt(String path) async {
    setState(() {
      loading = loadArt(path);
    });
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
        child: (() {
          if (widget.path == null) {
            return const RotatingAlbumPlaceholder();
          } else {
            return FutureBuilder<Uint8List>(
                future: loading,
                builder: (context, snapshot) {
                  return AnimatedSwitcher(
                    duration: kSMMRotatingAlbumFadeDuration,
                    child: snapshot.connectionState ==
                                ConnectionState.waiting ||
                            snapshot.connectionState == ConnectionState.done &&
                                !snapshot.hasData
                        ? const RotatingAlbumPlaceholder()
                        : ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(kRotatingArtSize),
                            ),
                            child: Image.memory(
                              snapshot.data,
                              width: kRotatingArtSize,
                              height: kRotatingArtSize,
                              fit: BoxFit.fill,
                            ),
                          ),
                  );
                });
          }
        })());
  }
}

class AlbumPlaceholderLarge extends StatelessWidget {
  const AlbumPlaceholderLarge({Key key, @required this.size}) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArtLarge.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: EdgeInsets.all(size / 4),
      child: SvgPicture.asset(
        // TODO: move all asset paths to constants
        'assets/images/icons/note_rounded.svg',
      ),
    );
  }
}

class AlbumPlaceholderSmall extends StatelessWidget {
  const AlbumPlaceholderSmall({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kSMMSmallArtSize,
      height: kSMMSmallArtSize,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArtSmall.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(10),
      // TODO: path to const
      child: Image.asset(
        'assets/images/placeholder_thumb.png',
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
        color: Constants.AppTheme.albumArtLarge.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: EdgeInsets.all(size / 4),
      child: Icon(
        Icons.error_outline,
        size: size / 4,
      ),
    );
  }
}

class AlbumArtErrorSmall extends StatelessWidget {
  const AlbumArtErrorSmall({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kSMMSmallArtSize,
      height: kSMMSmallArtSize,
      decoration: BoxDecoration(
        color: Constants.AppTheme.albumArtSmall.auto(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(Icons.error_outline),
    );
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
      // TODO: path to const
      child: Image.asset('assets/images/placeholder_thumb.png'),
    );
  }
}
