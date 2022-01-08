import 'package:permission_handler/permission_handler.dart';

import '../test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpAppTest();
  });

  testWidgets('permissions screen - shows when are no permissions and pressing the button requests permissions', (WidgetTester tester) async {
    await setUpAppTest(() {
      FakePermissions.instance.permissionStorageStatus = PermissionStatus.denied;
    });
    await tester.runAppTest(() async {
      expect(Permissions.instance.granted, false);
      await tester.tap(find.text(l10n.grant));
      expect(Permissions.instance.granted, true);
    });
  });

  testWidgets('searching screen - shows when permissions are granted and searching for tracks', (WidgetTester tester) async {
    // Use fake
    ContentControl.instance.dispose();
    final fake = FakeContentControl();
    ContentControl.instance = fake;
    fake.init();

    await tester.runAppTest(() async {
      expect(Permissions.instance.granted, true);
      expect(ContentControl.instance.disposed.value, true);
      expect(ContentControl.instance.initializing, false);
      expect(ContentControl.instance.stateNullable, null);

      // Fake ContentControl.init in a way to trigger the home screen rebuild
      fake.initializing = true;
      fake.stateNullable = ContentState();
      fake.disposed.value = false;

      expect(ContentControl.instance.initializing, true);

      await tester.pump();

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
    await setUpAppTest(() {
      FakeContentChannel.instance.songs = [];
    });
    await tester.runAppTest(() async {
      expect(Permissions.instance.granted, true);
      expect(find.text(l10n.noMusic + ' :('), findsOneWidget);

      // Test refresh
      FakeContentChannel.instance.songs = [songWith()];
      // Triggering refresh will cause a real async work
      await tester.runAsync(() {
        return tester.tap(find.text(l10n.refresh));
      });
      expect(ContentControl.instance.state.allSongs.songs, [songWith()]);
    });
  });
}
