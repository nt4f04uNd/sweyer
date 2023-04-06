import 'package:flutter/material.dart';

class FavoriteIndicator extends StatelessWidget {
  const FavoriteIndicator({
    Key? key,
    required this.shown,
    this.size,
  }) : super(key: key);

  final bool shown;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: child,
      ),
      child: !shown
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: size ?? 18.0,
              ),
            ),
    );
  }
}
