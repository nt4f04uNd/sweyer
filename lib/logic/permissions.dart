import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Permissions instance = Permissions();

  /// Whether storage permission is granted
  late PermissionStatus _permissionStorageStatus;
  late PermissionStatus _permissionAudioStatus;

  /// Returns true if permissions were granted
  bool get granted => _permissionStorageStatus == PermissionStatus.granted
      || _permissionAudioStatus == PermissionStatus.granted;

  /// Returns true if permissions were not granted
  bool get notGranted => !granted;

  Future<void> init() async {
    _permissionStorageStatus = await Permission.storage.status;
    _permissionAudioStatus = await Permission.audio.status;
  }

  Future<void> requestClick() async {
    final responses = await [Permission.storage, Permission.audio].request();
    _permissionStorageStatus = responses[Permission.storage] ?? PermissionStatus.denied;
    _permissionAudioStatus = responses[Permission.audio] ?? PermissionStatus.denied;
    if (granted) {
      await ContentControl.instance.init();
    } else if (_permissionStorageStatus == PermissionStatus.permanentlyDenied ||
        _permissionAudioStatus == PermissionStatus.permanentlyDenied) {
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
