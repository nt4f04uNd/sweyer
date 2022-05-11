import 'package:flutter/services.dart';

import '../test.dart';

/// An observer for toast messages from the flutter toast package.
class ToastChannelObserver {
  /// The method channel used by the flutter toast package
  static const MethodChannel _channel = MethodChannel('PonnamKarthik/fluttertoast');
  Map<String, dynamic>? _lastToastArguments;  /// The arguments for the last requested toast message.
  String? get lastToastMessage {
    final lastArguments = _lastToastArguments;
    clearLastToast();
    return lastArguments?['msg'] as String?;
  }
  
  /// Create a new toast channel observer, which automatically
  ///  unregisters any previously created observer.
  ToastChannelObserver(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) {
      if (call.method == 'showToast') {
        _lastToastArguments = Map.castFrom(call.arguments);
        return null;
      }
      return null;  // Ignore unimplemented method calls
    });
  }

  /// Forget the last received toast.
  void clearLastToast() {
    _lastToastArguments = null;
  }
}
