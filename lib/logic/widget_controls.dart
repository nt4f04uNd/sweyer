import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

/// Controller for handling widget control actions.
class WidgetControlsHandler {
  static WidgetControlsHandler instance = WidgetControlsHandler();

  /// Method channel for communication with the widget.
  final MethodChannel _playerControlsChannel = const MethodChannel('com.nt4f04und.sweyer/player_controls');

  /// Initialize the widget controls handler.
  void init() {
    _playerControlsChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle method calls from the widget.
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'playPause':
        await PlayerManager.instance.playPause();
        break;
      case 'next':
        await PlayerManager.instance.playNext();
        break;
      case 'previous':
        await PlayerManager.instance.playPrev();
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'The widget_controls plugin for Flutter doesn\'t implement the method: ${call.method}',
        );
    }
  }
}
