import 'package:flutter/services.dart';

import '../test.dart';

/// An observer for toast messages from the flutter toast package.
class ToastObserver {
  /// The method channel used by the flutter toast package
  static const MethodChannel _channel = MethodChannel('PonnamKarthik/fluttertoast');
  /// The arguments for the last requested toast message.
  Map<String, dynamic>? lastToastMessage;

  /// Create a new toast observer, which automatically
  ///  unregisters any previously created observer.
  ToastObserver(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) {
      if (call.method == 'showToast') {
        lastToastMessage = Map.castFrom(call.arguments);
        return null;
      }
      return null;  // Ignore unimplemented method calls
    });
  }

  /// Verify that the provided [callable] shows a toast.
  /// If provided, also verify that the toast showed the given [message].
  /// If no toast was shown or the message doesn't match,
  /// fail with the given [reason].
  Future<void> expectShowsToast(Future<void> Function() callable, {String? message, String? reason}) async {
    lastToastMessage = null;
    await callable();
    expect(lastToastMessage, isNotNull,
        reason: 'Expected a toast to be shown' + (reason != null ? ': $reason' : ''));
    if (message != null) {
      expect(lastToastMessage!['msg'] as String?, equals(message),
          reason: 'Expected a toast to show the expected message' + (reason != null ? ': $reason' : ''));
    }
  }

  /// Verify that the provided [callable] doesn't show a toast.
  /// Otherwise fail with the given [reason].
  Future<void> expectShowsNoToast(Future<void> Function() callable, {String? reason}) async {
    lastToastMessage = null;
    await callable();
    expect(lastToastMessage, isNull,
        reason: 'Expected no toast to be shown' + (reason != null ? ': $reason' : ''));
  }
}
