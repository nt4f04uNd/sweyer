import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import 'package:sweyer/logic/player/music_player.dart' as sweyer_music_player;
import '../../test.dart';

void main() {
  setUp(() {
    registerAppSetup(() {
      MusicPlayer.handler?.playbackState.add(PlaybackState());
    });
  });

  testWidgets('Player can pause', (tester) async {
    await tester.runAppTestWithoutUi(() async {
      var playFutureCompleted = false;
      MusicPlayer.instance.play().whenComplete(() => playFutureCompleted = true);
      await tester.pump();
      expect(MusicPlayer.instance.playing, true);
      await MusicPlayer.instance.pause();
      await tester.pump();
      expect(playFutureCompleted, true);
      expect(MusicPlayer.instance.playing, false);
    });
  });

  group('Player notification', () {
    testWidgets('Is updated when playing', (tester) async {
      await tester.runAppTestWithoutUi(() async {
        MusicPlayer.instance.play();
        await tester.pump();
        final playbackState = MusicPlayer.handler!.playbackState.value!;
        expect(playbackState.playing, true);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_music_player.AudioHandler.loopOff),
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
        MusicPlayer.instance.play();
        await tester.pump();
        await MusicPlayer.instance.pause();
        await tester.pump();
        final playbackState = MusicPlayer.handler!.playbackState.value!;
        expect(MusicPlayer.instance.playing, false);
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_music_player.AudioHandler.loopOff),
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
        MusicPlayer.instance.play();
        await tester.pump();
        await MusicPlayer.handler!.stop();
        await tester.pump();
        final playbackState = MusicPlayer.handler!.playbackState.value!;
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.idle);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl.custom(
                androidIcon: 'drawable/round_loop',
                label: l10n.loopOff,
                name: sweyer_music_player.AudioHandler.loopOff),
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
