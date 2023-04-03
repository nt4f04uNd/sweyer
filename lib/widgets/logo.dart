import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as constants;
import 'package:sweyer/sweyer.dart';

/// Creates a Sweyer logo.
class SweyerLogo extends StatelessWidget {
  const SweyerLogo({
    Key? key,
    this.size = kSongTileArtSize,
    this.color,
  }) : super(key: key);

  final double size;

  /// Background color to be used instead of [AppTheme.artColorForBlend],
  /// which is applied by default.
  final Color? color;

  static const _scale = 1.65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheSize = (size * _scale * MediaQuery.of(context).devicePixelRatio).round();
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(8.0),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Transform.scale(
              scale: _scale,
              child: Image.asset(
                constants.Assets.assetLogoMask,
                color: color != null
                    ? ContentArt.getColorToBlendInDefaultArt(color!)
                    : theme.appThemeExtension.artColorForBlend,
                cacheHeight: cacheSize,
                cacheWidth: cacheSize,
                colorBlendMode: BlendMode.plus,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
