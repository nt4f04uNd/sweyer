import 'dart:ui' as ui;

import 'package:palette_generator/palette_generator.dart';

import '../../test.dart';

class FakePlayerInterfaceColorStyleArtColorBuilder extends PlayerInterfaceColorStyleArtColorBuilder {
  @override
  Future<PaletteGenerator?> buildPalette(ui.Image image) async {
    return PaletteGenerator.fromColors([
      PaletteColor(kBlueSquareColor, 1),
    ]);
  }
}
