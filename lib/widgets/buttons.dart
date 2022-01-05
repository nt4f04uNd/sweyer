import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Button to switch loop mode
class LoopButton extends StatelessWidget {
  const LoopButton({Key? key}) : super(key: key);

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
          size: 40.0,
          iconSize: textScaleFactor * NFConstants.iconSize,
          active: snapshot.data!,
          onPressed: player.switchLooping,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return StreamBuilder(
      stream: ContentControl.state.onContentChange,
      builder: (context, snap) => AnimatedIconButton(
        icon: const Icon(Icons.shuffle_rounded),
        color: ThemeControl.theme.colorScheme.onSurface,
        size: 40.0,
        iconSize: textScaleFactor * NFConstants.iconSize,
        active: ContentControl.state.queues.shuffled,
        onPressed: () {
          ContentControl.setQueue(
            shuffled: !ContentControl.state.queues.shuffled,
          );
        },
      ),
    );
  }
}

/// Icon button that opens settings page.
class SettingsButton extends StatelessWidget {
  const SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NFIconButton(
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => AppRouter.instance.goto(AppRoutes.settings),
    );
  }
}


/// A button with text and icon, used to start queue playback.
/// 
/// Also used in:
///  * [PlayQueueButton]
///  * [ShuffleQueueButton]
class AppButton extends StatefulWidget {
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.splashColor,
    this.borderRadius = 15.0,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
  }) : super(key: key);

  final String text;
  final Icon? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Color? splashColor;
  final double borderRadius;
  final double? fontSize;
  final FontWeight fontWeight;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240)
  )
  ..value = disabled ? 0.0 : 1.0;
  late final colorAnimation = ColorTween(
    begin: ThemeControl.theme.colorScheme.onSurface.withOpacity(0.12),
    end: widget.color ?? ThemeControl.theme.colorScheme.primary,
  ).animate(CurvedAnimation(
    parent: controller,
    curve:  Curves.easeOut,
    reverseCurve: Curves.easeIn,
  ));
  late final textColorAnimation = ColorTween(
    begin: ThemeControl.theme.colorScheme.onSurface.withOpacity(0.38),
    end: widget.textColor ?? ThemeControl.theme.colorScheme.onPrimary
  ).animate(CurvedAnimation(
    parent: controller,
    curve:  Curves.easeOut,
    reverseCurve: Curves.easeIn,
  ));

  bool get disabled => widget.onPressed == null;

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

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.0),
      child: Text(widget.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => ElevatedButton(
        onPressed: widget.onPressed,
        style: const ElevatedButton(child: null, onPressed: null).defaultStyleOf(context).copyWith(
          backgroundColor: MaterialStateProperty.all(colorAnimation.value),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20.0)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            )
          ),
          foregroundColor: MaterialStateProperty.all(textColorAnimation.value),
          overlayColor: MaterialStateProperty.all(widget.splashColor ?? Constants.Theme.glowSplashColorOnContrast.auto),
          splashFactory: NFListTileInkRipple.splashFactory,
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          textStyle: MaterialStateProperty.all(TextStyle(
            fontFamily: ThemeControl.theme.textTheme.headline1!.fontFamily,
            fontWeight: widget.fontWeight,
            fontSize: widget.fontSize,
          )),
        ),
        child: widget.icon == null ? Text(widget.text): Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon!,
            const SizedBox(width: 6.0),
            _buildText(),
            const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }
}

/// Used to start queue playback.
class PlayQueueButton extends StatelessWidget {
  const PlayQueueButton({Key? key, required this.onPressed}) : super(key: key);

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
  const ShuffleQueueButton({Key? key, required this.onPressed}) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return AppButton(
      text: l10n.shuffleContentList,
      icon: const Icon(Icons.shuffle_rounded, size: 22.0),
      color: Constants.Theme.contrast.auto,
      textColor: ThemeControl.theme.colorScheme.background,
      borderRadius: 4.0,
      fontSize: 15.0,
      fontWeight: FontWeight.w700,
      onPressed: onPressed,
    );
  }
}