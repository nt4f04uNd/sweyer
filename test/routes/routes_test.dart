/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_test/flutter_test.dart';
import 'package:sweyer/sweyer.dart';

import '../test.dart';

void main() {
  test('HomeRoutes comparison test', () async {
    final albumRoute1 = HomeRoutes.factory.content<Album>(albumWith());
    final albumRoute2 = HomeRoutes.factory.content<Album>(albumWith());
    final artistRoute = HomeRoutes.factory.content<Artist>(artistWith());

    expect(albumRoute1, equals(albumRoute2));
    expect(albumRoute1.hasSameLocation(HomeRoutes.album), true);
    expect(artistRoute.hasDifferentLocation(HomeRoutes.album), true);
  });
}
