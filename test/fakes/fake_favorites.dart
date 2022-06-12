// ignore_for_file: overridden_fields

import '../test.dart';

class _FavoritesRepository extends FavoritesRepository {
  @override
  final serializersMap = ContentMap<IntSerializerType>({
    for (final contentType in Content.enumerate()) contentType: FakeJsonSerializer([]),
  });
}

class FakeFavoritesControl extends FavoritesControl {
  FakeFavoritesControl() {
    instance = this;
  }
  static late FakeFavoritesControl instance;

  @override
  late final repository = _FavoritesRepository();
}
