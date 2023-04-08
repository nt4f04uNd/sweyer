import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../test.dart';

/// An observer for platform permission requests.
class PermissionsChannelObserver {
  /// The method channel used by the flutter permissions package
  static const MethodChannel _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  /// The permissions which were requested.
  List<Permission> get requestedPermissions => UnmodifiableListView(_requestedPermissions);
  final List<Permission> _requestedPermissions = [];

  /// The permissions which were checked.
  List<Permission> get checkedPermissions => UnmodifiableListView(_checkedPermissions);
  final List<Permission> _checkedPermissions = [];

  /// The amount of attempts to open the permission settings.
  int get openSettingsRequests => _openSettingsRequests;
  int _openSettingsRequests = 0;

  /// Whether an attempt to open the settings should succeed.
  bool isOpeningSettingsSuccessful = true;

  /// Permissions whose values are specified, all other permissions are implicitly granted.
  final Map<Permission, Future<PermissionStatus> Function()> _specifiedPermissions = {};

  /// Create a new permissions observer, which automatically
  /// unregisters any previously created observer.
  PermissionsChannelObserver(TestWidgetsFlutterBinding binding) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'requestPermissions':
          final Map<int, int> permissionStatuses = {};
          for (final int permissionValue in List<int>.from(call.arguments)) {
            final permission = Permission.byValue(permissionValue);
            _requestedPermissions.add(permission);
          }
          for (final int permissionValue in List<int>.from(call.arguments)) {
            final permission = Permission.byValue(permissionValue);
            final permissionStatus = await getStatus(permission);
            permissionStatuses[permissionValue] = permissionStatus.index;
          }
          return permissionStatuses;
        case 'checkPermissionStatus':
          final Permission permission = Permission.byValue(call.arguments as int);
          _checkedPermissions.add(permission);
          final status = await getStatus(permission);
          return status.index;
        case 'openAppSettings':
          _openSettingsRequests++;
          return isOpeningSettingsSuccessful;
      }
      return null; // Ignore unimplemented method calls.
    });
  }

  /// Get the status of the given [permission].
  Future<PermissionStatus> getStatus(Permission permission) {
    return (_specifiedPermissions[permission] ?? () async => PermissionStatus.granted)();
  }

  /// Set the status value of the [permission] to the result of the
  /// [resolvable], which will be resolved when the permission status is
  /// first requested.
  void setPermissionResolvable(Permission permission, Future<PermissionStatus> Function() resolvable) {
    _specifiedPermissions[permission] = resolvable;
  }

  /// Set the [status] for the [permission].
  void setPermission(Permission permission, PermissionStatus status) {
    if (status == PermissionStatus.granted) {
      _specifiedPermissions.remove(permission);
    } else {
      setPermissionResolvable(permission, () async => status);
    }
  }
}
