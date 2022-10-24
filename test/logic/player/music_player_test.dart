// TODO: https://github.com/nt4f04uNd/sweyer/issues/76
// import 'package:audio_service/audio_service.dart';
// import 'package:rxdart/rxdart.dart';

// import '../../test.dart';

// void main() {
//   setUp(() async {
//     MusicPlayer.handler?.playbackState.add(PlaybackState());
//     await setUpAppTest();
//   });

//   tearDown(() async {
//     await MusicPlayer.instance.dispose();
//   });

//   test('Player can pause', () async {
//     var playFutureCompleted = false;
//     MusicPlayer.instance.play().whenComplete(() => playFutureCompleted = true);
//     await pumpEventQueue();
//     expect(MusicPlayer.instance.playing, true);
//     await MusicPlayer.instance.pause();
//     await pumpEventQueue();
//     expect(playFutureCompleted, true);
//     expect(MusicPlayer.instance.playing, false);
//   });

//   group('Player notification', () {
//     test('Is updated when playing', () async {
//       MusicPlayer.instance.play();
//       await pumpEventQueue();
//       final playbackState = MusicPlayer.handler!.playbackState.value!;
//       expect(playbackState.playing, true);
//       expect(playbackState.processingState, AudioProcessingState.ready);
//       expect(
//         playbackState.controls.map((control) => control.toString()),
//         [
//           MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
//           MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
//           MediaControl(androidIcon: 'drawable/round_pause', label: l10n.pause, action: 'pause'),
//           MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
//           MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
//         ].map((control) => control.toString()),
//       );
//     });

//     test('Is updated when paused', () async {
//       MusicPlayer.instance.play();
//       await pumpEventQueue();
//       await MusicPlayer.instance.pause();
//       await pumpEventQueue();
//       final playbackState = MusicPlayer.handler!.playbackState.value!;
//       expect(MusicPlayer.instance.playing, false);
//       expect(playbackState.playing, false);
//       expect(playbackState.processingState, AudioProcessingState.ready);
//       expect(
//         playbackState.controls.map((control) => control.toString()),
//         [
//           MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
//           MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
//           MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: 'play'),
//           MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
//           MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
//         ].map((control) => control.toString()),
//       );
//     });

//     test('Is updated when stopped', () async {
//       MusicPlayer.instance.play();
//       await pumpEventQueue();
//       await MusicPlayer.handler!.onNotificationAction('stop');
//       await pumpEventQueue();
//       final playbackState = MusicPlayer.handler!.playbackState.value!;
//       expect(playbackState.playing, false);
//       expect(playbackState.processingState, AudioProcessingState.ready);
//       expect(
//         playbackState.controls.map((control) => control.toString()),
//         [
//           MediaControl(androidIcon: 'drawable/round_loop', label: l10n.loopOff, action: 'loop_off'),
//           MediaControl(androidIcon: 'drawable/round_skip_previous', label: l10n.previous, action: 'play_prev'),
//           MediaControl(androidIcon: 'drawable/round_play_arrow', label: l10n.play, action: 'play'),
//           MediaControl(androidIcon: 'drawable/round_skip_next', label: l10n.next, action: 'play_next'),
//           MediaControl(androidIcon: 'drawable/round_stop', label: l10n.stop, action: 'stop'),
//         ].map((control) => control.toString()),
//       );
//     });
//   });
// }
