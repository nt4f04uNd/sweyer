import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sweyer/sweyer.dart';

/// Button to switch loop mode
class LoopButton extends StatelessWidget {
  const LoopButton({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final player = MusicPlayer.instance;
    return StreamBuilder<bool>(
      stream: player.loopingStream,
      initialData: player.looping,
      builder: (context, snapshot) {
        return AnimatedIconButton(
          icon: const Icon(Icons.loop_rounded),
          size: textScaleFactor * 40.0,
          iconSize: textScaleFactor * NFConstants.iconSize,
          active: snapshot.data!,
          onPressed: player.switchLooping,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: QueueControl.instance.onQueueChanged,
      builder: (context, snap) => AnimatedIconButton(
        icon: const Icon(Icons.shuffle_rounded),
        color: theme.colorScheme.onSurface,
        size: textScaleFactor * 40.0,
        iconSize: textScaleFactor * NFConstants.iconSize,
        active: QueueControl.instance.state.shuffled,
        onPressed: () {
          QueueControl.instance.setQueue(
            shuffled: !QueueControl.instance.state.shuffled,
          );
        },
      ),
    );
  }
}

/// Icon button that opens settings page.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NFIconButton(
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => AppRouter.instance.goto(AppRoutes.settings),
    );
  }
}

/// Button type for [AppButton].
enum AppButtonType {
  /// Will create [ElevatedButton].
  elevated,

  /// Will create [TextButton].
  flat,
}

/// A button with text and icon, used to start queue playback.
///
/// Also used in:
///  * [PlayQueueButton]
///  * [ShuffleQueueButton]
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.splashColor,
    this.borderRadius = 15.0,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.loading = false,
    this.verticalPadding = 0.0,
    this.horizontalPadding = kHorizontalPadding,
  })  : type = AppButtonType.elevated,
        popResult = _emptyPopResult;

  const AppButton.flat({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.splashColor,
    this.borderRadius = 15.0,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.loading = false,
    this.verticalPadding = 0.0,
    this.horizontalPadding = kHorizontalPadding,
  })  : type = AppButtonType.flat,
        popResult = _emptyPopResult;

  /// Will automatically pop using its context, [onPressed] still will be called.
  const AppButton.pop({
    super.key,
    required this.text,
    required this.popResult,
    this.type = AppButtonType.flat,
    this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.splashColor,
    this.borderRadius = 15.0,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.loading = false,
    this.verticalPadding = 0.0,
    this.horizontalPadding = kHorizontalPadding,
  });

  final AppButtonType type;
  final Object? popResult;
  final String text;
  final Icon? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Color? splashColor;
  final double borderRadius;
  final double? fontSize;
  final FontWeight fontWeight;
  final bool loading;
  final double verticalPadding;
  final double horizontalPadding;

  static const kHorizontalPadding = 15.0;
  static const _emptyPopResult = Object();

  bool get pop => popResult != _emptyPopResult;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
    ..value = disabled ? 0.0 : 1.0;
  late Animation<Color?> colorAnimation;
  late Animation<Color?> textColorAnimation;

  bool get disabled => !widget.pop && widget.onPressed == null;

  Color get defaultColor {
    final theme = Theme.of(context);
    switch (widget.type) {
      case AppButtonType.elevated:
        return theme.colorScheme.primary;
      case AppButtonType.flat:
        return Colors.transparent;
    }
  }

  Color get defaultTextColor {
    final theme = Theme.of(context);
    switch (widget.type) {
      case AppButtonType.elevated:
        return theme.colorScheme.onPrimary;
      case AppButtonType.flat:
        return theme.colorScheme.onSecondary;
    }
  }

  VoidCallback? get onPressed => !widget.pop
      ? widget.onPressed
      : () {
          Navigator.pop(context, widget.popResult);
          widget.onPressed?.call();
        };

  EdgeInsets get padding => EdgeInsets.symmetric(
        vertical: widget.verticalPadding,
        horizontal: widget.horizontalPadding,
      );

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    if (disabled) {
      controller.reverse();
    } else {
      controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    colorAnimation = ColorTween(
      begin: theme.colorScheme.onSurface.withValues(alpha: 0.12),
      end: widget.color ?? defaultColor,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    textColorAnimation = ColorTween(
      begin: theme.colorScheme.onSurface.withValues(alpha: 0.38),
      end: widget.textColor ?? defaultTextColor,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
  }

  Widget _buildText() {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Text(
        widget.text,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        switch (widget.type) {
          case AppButtonType.elevated:
            return _buildElevated();
          case AppButtonType.flat:
            return _buildFlat();
        }
      },
    );
  }

  Widget _buildChild() {
    return widget.loading
        ? const SizedBox(
            width: 25.0,
            height: 25.0,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : widget.icon == null
            ? _buildText()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon!,
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: _buildText(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],
              );
  }

  Widget _buildElevated() {
    final theme = Theme.of(context);
    return ElevatedButton(
      child: _buildChild(),
      onPressed: onPressed,
      style: const ElevatedButton(child: null, onPressed: null).defaultStyleOf(context).copyWith(
            animationDuration: Duration.zero,
            backgroundColor: WidgetStateProperty.all(colorAnimation.value),
            padding: WidgetStateProperty.all(padding),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            )),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: WidgetStateProperty.all(textColorAnimation.value),
            overlayColor:
                WidgetStateProperty.all(widget.splashColor ?? theme.appThemeExtension.glowSplashColorOnContrast),
            splashFactory: NFListTileInkRipple.splashFactory,
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            textStyle: WidgetStateProperty.all(TextStyle(
              fontFamily: theme.textTheme.displayLarge!.fontFamily,
              fontWeight: widget.fontWeight,
              fontSize: widget.fontSize,
            )),
          ),
    );
  }

  Widget _buildFlat() {
    final theme = Theme.of(context);
    return TextButton(
      child: _buildChild(),
      onPressed: onPressed,
      style: const TextButton(child: SizedBox.shrink(), onPressed: null).defaultStyleOf(context).copyWith(
            animationDuration: Duration.zero,
            padding: WidgetStateProperty.all(padding),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            )),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: WidgetStateProperty.all(textColorAnimation.value),
            overlayColor:
                WidgetStateProperty.all(widget.splashColor ?? theme.appThemeExtension.glowSplashColorOnContrast),
            splashFactory: NFListTileInkRipple.splashFactory,
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            textStyle: WidgetStateProperty.all(TextStyle(
              fontFamily: theme.textTheme.displayLarge!.fontFamily,
              fontWeight: widget.fontWeight,
              fontSize: widget.fontSize,
            )),
          ),
    );
  }
}

