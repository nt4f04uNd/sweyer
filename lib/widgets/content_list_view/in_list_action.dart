import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Action to be displayed directly in the content list.
class InListContentAction extends StatefulWidget {
  /// Create action with paddings for song list.
  const InListContentAction.song({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
    this.iconColor,
    this.textColor,
    this.splashColor,
  }) : horizontalPadding = kSongTileHorizontalPadding;

  /// Create action with paddings for persistent queue list.
  const InListContentAction.persistentQueue({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
    this.iconColor,
    this.textColor,
    this.splashColor,
  }) : horizontalPadding = kPersistentQueueTileHorizontalPadding;

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final Color? splashColor;
  final double horizontalPadding;

  @override
  State<InListContentAction> createState() => _InListContentActionState();
}

class _InListContentActionState extends State<InListContentAction> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final fadeAnimation = Tween(
    begin: 0.2,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  Color? previousColor;

  bool get enabled => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    if (enabled) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant InListContentAction oldWidget) {
    previousColor = oldWidget.color;
    if (oldWidget.onTap != widget.onTap) {
      if (enabled) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: fadeAnimation,
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        tween: ColorTween(begin: previousColor, end: widget.color ?? Colors.transparent),
        builder: (context, value, child) => Material(
          color: value,
          child: child,
        ),
        child: NFInkWell(
          splashColor: widget.splashColor,
          onTap: widget.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            height: kSongTileHeight(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: kSongTileArtSize,
                  width: kSongTileArtSize,
                  decoration: BoxDecoration(
                    color: theme.appThemeExtension.glowSplashColor,
                    borderRadius: const BorderRadius.all(Radius.circular(kArtBorderRadius)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    size: 36.0,
                    color: widget.iconColor,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      style: theme.textTheme.titleLarge?.copyWith(color: widget.textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreatePlaylistInListAction extends StatefulWidget {
  const CreatePlaylistInListAction({
    super.key,
    this.enabled = true,
  });

  final bool enabled;

  @override
  State<CreatePlaylistInListAction> createState() => _CreatePlaylistInListActionState();
}

class _CreatePlaylistInListActionState extends State<CreatePlaylistInListAction> with TickerProviderStateMixin {
  void _handleTap() {
    ShowFunctions.instance.showCreatePlaylist(this, context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return InListContentAction.persistentQueue(
      onTap: widget.enabled ? _handleTap : null,
      icon: Icons.add_rounded,
      text: l10n.newPlaylist,
    );
  }
}
