import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sweyer/sweyer.dart';

enum PlayerInterfaceColorStyle {
  themeColor,
  artColor,
}

class PlayerInterfaceColorStyleControl extends Control {
  static PlayerInterfaceColorStyleControl instance = PlayerInterfaceColorStyleControl();

  @visibleForTesting
  late ValueNotifier<PaletteGenerator?> currentPallete;

  @override
  void init() {
    super.init();
    currentPallete = ValueNotifier(null);
    Settings.playerInterfaceColorStyle.addListener(_handlePlayerInterfaceStyle);
  }

  @override
  void dispose() {
    currentPallete.dispose();
    Settings.playerInterfaceColorStyle.removeListener(_handlePlayerInterfaceStyle);
    super.dispose();
  }

  void _handlePlayerInterfaceStyle() {
    switch (Settings.playerInterfaceColorStyle.value) {
      case PlayerInterfaceColorStyle.themeColor:
        currentPallete.value = null;
        break;
      case PlayerInterfaceColorStyle.artColor:
        break;
    }
  }
}

class PlayerInterfaceColorStyleSettingBuilder extends StatelessWidget {
  const PlayerInterfaceColorStyleSettingBuilder({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final ValueWidgetBuilder<PlayerInterfaceColorStyle> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerInterfaceColorStyle>(
      valueListenable: Settings.playerInterfaceColorStyle,
      builder: builder,
      child: child,
    );
  }
}

class PlayerInterfaceColorStyleSettingWidget extends StatelessWidget {
  const PlayerInterfaceColorStyleSettingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Стиль проигрывателя'),
      onTap: () {
        ShowFunctions.instance.showRadio<PlayerInterfaceColorStyle>(
          context: context,
          title: 'Стиль проигрывателя',
          items: PlayerInterfaceColorStyle.values,
          itemTitleBuilder: (item) => item.name,
          onItemSelected: (item) => Settings.playerInterfaceColorStyle.set(item),
          groupValueGetter: () => Settings.playerInterfaceColorStyle.value,
        );
      },
    );
  }
}

class PlayerInterfaceBackgroundWidget extends StatelessWidget {
  const PlayerInterfaceBackgroundWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.instance.theme;
    return PlayerInterfaceColorStyleSettingBuilder(
      builder: (context, value, child) {
        switch (value) {
          case PlayerInterfaceColorStyle.themeColor:
            return Container(
              color: theme.colorScheme.background,
            );
          case PlayerInterfaceColorStyle.artColor:
            return const _SolidPaletteColorBackground();
        }
      },
    );
  }
}

class _SolidPaletteColorBackground extends StatelessWidget {
  const _SolidPaletteColorBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeControl.instance.theme;
    return StreamBuilder(
      stream: PlaybackControl.instance.onSongChange,
      builder: (context, snapshot) => ValueListenableBuilder<PaletteGenerator?>(
        valueListenable: PlayerInterfaceColorStyleControl.instance.currentPallete,
        builder: (context, value, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          color: value?.dominantColor?.color.withOpacity(0.9) ?? theme.colorScheme.background,
        ),
      ),
    );
  }
}

class ContentArtLoadBuilder extends StatelessWidget {
  const ContentArtLoadBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(ContentArtOnLoadCallback? onLoad) builder;

  @override
  Widget build(BuildContext context) {
    return PlayerInterfaceColorStyleSettingBuilder(
      builder: (context, value, child) {
        final ContentArtOnLoadCallback? onLoad;
        switch (value) {
          case PlayerInterfaceColorStyle.themeColor:
            onLoad = null;
            break;
          case PlayerInterfaceColorStyle.artColor:
            onLoad = (image) async {
              final byteData = await image.toByteData();
              if (byteData == null) {
                return;
              }
              final palette = await compute<EncodedImage, PaletteGenerator>(
                (image) => createPalette(image),
                EncodedImage(
                  byteData,
                  width: image.width,
                  height: image.height,
                ),
              );
              PlayerInterfaceColorStyleControl.instance.currentPallete.value = palette;
            };
            break;
        }
        return builder(onLoad);
      },
    );
  }
}
