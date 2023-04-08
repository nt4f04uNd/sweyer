import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Permissions instance = Permissions();

  /// Whether audio access permission is granted
  late PermissionStatus _permissionAudioStatus;

  /// Returns true if permissions were granted
  bool get granted => _permissionAudioStatus == PermissionStatus.granted;

  /// Returns true if permissions were not granted
  bool get notGranted => !granted;

  /// The permission to use when requesting access to the audio files on the device
  Permission get _audioPermission =>
      DeviceInfoControl.instance.useAudioPermission ? Permission.audio : Permission.storage;

  Future<void> init() async {
    _permissionAudioStatus = await _audioPermission.status;
  }

  Future<void> requestClick() async {
    final responses = await [Permission.storage, Permission.audio].request();
    _permissionAudioStatus = responses[_audioPermission] ?? PermissionStatus.denied;
    if (granted) {
      await ContentControl.instance.init();
    } else if (_permissionAudioStatus == PermissionStatus.permanentlyDenied) {
      final l10n = staticl10n;
      await ShowFunctions.instance.showToast(
        msg: l10n.allowAccessToExternalStorageManually,
      );
      if (!(await openAppSettings())) {
        await Fluttertoast.cancel();
        await ShowFunctions.instance.showToast(msg: l10n.openAppSettingsError);
      }
    }
  }
}
