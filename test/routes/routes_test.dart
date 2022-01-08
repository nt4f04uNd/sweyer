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
