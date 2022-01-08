import '../test.dart';

class FakeDeviceInfoControl extends DeviceInfoControl {
  FakeDeviceInfoControl() {
    instance = this;
  }
  static late FakeDeviceInfoControl instance;

  @override
  int sdkInt = 30;

  @override
  // ignore: must_call_super
  Future<void> init() async {}
}
