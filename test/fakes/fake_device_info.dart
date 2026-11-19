import '../test.dart';

class FakeDeviceInfoControl extends DeviceInfoControl {
  FakeDeviceInfoControl() {
    instance = this;
    androidSdkInt = 30;
  }
  static late FakeDeviceInfoControl instance;

  @override
  // ignore: must_call_super
  Future<void> init() async {}
}
