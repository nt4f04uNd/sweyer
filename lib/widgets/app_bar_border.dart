import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Themed border divider that can be shown and hidden with animation.
///
/// Used in list views when they are scrolled and displayed below the [AppBar],
/// instead of elevation.
class AppBarBorder extends StatelessWidget {
  const AppBarBorder({super.key, this.shown = true});

  final bool shown;

  static const height = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 400),
      color: shown ? theme.appThemeExtension.appBarBorderColor : theme.colorScheme.secondary.withValues(alpha: 0.0),
      height: height,
    );
  }
}
