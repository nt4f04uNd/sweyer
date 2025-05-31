import '../../test.dart';

void main() {
  late Album album;
  setUp(() {
    album = albumWith();
  });

  testWidgets('Sorts tracks', (tester) async {
    final nullSong1 = songWith(id: 0, track: null, title: 'Null Song 1');
    final nullSong2 = songWith(id: 5, track: null, title: 'Null Song 2');
    final song1 = songWith(id: 6, track: '1', title: 'First Song');
    final song2 = songWith(id: 2, track: '2', title: 'Second Song');
    final song3 = songWith(id: 4, track: '3', title: 'Third Song');
    final song4 = songWith(id: 1, track: '4', title: 'Fourth Song');
    final song10 = songWith(id: 3, track: '10', title: 'Tenth Song');
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [nullSong1, nullSong2, song1, song2, song3, song4, song10];
    });
    await tester.runAppTestWithoutUi(() {
      expect(album.songs, [song1, song2, song3, song4, song10, nullSong1, nullSong2]);
    });
  });

  testWidgets('Sorts tracks with total track count', (tester) async {
    final nullSong1 = songWith(id: 0, track: null, title: 'Null Song 1');
    final song1 = songWith(id: 6, track: '1/10', title: 'First Song');
    final song2 = songWith(id: 2, track: '2/', title: 'Second Song');
    final song3 = songWith(id: 4, track: '3/X', title: 'Third Song');
    final song4 = songWith(id: 1, track: '4/0', title: 'Fourth Song');
    final song10 = songWith(id: 3, track: '10/10', title: 'Tenth Song');
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [nullSong1, song1, song2, song3, song4, song10];
    });
    await tester.runAppTestWithoutUi(() {
      expect(album.songs, [song1, song2, song3, song4, song10, nullSong1]);
    });
  });

  testWidgets('Sorts tracks with spaces in track field', (tester) async {
    final nullSong1 = songWith(id: 0, track: null, title: 'Null Song 1');
    final song1 = songWith(id: 6, track: '1   ', title: 'First Song');
    final song2 = songWith(id: 2, track: ' 2 ', title: 'Second Song');
    final song3 = songWith(id: 4, track: '3 /  10', title: 'Third Song');
    final song4 = songWith(id: 1, track: ' 4 / 10 ', title: 'Fourth Song');
    final song10 = songWith(id: 3, track: ' 10 /10', title: 'Tenth Song');
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [nullSong1, song1, song2, song3, song4, song10];
    });
    await tester.runAppTestWithoutUi(() {
      expect(album.songs, [song1, song2, song3, song4, song10, nullSong1]);
    });
  });
}
