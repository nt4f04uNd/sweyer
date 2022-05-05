import 'package:flutter/services.dart';

import '../test.dart';

/// An observer for the application state. 
class AppObserver {
  
  /// Whether a close request was recorded.
  bool _haveCloseRequest = false;

  /// Create a new application state observer, which automatically
  /// unregisters any previously created observer.
  AppObserver(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
      if (call.method == 'SystemNavigator.pop') {
        _haveCloseRequest = true;
        return null;
      }
      return null;  // Ignore unimplemented method calls
    });
  }

  /// Execute the provided [callable] and return whether
  /// an application close request was made by it. 
  Future<bool> haveCloseRequest(Future<void> Function() callable) async {
    _haveCloseRequest = false;
    await callable();
    return _haveCloseRequest;
  }
}
