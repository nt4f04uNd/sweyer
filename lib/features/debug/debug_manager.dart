import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweyer/sweyer.dart';

final debugManagerProvider = Provider(
  (ref) => DebugManager(),
);

class DebugManager {
  OverlayEntry? _entry;

  void showOverlay() {
    if (_entry != null) {
      return;
    }
    _entry = OverlayEntry(builder: (context) => const DebugOverlayWidget());
    AppRouter.instance.navigatorKey.currentState!.overlay!.insert(_entry!);
  }

  void closeOverlay() {
    _entry?.remove();
    _entry = null;
  }
}
