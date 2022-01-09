import 'package:flutter/material.dart';

import '../test.dart';

void main() {
  setUp(() async {
    await setUpAppTest();
  });

  Future<void> expandPlayerRoute(WidgetTester tester) async {
    await tester.tap(find.byType(TrackPanel));
    await tester.pumpAndSettle();
    expect(playerRouteController.value, 1.0);
  }

  testWidgets('can expand/collapse by tapping the button', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      // Tap collapse button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(playerRouteController.value, 0.0);
    });
  });

  testWidgets('can expand/collapse by flinging', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route with fling
      await tester.fling(find.byType(TrackPanel), const Offset(0.0, -400.0), 1000.0);
      await tester.pumpAndSettle();
      expect(playerRouteController.value, 1.0);

      // Fling to collapse
      await tester.flingFrom(Offset.zero, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle();
      expect(playerRouteController.value, 0.0);
    });
  });

  testWidgets('can open queue screen by swiping to left', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      expect(find.text(l10n.upNext), findsNothing);
      await tester.flingFrom(Offset.zero, const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();
      expect(find.text(l10n.upNext), findsOneWidget);
    });
  });

  testWidgets('shows correct track info', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      /// Expect 3 because:
      /// 1 - from [SongTile]
      /// 2 - from [TrackPanel]
      /// 3 - from [PlayerRoute]

      final currentSong = PlaybackControl.instance.currentSong;
      expect(find.text(currentSong.title), findsNWidgets(3));
      /// Use `textContaining`, because [SongTile] adds duration at the end of the artist
      expect(find.textContaining(currentSong.artist), findsNWidgets(3));
      expect(find.byWidgetPredicate(
        (widget) =>
          widget is ContentArt &&
          widget.source == ContentArtSource.song(currentSong)),
        findsNWidgets(4), // PlayerRoute shows uses two arts and animates between them
      );
    });
  });

  testWidgets('shuffle button works', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      expect(QueueControl.instance.state.shuffled, false);
      await tester.tap(find.byType(ShuffleButton));
      expect(QueueControl.instance.state.shuffled, true);
      await tester.tap(find.byType(ShuffleButton));
      expect(QueueControl.instance.state.shuffled, false);
    });
  });

  testWidgets('loop button works', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      expect(MusicPlayer.instance.looping, false);
      await tester.tap(find.byType(LoopButton));
      expect(MusicPlayer.instance.looping, true);
      await tester.tap(find.byType(LoopButton));
      expect(MusicPlayer.instance.looping, false);
    });
  });

  testWidgets('play previous button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0),
      songWith(id: 1),
      songWith(id: 2),
    ]);
    await tester.runAsync(() async {
      await setUpAppTest(() {
        FakeContentChannel.instance.songs = songs.toList();
      });
    });
    PlaybackControl.instance.changeSong(songs[1]);
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      expect(PlaybackControl.instance.currentSong, songs[1]);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pumpAndSettle();
      expect(PlaybackControl.instance.currentSong, songs.first);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(PlaybackControl.instance.currentSong, songs.last);
    });
  });

  testWidgets('play next button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0),
      songWith(id: 1),
      songWith(id: 2),
    ]);
    await tester.runAsync(() async {
      await setUpAppTest(() {
        FakeContentChannel.instance.songs = songs.toList();
      });
    });
    PlaybackControl.instance.changeSong(songs[1]);
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      expect(PlaybackControl.instance.currentSong, songs[1]);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(PlaybackControl.instance.currentSong, songs.last);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(PlaybackControl.instance.currentSong, songs.first);
    });
  });

  testWidgets('play/pause button works', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Expand the route
      await expandPlayerRoute(tester);

      final button = find.descendant(
        of: find.byType(SharedAxisTabView),
        matching: find.byType(AnimatedPlayPauseButton),
      );

      expect(MusicPlayer.instance.playing, false);

      await tester.tap(button);
      expect(MusicPlayer.instance.playing, true);

      await tester.tap(button);
      expect(MusicPlayer.instance.playing, false);

      await tester.pumpAndSettle();
    });
  });
}
