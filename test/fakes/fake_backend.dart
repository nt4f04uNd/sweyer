import '../test.dart';

class FakeBackend implements Backend {
  @override
  Future<GetArtistInfoResponse> getArtistInfo(String name) async {
    return GetArtistInfoResponse(imageUrl: null);
  }
}
