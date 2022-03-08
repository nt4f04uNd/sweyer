import 'package:golden_toolkit/golden_toolkit.dart';

import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  group('player_route', () {
    testGoldens('idle_player_route', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        await tester.tap(find.byType(SongTile));
        await tester.pumpAndSettle();
        expect(playerRouteController.value, 1.0);
      }, goldenCaptureCallback: () => screenMatchesGoldenWithTolerance(tester, 'player_route.idle_player_route'));
    });
  });

  group('tabs_route', () {
    testGoldens('idle_songs_tab', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        await tester.pumpAndSettle();
      }, goldenCaptureCallback: () => screenMatchesGoldenWithTolerance(tester, 'tabs_route.idle_songs_tab'));
    });
  
    testGoldens('idle_albums_tab', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        await tester.tap(find.byIcon(Album.icon));
        await tester.pumpAndSettle();
        expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsOneWidget);
      }, goldenCaptureCallback: () => screenMatchesGoldenWithTolerance(tester, 'tabs_route.idle_albums_tab'));
    });

    testGoldens('idle_playlists_tab', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        await tester.tap(find.byIcon(Playlist.icon));
        await tester.pumpAndSettle();
        expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsOneWidget);
      }, goldenCaptureCallback: () => screenMatchesGoldenWithTolerance(tester, 'tabs_route.idle_playlists_tab'));
    });

    testGoldens('idle_artists_tab', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        await tester.tap(find.byIcon(Artist.icon));
        await tester.pumpAndSettle();
        expect(find.byType(typeOf<ArtistTile>()), findsOneWidget);
      }, goldenCaptureCallback: () => screenMatchesGoldenWithTolerance(tester, 'tabs_route.idle_artists_tab'));
    });
  });
}
