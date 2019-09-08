import 'dart:io';
import 'package:flutter/material.dart';

/// Album art with hero inside
class AlbumArtHero extends StatelessWidget {
  /// Path of album art
  final String path;

  /// Whether to use large variant (used in player route)
  final bool isLarge;
  AlbumArtHero({Key key, this.path, this.isLarge: false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: path != null
          ? _AlbumArtPicHero(path: path, isLarge: isLarge)
          : _AlbumArtPlaceholderHero(isLarge: isLarge),
    );
  }
}

class _AlbumArtPicHero extends StatelessWidget {
  double horizontalMargin;
  final String path;
  final bool isLarge;
  _AlbumArtPicHero({Key key, @required this.path, @required this.isLarge})
      : super(key: key) {
    if (isLarge)
      horizontalMargin = 20;
    else
      horizontalMargin = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Hero(
        tag: 'AlbumArtPic',
        child: SizedBox(
          height: isLarge
              ? MediaQuery.of(context).size.width - 70
              : constraint.biggest.height,
          width: isLarge
              ? MediaQuery.of(context).size.width - 70
              : constraint.biggest.height,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(isLarge ? 10 : 25)),
            child: Image.file(
              File(path),
              width: isLarge
                  ? constraint.biggest.width
                  : constraint.biggest.height,
              height: isLarge
                  ? constraint.biggest.width
                  : constraint.biggest.height,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    });
  }
}

class _AlbumArtPlaceholderHero extends StatelessWidget {
  final bool isLarge;
  _AlbumArtPlaceholderHero({Key key, @required this.isLarge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint1) {
      return Hero(
        tag: 'AlbumArtPlaceholder',
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(isLarge ? 10 : 25)),
          child: Container(
            height: isLarge ? MediaQuery.of(context).size.width - 100 : constraint1.biggest.height,
            width: isLarge ? MediaQuery.of(context).size.width - 100 : constraint1.biggest.height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
            ),
            child: LayoutBuilder(builder: (context, constraint) {
              return Icon(
                Icons.music_note,
                size: isLarge
                    ? constraint.biggest.height * 0.6 < 50
                        ? 35
                        : constraint.biggest.height * 0.6
                    : constraint.biggest.width * 0.6 < 50
                        ? 35
                        : constraint.biggest.width * 0.6,
                color: Colors.deepPurple,
              );
            }),
          ),
        ),
      );
    });
  }
}
// TODO: refactor constructors and add comments
