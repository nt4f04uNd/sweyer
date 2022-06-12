import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class DebugOverlay {
  DebugOverlay(WidgetBuilder builder) {
    assert(() {
      _entry = OverlayEntry(builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height / 2.5,
              bottom: 40,
              left: 0,
              right: 0,
              child: builder(context),
            ),
          ],
        );
      });
      HomeRouter.instance.navigatorKey.currentState!.overlay!.insert(_entry!);
      return true;
    }());
  }

  OverlayEntry? _entry;

  void dispose() {
    assert(() {
      final result = _entry != null;
      _entry!.remove();
      return result;
    }());
  }
}
