
import 'dart:async';

/// Class to create change and control stream
class ManualStreamController {
  /// Stream controller used to create stream of changes on track list (just to notify)
  StreamController<void> _controller = StreamController<void>.broadcast();

  /// Get stream of notifier events about changes on track list
  Stream<void> get stream => _controller.stream;

  /// Emit change event
  void emitEvent() {
    _controller.add(null);
  }
}