import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../observer/observer.dart';
import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  testWidgets('permissions screen - shows when are no permissions and pressing the button requests permissions', (WidgetTester tester) async {
    await setUpAppTest(() {
      FakePermissions.instance.granted = false;
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

  testWidgets('app shows exit confirmation toast', (WidgetTester tester) async {
    await Prefs.confirmExitingWithBackButton.set(true);
    final ToastObserver toastObserver = ToastObserver(tester);
    final AppObserver appObserver = AppObserver(tester);
    await tester.runAppTest(() async {
      expect(
        await appObserver.haveCloseRequest(
          () => toastObserver.expectShowsToast(
            BackButtonInterceptor.popRoute,
            message: l10n.pressOnceAgainToExit,
            reason: 'Expected the app to ask for confirmation before exiting',
          ),
        ),
        isFalse,
        reason: 'Expected the app not to close after showing the toast',
      );
      await tester.binding.delayed(const Duration(seconds: 5));
      expect(
        await appObserver.haveCloseRequest(
          () => toastObserver.expectShowsToast(
            BackButtonInterceptor.popRoute,
            message: l10n.pressOnceAgainToExit,
            reason: 'Expected the app to ask for confirmation before exiting after the previous message timed out',
          ),
        ),
        isFalse,
        reason: 'Expected the app not to close after showing the toast',
      );
      expect(
        await appObserver.haveCloseRequest(
          () => toastObserver.expectShowsNoToast(
            BackButtonInterceptor.popRoute,
            reason: 'Expected the app to show no toast when pressing the back button a second time',
          ),
        ),
        isTrue,
      );
    });
  });

  testWidgets('app respects the exit confirmation preference', (WidgetTester tester) async {
    await Prefs.confirmExitingWithBackButton.set(true);
    final ToastObserver toastObserver = ToastObserver(tester);
    final AppObserver appObserver = AppObserver(tester);
    await tester.runAppTest(() async {
      expect(
        await appObserver.haveCloseRequest(
          () => toastObserver.expectShowsToast(
            BackButtonInterceptor.popRoute,
            message: l10n.pressOnceAgainToExit,
            reason: 'Expected the app to ask for confirmation before exiting',
          ),
        ),
        isFalse,
        reason: 'Expected the app not to close after showing the toast',
      );
      await Prefs.confirmExitingWithBackButton.set(false);
      await tester.binding.delayed(const Duration(seconds: 5));
      expect(
        await appObserver.haveCloseRequest(
          () => toastObserver.expectShowsNoToast(
            BackButtonInterceptor.popRoute,
            reason: 'Expected the app to show no toast when pressing the back button after disabling it',
          ),
        ),
        isTrue,
        reason: 'Expected the confirmation toast to be disabled',
      );
    });
  });
}
