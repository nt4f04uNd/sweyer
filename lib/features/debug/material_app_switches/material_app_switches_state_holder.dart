import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweyer/sweyer.dart';

final materialAppSwitchesStateHolderProvider =
    StateNotifierProvider<MaterialAppSwitchesStateHolder, MaterialAppSwitchesState>(
  (ref) => MaterialAppSwitchesStateHolder(),
);

class MaterialAppSwitchesStateHolder extends StateNotifier<MaterialAppSwitchesState> {
  MaterialAppSwitchesStateHolder() : super(const MaterialAppSwitchesState());

  void setShowPerformanceOverlay(bool value) => state = state.copyWith(showPerformanceOverlay: value);

  void setCheckerboardRasterCacheImages(bool value) => state = state.copyWith(checkerboardRasterCacheImages: value);

  void setShowSemanticsDebugger(bool value) => state = state.copyWith(showSemanticsDebugger: value);
}
