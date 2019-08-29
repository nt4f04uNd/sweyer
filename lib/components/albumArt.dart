import 'dart:io';
import 'package:flutter/material.dart';

/// Album art
class AlbumArt extends StatelessWidget {
  final String path;

  /// Horizontal margin of placeholder
  final double placeholderHorizontalMargin;

  /// Padding of placeholder
  final double placeholderPadding;

  /// Whether to use width of height from setting max icon size in placeholder
  final bool placeholderUseWidthForMaxSize;
  AlbumArt(
      {Key key,
      @required this.path,
      this.placeholderHorizontalMargin: 0,
      this.placeholderPadding: 6,
      this.placeholderUseWidthForMaxSize: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: path != null
            ? _AlbumArtPic(path: path)
            : _AlbumArtPlaceholder(
                horizontalMargin: placeholderHorizontalMargin,
                padding: placeholderPadding,
                useWidthForMaxSize: placeholderUseWidthForMaxSize,
              ));
  }
}

class _AlbumArtPic extends StatelessWidget {
  final String path;
  const _AlbumArtPic({Key key, @required this.path}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      child: LayoutBuilder(builder: (context, constraint) {
        return Image.file(
          File(path),
          width: constraint.biggest.height,
          height: constraint.biggest.height,
          fit: BoxFit.cover,
        );
      }),
    );
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  final double horizontalMargin;
  final double padding;
  final bool useWidthForMaxSize;
  const _AlbumArtPlaceholder(
      {Key key,
      @required this.horizontalMargin,
      @required this.padding,
      @required this.useWidthForMaxSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.all(padding),
      child: LayoutBuilder(builder: (context, constraint) {
        return Icon(
          Icons.music_note,
          size: useWidthForMaxSize
              ? constraint.biggest.width
              : constraint.biggest.height,
          color: Colors.deepPurple.shade500,
        );
      }),
    );
  }
}
// TODO: refactor constructors and add comments
