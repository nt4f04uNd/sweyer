import 'dart:io';
import 'package:flutter/material.dart';

/// Album art
class AlbumArt extends StatelessWidget {
  final String path;

  /// Whether to use large variant (used in playerRoute)
  final bool isLarge;
  AlbumArt({Key key, @required this.path, this.isLarge: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: path != null
            ? _AlbumArtPic(path: path, isLarge: isLarge)
            : _AlbumArtPlaceholder(isLarge: isLarge));
  }
}

class _AlbumArtPic extends StatelessWidget {
  final String path;
  final bool isLarge;
  const _AlbumArtPic({Key key, @required this.path, @required this.isLarge})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      child: LayoutBuilder(builder: (context, constraint) {
        return Image.file(
          File(path),
          width: isLarge
              ? constraint.biggest.width - 80
              : constraint.biggest.height,
          height: isLarge
              ? constraint.biggest.width - 80
              : constraint.biggest.height,
          fit: BoxFit.cover,
        );
      }),
    );
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  final bool isLarge;
  const _AlbumArtPlaceholder({
    Key key,
    @required this.isLarge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint1) {
      return Container(
        height: isLarge
            ? constraint1.biggest.width - 80
            : constraint1.biggest.height, // These two lines are needed to reduce note icon size on plyaerRoute
        width: isLarge ? constraint1.biggest.width - 80 : constraint1.biggest.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, constraint) {
          return Icon(
            Icons.music_note,
            size: isLarge
                ? constraint.biggest.width - 115
                : constraint.biggest.height,
            color: Colors.deepPurple,
          );
        }),
      );
    });
  }
}
// TODO: refactor constructors and add comments
