import '../test.dart';

class FakeDeviceInfoControl extends DeviceInfoControl {
  FakeDeviceInfoControl() {
    instance = this;
  }
  static late FakeDeviceInfoControl instance;

  int androidSdkInt = 30;

  @override
  bool get useScopedStorageForFileModifications =>
      defaultTargetPlatform == TargetPlatform.android && androidSdkInt >= 30;

  @override
  bool get useAudioPermission => defaultTargetPlatform == TargetPlatform.android && androidSdkInt >= 33;

  @override
  bool get useBytesForAlbumArt =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android && androidSdkInt >= 29;

  @override
  // ignore: must_call_super
  Future<void> init() async {}
}
