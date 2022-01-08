// ignore_for_file: overridden_fields

import '../test.dart';

class FakePermissions extends Permissions {
  FakePermissions() {
    instance = this;
  }
  static late FakePermissions instance;

  @override
  bool granted = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> requestClick() async {
    granted = true;
  }
}
