import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_app_switches_state.freezed.dart';

@freezed
class MaterialAppSwitchesState with _$MaterialAppSwitchesState {
  const factory MaterialAppSwitchesState({
    @Default(false) bool showPerformanceOverlay,
    @Default(false) bool checkerboardRasterCacheImages,
    @Default(false) bool showSemanticsDebugger,
  }) = _MaterialAppSwitchesState;
}
