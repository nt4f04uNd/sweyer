import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sweyer/sweyer.dart';

final playerInterfaceColorStyleArtColorBuilderProvider = Provider(
  (ref) => PlayerInterfaceColorStyleArtColorBuilder(),
);

abstract class PlayerInterfaceColorStyleBuilder {
  ContentArtOnLoadCallback buildOnLoad(BuildContext context);
}

class PlayerInterfaceColorStyleArtColorBuilder implements PlayerInterfaceColorStyleBuilder {
  @visibleForTesting
  Future<PaletteGenerator?> buildPalette(ui.Image image) async {
    final byteData = await image.toByteData();
    if (byteData == null) {
      return null;
    }
    return compute<EncodedImage, PaletteGenerator>(
      (image) => createPalette(image),
      EncodedImage(
        byteData,
        width: image.width,
        height: image.height,
      ),
    );
  }

  @override
  ContentArtOnLoadCallback buildOnLoad(BuildContext context) {
    final theme = Theme.of(context);
    return (image) async {
      final palette = await buildPalette(image);
      PlayerInterfaceColorStyleControl.instance.updatePalette(
        theme,
        palette,
      );
    };
  }
}
