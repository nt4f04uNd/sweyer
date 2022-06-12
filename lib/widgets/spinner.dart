import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class Spinner extends StatelessWidget {
  const Spinner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
        ThemeControl.instance.theme.colorScheme.onBackground,
      ),
    );
  }
}
