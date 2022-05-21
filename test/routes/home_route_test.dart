import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweyer/constants.dart';

import '../observer/observer.dart';
import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  testWidgets('permissions screen - shows when are no permissions and pressing the button requests permissions', (WidgetTester tester) async {
    late PermissionsChannelObserver permissionsObserver;
    await setUpAppTest(() {
      permissionsObserver = PermissionsChannelObserver(tester.binding);
      permissionsObserver.setPermission(Permission.storage, PermissionStatus.denied);
    });
    await tester.runAppTest(() async {
      expect(permissionsObserver.checkedPermissions, [Permission.storage],
          reason: 'Should always check the storage permission on startup');
      expect(find.byType(Home), findsNothing, reason: 'Permissions are not granted yet');
      final permissionGrantCompleter = Completer<PermissionStatus>(); 
      permissionsObserver.setPermissionResolvable(Permission.storage, () => permissionGrantCompleter.future);
      await tester.tap(find.text(l10n.grant));
      expect(permissionsObserver.requestedPermissions, [Permission.storage]);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Indicate while waiting for the permission to be granted');
      permissionGrantCompleter.complete(PermissionStatus.granted);
      await tester.pumpAndSettle();
      expect(find.byType(Home), findsOneWidget);
    });
  });

  testWidgets('permissions screen - shows toast and opens settings when permissions are denied', (WidgetTester tester) async {
    late PermissionsChannelObserver permissionsObserver;
    await setUpAppTest(() {
      permissionsObserver = PermissionsChannelObserver(tester.binding);
      permissionsObserver.setPermission(Permission.storage, PermissionStatus.denied);
    });
    await tester.runAppTest(() async {
      permissionsObserver.setPermission(Permission.storage, PermissionStatus.permanentlyDenied);
      permissionsObserver.isOpeningSettingsSuccessful = false;
      final ToastChannelObserver toastObserver = ToastChannelObserver(tester);
      await tester.tap(find.text(l10n.grant));
      expect(permissionsObserver.openSettingsRequests, 1);
      expect(toastObserver.toastMessagesLog, [l10n.allowAccessToExternalStorageManually, l10n.openAppSettingsError]);

      permissionsObserver.isOpeningSettingsSuccessful = true;
      await tester.tap(find.text(l10n.grant));
      expect(permissionsObserver.openSettingsRequests, 2);
      expect(
          toastObserver.toastMessagesLog,
          [l10n.allowAccessToExternalStorageManually, l10n.openAppSettingsError, l10n.allowAccessToExternalStorageManually]);
    });
  });
  
  testWidgets('searching screen - shows when permissions are granted and searching for tracks', (WidgetTester tester) async {
    // Use fake
    ContentControl.instance.dispose();
    final fake = FakeContentControl();
    ContentControl.instance = fake;
    fake.init();

    expect(Permissions.instance.granted, true);
    expect(ContentControl.instance.disposed.value, true);
    expect(ContentControl.instance.initializing, false);
    expect(ContentControl.instance.stateNullable, null);

    // Fake ContentControl.init in a way to trigger the home screen rebuild
    fake.initializing = true;
    fake.stateNullable = ContentState();
    fake.disposed.value = false;

    expect(ContentControl.instance.initializing, true);

    await tester.runAppTest(() async {
      // Expect appropriate ui
      expect(find.text(l10n.searchingForTracks), findsOneWidget);
      expect(find.byType(Spinner), findsOneWidget);
    });
  });

  testWidgets('home screen - shows when permissions are granted and not searching for tracks', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      expect(Permissions.instance.granted, true);
      expect(find.byType(Home), findsOneWidget);
    });
  });

  testWidgets('no songs screen - shows when the library is empty and pressing the button performs refetching', (WidgetTester tester) async {
    // TODO: because of `MusicPlayer.instance.stop` at the end of `runAppTest`, this test will print an error in console, but not actually fail, because the exception is catched. Ideally I should somehow hide that
    await setUpAppTest(() {
      FakeContentChannel.instance.songs = [];
    });
    await tester.runAppTest(() async {
      expect(Permissions.instance.granted, true);
      expect(find.text(l10n.noMusic), findsOneWidget);

      // Test refresh
      FakeContentChannel.instance.songs = [songWith()];
      // Triggering refresh will cause a real async work
      await tester.runAsync(() {
        return tester.tap(find.text(l10n.refresh));
      });
      expect(ContentControl.instance.state.allSongs.songs, [songWith()]);
    });
  });

  testWidgets('app shows exit confirmation toast if enabled in the preferences', (WidgetTester tester) async {
    await Settings.confirmExitingWithBackButton.set(true);
    await tester.runAppTest(() async {
      final SystemChannelObserver systemObserver = SystemChannelObserver(tester);
      final ToastChannelObserver toastObserver = ToastChannelObserver(tester);
      await BackButtonInterceptor.popRoute();
      expect(toastObserver.toastMessagesLog, [l10n.pressOnceAgainToExit]);
      expect(systemObserver.closeRequests, 0, reason: 'The app must not close after showing the toast');
      await tester.binding.delayed(Config.BACK_PRESS_CLOSE_TIMEOUT + const Duration(milliseconds: 1));
      await BackButtonInterceptor.popRoute();
      expect(toastObserver.toastMessagesLog, [l10n.pressOnceAgainToExit, l10n.pressOnceAgainToExit],
          reason: 'The previous message timed out');
      expect(systemObserver.closeRequests, 0, reason: 'The app must not close after showing the toast');
      await tester.binding.delayed(Config.BACK_PRESS_CLOSE_TIMEOUT - const Duration(milliseconds: 1));
      await BackButtonInterceptor.popRoute();
      expect(toastObserver.toastMessagesLog, [l10n.pressOnceAgainToExit, l10n.pressOnceAgainToExit]);
      expect(systemObserver.closeRequests, 1);
    });
  });

  testWidgets('app does not ask for exit confirmation if disabled in the preferences', (WidgetTester tester) async {
    await Settings.confirmExitingWithBackButton.set(false);
    await tester.runAppTest(() async {
      final SystemChannelObserver systemObserver = SystemChannelObserver(tester);
      final ToastChannelObserver toastObserver = ToastChannelObserver(tester);
      await BackButtonInterceptor.popRoute();
      expect(toastObserver.toastMessagesLog, []);
      expect(systemObserver.closeRequests, 1);
    });
  });
}
