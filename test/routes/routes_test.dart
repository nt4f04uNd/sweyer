import '../test.dart';

void main() {
  test('HomeRoutes comparison test', () async {
    final albumRoute1 = HomeRoutes.factory.content(albumWith());
    final albumRoute2 = HomeRoutes.factory.content(albumWith());
    final artistRoute = HomeRoutes.factory.content(artistWith());

    expect(albumRoute1, equals(albumRoute2));
    expect(albumRoute1.hasSameLocation(HomeRoutes.album), true);
    expect(artistRoute.hasDifferentLocation(HomeRoutes.album), true);
  });
}
