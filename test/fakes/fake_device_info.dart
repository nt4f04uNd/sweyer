import '../test.dart';

class FakeDeviceInfoControl extends DeviceInfoControl {
  FakeDeviceInfoControl() {
    instance = this;
  }
  static late FakeDeviceInfoControl instance;

  int androidSdkInt = 30;

  @override
  bool get useScopedStorageForFileModifications => androidSdkInt >= 30;

  @override
  bool get useAudioPermission => androidSdkInt >= 33;

  @override
  bool get useBytesForAlbumArt => defaultTargetPlatform == TargetPlatform.iOS || androidSdkInt >= 29;

  @override
  // ignore: must_call_super
  Future<void> init() async {}
}
