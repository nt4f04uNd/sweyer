/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweyer/sweyer.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // await ContentControl.init();
  });

  // test('test', () async {
  //   final song1 = SelectionEntry(data: Song(id: 0));
  //   final song2 = SelectionEntry(data: Song(id: 0));
  //   final songs = [song1];
  //   expect(songs.contains(song2), true);
  //   // print(ContentControl.state.sdkInt);
  // });

  // test('test2', () async {
  //   List<int> f = [1,2,3,4];
  //   final b = f.cast<Map<String, dynamic>>();
  //   // print(b);
  // });

  test('test3', () async {
    await AppLocalizations.load(const Locale('ru', 'RU'));
    await AppLocalizations.load(const Locale('en', 'EN'));
    await AppLocalizations.load(const Locale('ru', 'RU'));
    print(staticl10n.artistUnknown);
  });
}
