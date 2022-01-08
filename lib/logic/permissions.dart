import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Permissions instance = Permissions();

  /// Whether storage permission is granted
  late PermissionStatus _permissionStorageStatus;

  /// Returns true if permissions were granted
  bool get granted => _permissionStorageStatus == PermissionStatus.granted;

  /// Returns true if permissions were not granted
  bool get notGranted => !granted;

  Future<void> init() async {
    _permissionStorageStatus = await Permission.storage.status;
  }

  Future<void> requestClick() async {
    _permissionStorageStatus = await Permission.storage.request();
    if (_permissionStorageStatus == PermissionStatus.granted) {
      await ContentControl.instance.init();
    } else if (_permissionStorageStatus == PermissionStatus.permanentlyDenied) {
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
