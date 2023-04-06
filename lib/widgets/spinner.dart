import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  const Spinner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
        theme.colorScheme.onBackground,
      ),
    );
  }
}
