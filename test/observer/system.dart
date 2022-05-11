import 'package:flutter/services.dart';

import '../test.dart';

/// An observer for the system channel. 
class SystemChannelObserver {
  
  int _closeRequests = 0;  /// How many close request was recorded since the last observation.
  int get closeRequests {
    final numRequests = _closeRequests;
    clearCloseRequest();
    return numRequests;
  } 

  /// Create a new system channel observer, which automatically
  /// unregisters any previously created observer.
  SystemChannelObserver(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
      if (call.method == 'SystemNavigator.pop') {
        _closeRequests++;
        return null;
      }
      return null;  // Ignore unimplemented method calls
    });
  }

  /// Reset the number of recorded close requests to zero.
  void clearCloseRequest() {
    _closeRequests = 0;
  }
}
