import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  testWidgets('SongTile - tapping opens player route', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      await tester.tap(find.byType(SongTile));
      await tester.pumpAndSettle();
      expect(playerRouteController.value, 1.0);
    });
  });

  testWidgets('AlbumTile - tapping opens album route', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Open albums tab
      await tester.tap(find.byIcon(Album.icon));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(typeOf<PersistentQueueTile<Album>>()));
      await tester.pumpAndSettle();
      final route = tester.widget<PersistentQueueRoute>(find.byType(typeOf<PersistentQueueRoute>()));
      expect(route.arguments, isA<PersistentQueueArguments<Album>>());
    });
  });

  testWidgets('PlaylistTile - tapping opens playlist route', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Open playlists tab
      await tester.tap(find.byIcon(Playlist.icon));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(typeOf<PersistentQueueTile<Playlist>>()));
      await tester.pumpAndSettle();
      final route = tester.widget<PersistentQueueRoute>(find.byType(typeOf<PersistentQueueRoute>()));
      expect(route.arguments, isA<PersistentQueueArguments<Playlist>>());
    });
  });

  testWidgets('ArtistTile - tapping opens artist route', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Open artists tab
      await tester.tap(find.byIcon(Artist.icon));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(typeOf<ArtistTile>()));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<ArtistRoute>()), findsOneWidget);
    });
  });
}
