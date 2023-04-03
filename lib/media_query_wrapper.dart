import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweyer/sweyer.dart';

class MediaQueryWrapper extends ConsumerWidget {
  const MediaQueryWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScaleFactor = ref.watch(textScaleFactorStateNotifierProvider.select((value) => value));

    return MediaQuery(
      data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        textScaleFactor: textScaleFactor,
      ),
      child: child,
    );
  }
}
