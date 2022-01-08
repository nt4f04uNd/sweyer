import 'package:device_info/device_info.dart';
import 'package:sweyer/sweyer.dart';

/// Provides an information about the device.
class DeviceInfoControl extends Control {
  static DeviceInfoControl instance = DeviceInfoControl(); 

  /// Android SDK integer.
  int get sdkInt => _sdkInt;
  late int _sdkInt;

  @override
  Future<void> init() async {
    super.init();
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    _sdkInt = androidInfo.version.sdkInt;
  }
}
