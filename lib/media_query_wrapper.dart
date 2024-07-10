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
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: ref.watch(textScaleFactorStateNotifierProvider.select((value) => value)),
          ),
          child: child,
        ),
      ),
    );
  }
}
