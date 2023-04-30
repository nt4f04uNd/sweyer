import 'package:flutter/material.dart';

import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  group('playlist add element selection screen', () {
    testWidgets('hides config button on insertion order config screen', (WidgetTester tester) async {
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlistWith()));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);

          // Open insertion settings
          await tester.tap(find.descendant(
            of: find.byType(SelectionActionsBar),
            matching: find.byIcon(Icons.settings_rounded).hitTestable(),
          ));
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsNothing);

          // Close insertion settings
          await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable());
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);
        });
      });
    });

    testWidgets('allows to finish insertion from insertion order config screen', (WidgetTester tester) async {
      final song0 = songWith(id: 0, title: 'Song 0');
      final song1 = songWith(id: 1, title: 'Song 1');
      final playlist = playlistWith(songIds: [song0.id]);
      await setUpAppTest(() {
        FakeSweyerPluginPlatform.instance.songs = [song0, song1];
        FakeSweyerPluginPlatform.instance.playlists = [playlist];
      });
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isFalse);

          // Open insertion settings
          await tester.tap(find.descendant(
            of: find.byType(SelectionActionsBar),
            matching: find.byIcon(Icons.settings_rounded).hitTestable(),
          ));
          await tester.pumpAndSettle();
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isFalse);

          // Close insertion settings
          await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable());
          await tester.pumpAndSettle();

          // Select Song 1
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song1.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isTrue);

          // Open insertion settings
          await tester.tap(find.descendant(
            of: find.byType(SelectionActionsBar),
            matching: find.byIcon(Icons.settings_rounded).hitTestable(),
          ));
          await tester.pumpAndSettle();
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isTrue);

          // Finish insertion
          await tester.tap(find.ancestor(of: find.text(l10n.done), matching: find.byType(ElevatedButton)));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(SongTile, song1.title).hitTestable(), findsOneWidget);
          expect(playlist.songs, orderedEquals([song0, song1]));
        });
      });
    });

    testWidgets('counts selection', (WidgetTester tester) async {
      final song0 = songWith(id: 0, title: 'Song 0');
      final song1 = songWith(id: 1, title: 'Song 1');
      final song2 = songWith(id: 2, title: 'Song 2');
      final playlist = playlistWith(songIds: [song0.id]);
      await setUpAppTest(() {
        FakeSweyerPluginPlatform.instance.songs = [song0, song1, song2];
        FakeSweyerPluginPlatform.instance.playlists = [playlist];
      });
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(find.descendant(of: find.byType(SelectionCounter), matching: find.text('0')), findsOneWidget);
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);

          // Select Song 1
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song1.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();
          expect(find.descendant(of: find.byType(SelectionCounter), matching: find.text('1')).hitTestable(),
              findsOneWidget);
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isTrue);

          // Select Song 2
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song2.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();
          expect(find.descendant(of: find.byType(SelectionCounter), matching: find.text('2')).hitTestable(),
              findsOneWidget);
          expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, l10n.done)).enabled, isTrue);
        });
      });
    });

    testWidgets('inserts at the end per default', (WidgetTester tester) async {
      final song0 = songWith(id: 0, title: 'Song 0');
      final song1 = songWith(id: 1, title: 'Song 1');
      final song2 = songWith(id: 2, title: 'Song 2');
      final playlist = playlistWith(songIds: [song0.id, song1.id]);
      await setUpAppTest(() {
        FakeSweyerPluginPlatform.instance.songs = [song0, song1, song2];
        FakeSweyerPluginPlatform.instance.playlists = [playlist];
      });
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);

          // Select Song 2
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song2.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();

          // Add selected Song 2 to playlist
          await tester.tap(find.ancestor(of: find.text(l10n.done), matching: find.byType(ElevatedButton)));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(SongTile, song2.title).hitTestable(), findsOneWidget);
          expect(playlist.songs, orderedEquals([song0, song1, song2]));
        });
      });
    });

    testWidgets('allows insertion at the beginning', (WidgetTester tester) async {
      final song0 = songWith(id: 0, title: 'Song 0');
      final song1 = songWith(id: 1, title: 'Song 1');
      final song2 = songWith(id: 2, title: 'Song 2');
      final playlist = playlistWith(songIds: [song0.id, song1.id]);
      await setUpAppTest(() {
        FakeSweyerPluginPlatform.instance.songs = [song0, song1, song2];
        FakeSweyerPluginPlatform.instance.playlists = [playlist];
      });
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);

          // Select Song 2
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song2.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();

          // Open insertion settings
          await tester.tap(find.descendant(
            of: find.byType(SelectionActionsBar),
            matching: find.byIcon(Icons.settings_rounded).hitTestable(),
          ));
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<InListContentAction>(find.widgetWithText(InListContentAction, l10n.insertAtTheBeginning))
                  .color,
              isNot(FakeThemeControl.instance.theme.colorScheme.primary));

          // Select insert at beginning
          await tester.tap(find.widgetWithText(InListContentAction, l10n.insertAtTheBeginning));
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<InListContentAction>(find.widgetWithText(InListContentAction, l10n.insertAtTheBeginning))
                  .color,
              FakeThemeControl.instance.theme.colorScheme.primary);

          // Add selected Song 2 to playlist
          await tester.tap(find.ancestor(of: find.text(l10n.done), matching: find.byType(ElevatedButton)));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(SongTile, song2.title).hitTestable(), findsOneWidget);
          expect(playlist.songs, orderedEquals([song2, song0, song1]));
        });
      });
    });

    testWidgets('allows insertion at any index', (WidgetTester tester) async {
      final song0 = songWith(id: 0, title: 'Song 0');
      final song1 = songWith(id: 1, title: 'Song 1');
      final song2 = songWith(id: 2, title: 'Song 2');
      final playlist = playlistWith(songIds: [song0.id, song1.id]);
      await setUpAppTest(() {
        FakeSweyerPluginPlatform.instance.songs = [song0, song1, song2];
        FakeSweyerPluginPlatform.instance.playlists = [playlist];
      });
      await tester.runAppTest(() async {
        HomeRouter.instance.goto(HomeRoutes.factory.content(playlist));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.runAsync(() async {
          // The marquee widget starts a future, we must use runAsync
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.settings_rounded).hitTestable(), findsOneWidget);

          // Select Song 2
          await tester.tap(find.descendant(
              of: find.ancestor(of: find.text(song2.title), matching: find.byType(SongTile)),
              matching: find.byIcon(Icons.add_rounded)));
          await tester.pumpAndSettle();

          // Open insertion settings
          await tester.tap(find.descendant(
            of: find.byType(SelectionActionsBar),
            matching: find.byIcon(Icons.settings_rounded).hitTestable(),
          ));
          await tester.pumpAndSettle();
          expect(tester.widget<SongTile>(find.widgetWithText(SongTile, song0.title).hitTestable()).backgroundColor,
              isNot(FakeThemeControl.instance.theme.colorScheme.primary));

          // Select Song 0
          await tester.tap(find.widgetWithText(SongTile, song0.title).hitTestable());
          await tester.pumpAndSettle();
          expect(tester.widget<SongTile>(find.widgetWithText(SongTile, song0.title).hitTestable()).backgroundColor,
              FakeThemeControl.instance.theme.colorScheme.primary);

          // Add selected Song 2 to playlist
          await tester.tap(find.ancestor(of: find.text(l10n.done), matching: find.byType(ElevatedButton)));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(SongTile, song2.title).hitTestable(), findsOneWidget);
          expect(playlist.songs, orderedEquals([song0, song2, song1]));
        });
      });
    });
  });
}
