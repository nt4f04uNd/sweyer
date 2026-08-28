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
    final textScaleFactorOverwrite = ref.watch(textScaleFactorStateNotifierProvider);
    return textScaleFactorOverwrite == null
        ? child
        : MediaQuery.fromView(
            view: View.of(context),
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactorOverwrite),
                ),
                child: child,
              ),
            ),
          );
  }
}
