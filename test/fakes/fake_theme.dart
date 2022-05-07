import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

class FakeThemeControl extends ThemeControl {
  FakeThemeControl() {
    instance = this;
  }
  static late FakeThemeControl instance;

  @override
  Duration get themeChangeDuration => Duration.zero;

  @override
  Future<void> initSystemUi() async {
    SystemUiStyleController.instance.setSystemUiOverlay(const SystemUiOverlayStyle());
  }
}