import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:sweyer/logic/player/player_manager.dart' as sweyer_player_manager;
import '../../test.dart';

void main() {
  setUp(() {
    registerAppSetup(() {
      PlayerManager.handler?.playbackState.add(PlaybackState());
    });
  });

  testWidgets('Player can pause', (tester) async {
    await tester.runAppTestWithoutUi(() async {
      var playFutureCompleted = false;
      unawaited(tester.runAsync(PlayerManager.instance.play).whenComplete(() => playFutureCompleted = true));
      expect(PlayerManager.instance.playing, true);
      await PlayerManager.instance.pause();
      expect(playFutureCompleted, true);
      expect(PlayerManager.instance.playing, false);
    });
  });

  group('Player notification', () {
    testWidgets('Is updated when playing', (tester) async {
      await tester.runAppTestWithoutUi(() async {
        unawaited(PlayerManager.instance.play());
        await tester.runAsync(tester.idle);
        final playbackState = PlayerManager.handler!.playbackState.value;
        expect(playbackState.playing, true);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_player_manager.AudioHandler.loopOff),
            MediaControl(
                androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: MediaAction.skipToPrevious),
            MediaControl(androidIcon: 'drawable/round_pause', label: l10n.pause, action: MediaAction.pause),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: MediaAction.skipToNext),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: MediaAction.stop),
          ].map((control) => control.toString()),
        );
      });
    });

    testWidgets('Is updated when paused', (tester) async {
      await tester.runAppTestWithoutUi(() async {
        unawaited(PlayerManager.instance.play());
        await tester.pump();
        await tester.runAsync(PlayerManager.instance.pause);
        await tester.pump();
        final playbackState = PlayerManager.handler!.playbackState.value;
        expect(PlayerManager.instance.playing, false);
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_player_manager.AudioHandler.loopOff),
            MediaControl(
                androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: MediaAction.skipToPrevious),
            MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: MediaAction.play),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: MediaAction.skipToNext),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: MediaAction.stop),
          ].map((control) => control.toString()),
        );
      });
    });

    testWidgets('Is updated when stopped', (tester) async {
      await tester.runAppTestWithoutUi(() async {
        unawaited(PlayerManager.instance.play());
        await tester.pump();
        await tester.runAsync(PlayerManager.handler!.stop);
        await tester.pump();
        final playbackState = PlayerManager.handler!.playbackState.value;
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.idle);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_player_manager.AudioHandler.loopOff),
            MediaControl(
                androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: MediaAction.skipToPrevious),
            MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: MediaAction.play),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: MediaAction.skipToNext),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: MediaAction.stop),
          ].map((control) => control.toString()),
        );
      });
    });
  });
}
