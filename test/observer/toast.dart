import 'dart:collection';

import 'package:flutter/services.dart';

import '../test.dart';

/// An observer for toast messages from the flutter toast package.
class ToastChannelObserver {
  /// The method channel used by the flutter toast package.
  static const MethodChannel _channel = MethodChannel('PonnamKarthik/fluttertoast');
  final List<String> _toastMessagesLog = []; /// The messages of all recorded requested toasts.
  List<String> get toastMessagesLog => UnmodifiableListView(_toastMessagesLog);
  
  /// Create a new toast channel observer, which automatically
  /// unregisters any previously created observer.
  ToastChannelObserver(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) {
      if (call.method == 'showToast') {
        _toastMessagesLog.add(Map.castFrom(call.arguments)['msg'] as String);
        return null;
      }
      return null;  // Ignore unimplemented method calls
    });
  }
}
