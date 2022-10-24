import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

class DefaultArtControl {
  static final instance = DefaultArtControl();

  late File _fallbackArtFile;

  Uri get fallbackArtUri => _fallbackArtFile.uri;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _fallbackArtFile = File('${directory.path}/default_art.png');
    await updateFallbackArt(null);
  }

  Future<void> updateFallbackArt(Color? color) async {
    await _updateFileFromColor(color);
    AudioService.setFallbackArt(fallbackArtUri);
  }

  Future<void> _updateFileFromColor(Color? color) async {
    if (color != null || !_fallbackArtFile.existsSync()) {
      color ??= staticTheme.appThemeExtension.artColorForBlend;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const int imageSize = constants.Assets.assetLogoThumbNotificationSize;
      const imageAssetPath = constants.Assets.assetLogoThumbNotification;

      final ByteData data = await rootBundle.load(imageAssetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetHeight: imageSize,
        targetWidth: imageSize,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      canvas.drawImage(image, Offset.zero, Paint());
      canvas.drawColor(ContentArt.getColorToBlendInDefaultArt(color), BlendMode.plus);
      final recordedImage = await recorder.endRecording().toImage(imageSize, imageSize);
      final recordedImageByteData = await recordedImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = recordedImageByteData!.buffer.asUint8List();
      await _fallbackArtFile.writeAsBytes(bytes);
    }
  }
}
