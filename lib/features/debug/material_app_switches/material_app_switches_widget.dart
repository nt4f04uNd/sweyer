import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweyer/sweyer.dart';

class MaterialAppSwitchesWidget extends ConsumerWidget {
  const MaterialAppSwitchesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = getl10n(context);
    final materialAppSwitchesStateHolder = ref.watch(materialAppSwitchesStateHolderProvider.notifier);
    final materialAppSwitchesState = ref.watch(materialAppSwitchesStateHolderProvider.select((value) => value));
    return Column(
      children: [
        SwitchListTile(
          title: Text(l10n.debugShowPerformanceOverlay),
          value: materialAppSwitchesState.showPerformanceOverlay,
          onChanged: materialAppSwitchesStateHolder.setShowPerformanceOverlay,
        ),
        SwitchListTile(
          title: Text(l10n.debugShowCheckerboardRasterCacheImages),
          value: materialAppSwitchesState.checkerboardRasterCacheImages,
          onChanged: materialAppSwitchesStateHolder.setCheckerboardRasterCacheImages,
        ),
        SwitchListTile(
          title: Text(l10n.debugShowSemanticsDebugger),
          value: materialAppSwitchesState.showSemanticsDebugger,
          onChanged: materialAppSwitchesStateHolder.setShowSemanticsDebugger,
        ),
      ],
    );
  }
}
