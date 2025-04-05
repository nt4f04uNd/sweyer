import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import '../../test.dart';

void main() {
  setUp(() {
    registerAppSetup(() {
      PlayerManager.handler?.playbackState.add(PlaybackState());
    });
  });

  test('Player can pause', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runAppTestWithoutUi(() async {
      var playFutureCompleted = false;
      PlayerManager.instance.play().whenComplete(() => playFutureCompleted = true);
      await binding.pump();
      expect(PlayerManager.instance.playing, true);
      await PlayerManager.instance.pause();
      await binding.pump();
      expect(playFutureCompleted, true);
      expect(PlayerManager.instance.playing, false);
    });
  });

  group('Player notification', () {
    test('Is updated when playing', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        PlayerManager.instance.play();
        await binding.pump();
        final playbackState = PlayerManager.handler!.playbackState.value!;
        expect(playbackState.playing, true);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
            MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
            MediaControl(androidIcon: 'drawable/round_pause', label: l10n.pause, action: 'pause'),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
          ].map((control) => control.toString()),
        );
      });
    });

    test('Is updated when paused', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        PlayerManager.instance.play();
        await binding.pump();
        await PlayerManager.instance.pause();
        await binding.pump();
        final playbackState = PlayerManager.handler!.playbackState.value!;
        expect(PlayerManager.instance.playing, false);
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
            MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
            MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: 'play'),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
          ].map((control) => control.toString()),
        );
      });
    });

    test('Is updated when stopped', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.runAppTestWithoutUi(() async {
        PlayerManager.instance.play();
        await binding.pump();
        await PlayerManager.handler!.onNotificationAction('stop');
        await binding.pump();
        final playbackState = PlayerManager.handler!.playbackState.value!;
        expect(playbackState.playing, false);
        expect(playbackState.processingState, AudioProcessingState.ready);
        expect(
          playbackState.controls.map((control) => control.toString()),
          [
            MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
            MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
            MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: 'play'),
            MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
            MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
          ].map((control) => control.toString()),
        );
      });
    });
  });
}
