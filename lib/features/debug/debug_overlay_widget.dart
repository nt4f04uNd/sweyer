import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweyer/sweyer.dart';

class DebugOverlayWidget extends ConsumerWidget {
  const DebugOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugManager = ref.watch(debugManagerProvider);
    final theme = Theme.of(context);

    const overlayHeight = 175.0;
    const overlayAreaPadding = EdgeInsets.only(
      left: 20.0,
      right: 20.0,
    );

    return Padding(
      padding: overlayAreaPadding,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: overlayHeight,
            padding: const EdgeInsets.all(20.0),
            color: Colors.purpleAccent,
            child: Container(
              color: theme.colorScheme.secondaryContainer,
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: debugManager.closeOverlay,
                            ),
                          ],
                        ),
                        const DebugTextScaleFactorSlider(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
