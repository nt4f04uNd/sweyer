import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<ui.Image> loadImage(
  ImageProvider imageProvider, {
  Size? size,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final ImageStream stream = imageProvider.resolve(
    ImageConfiguration(
      size: size,
      devicePixelRatio: 1.0,
    ),
  );
  final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
  Timer? loadFailureTimeout;
  late ImageStreamListener listener;
  listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    loadFailureTimeout?.cancel();
    stream.removeListener(listener);
    imageCompleter.complete(info.image);
  });

  if (timeout != Duration.zero) {
    loadFailureTimeout = Timer(timeout, () {
      stream.removeListener(listener);
      imageCompleter.completeError(
        TimeoutException('Timeout occurred trying to load from $imageProvider'),
      );
    });
  }
  stream.addListener(listener);
  return imageCompleter.future;
}
