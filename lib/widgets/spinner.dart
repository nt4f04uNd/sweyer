import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
        theme.colorScheme.onSecondaryContainer,
      ),
    );
  }
}
