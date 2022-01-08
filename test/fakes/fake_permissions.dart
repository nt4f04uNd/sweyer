// ignore_for_file: overridden_fields

import 'package:permission_handler/permission_handler.dart';
import '../test.dart';

class FakePermissions extends Permissions {
  FakePermissions() {
    instance = this;
  }
  static late FakePermissions instance;

  @override
  PermissionStatus permissionStorageStatus = PermissionStatus.granted;

  @override
  Future<void> init() async {}

  @override
  Future<void> requestClick() async {
    permissionStorageStatus = PermissionStatus.granted;
  }
}
