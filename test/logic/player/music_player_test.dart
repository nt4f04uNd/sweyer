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

  test('Player can pause', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runAppTestWithoutUi(() async {
      var playFutureCompleted = false;
      MusicPlayer.instance.play().whenComplete(() => playFutureCompleted = true);
      await binding.pump();
      expect(MusicPlayer.instance.playing, true);
      await MusicPlayer.instance.pause();
      await binding.pump();
      expect(playFutureCompleted, true);
      expect(MusicPlayer.instance.playing, false);
    });
  });

  group('Player notification', () {
    test('Is updated when playing', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        MusicPlayer.instance.play();
        await binding.pump();
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

    test('Is updated when paused', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        MusicPlayer.instance.play();
        await binding.pump();
        await MusicPlayer.instance.pause();
        await binding.pump();
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

    test('Is updated when stopped', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        MusicPlayer.instance.play();
        await binding.pump();
        await MusicPlayer.handler!.stop();
        await binding.pump();
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