/// Used to start queue playback.
class PlayQueueButton extends StatelessWidget {
  const PlayQueueButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return AppButton(
      text: l10n.playContentList,
      icon: const Icon(Icons.play_arrow_rounded, size: 28.0),
      borderRadius: 4.0,
      fontSize: 15.0,
      fontWeight: FontWeight.w700,
      onPressed: onPressed,
    );
  }
}

/// Used to start shuffled queue playback.
class ShuffleQueueButton extends StatelessWidget {
  const ShuffleQueueButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    return AppButton(
      text: l10n.shuffleContentList,
      icon: const Icon(Icons.shuffle_rounded, size: 22.0),
      color: theme.appThemeExtension.contrast,
      textColor: theme.colorScheme.secondaryContainer,
      borderRadius: 4.0,
      fontSize: 15.0,
      fontWeight: FontWeight.w700,
      onPressed: onPressed,
    );
  }
}

/// Creates an icon copy button, which, when pressed,
/// will copy [text] to clipboard.
class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.text,
    this.size = 44.0,
  });

  /// Text that will be copied when button is pressed.
  final String text;

  /// Button size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final color = Theme.of(context).colorScheme.onPrimary;
    return NFIconButton(
      icon: const Icon(Icons.content_copy_rounded),
      size: size,
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: text),
        );
        NFSnackbarController.showSnackbar(
          NFSnackbarEntry(
            child: NFSnackbar(
              title: Text(
                l10n.copied,
                style: TextStyle(color: color),
              ),
              titlePadding: const EdgeInsets.only(left: 8.0),
              leading: Icon(
                Icons.content_copy_rounded,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PlaybackControl.instance.onSongChange,
      builder: (context, snapshot) => StreamBuilder(
        stream: ContentControl.instance.onContentChange,
        builder: (context, snapshot) {
          final currentSong = PlaybackControl.instance.currentSong;
          return HeartButton(
            active: currentSong.isFavorite,
            onPressed: FavoritesControl.instance.toggleFavoriteCurrentSong,
          );
        },
      ),
    );
  }
}

class HeartButton extends StatelessWidget {
  const HeartButton({
    super.key,
    this.active = true,
    this.tooltip,
    this.color,
    this.inactiveColor,
    this.onPressed,
  });

  final bool active;
  final String? tooltip;
  final Color? color;
  final Color? inactiveColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedIconButton(
      active: active,
      duration: const Duration(milliseconds: 240),
      icon: Icon(
        active ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
      ),
      tooltip: tooltip,
      color: color ?? Colors.redAccent,
      inactiveColor: inactiveColor ?? theme.colorScheme.onSurface,
      iconSize: 24.0,
      onPressed: onPressed,
    );
  }
}
