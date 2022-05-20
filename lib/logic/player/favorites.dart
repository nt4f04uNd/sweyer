import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';

@visibleForTesting
class FavoritesRepository {
  final serializersMap = ContentMap<IntSerializerType>({
    for (final contentType in Content.enumerate())
      contentType: IntListSerializer('favorites_${ContentUtils.contentTypeId(contentType)}.json')
  });
}

class FavoritesControl extends Control {
  static FavoritesControl instance = FavoritesControl();

  @visibleForTesting
  final repository = FavoritesRepository();

  final _favoriteSetsMap = ContentMap<Set<int>>();

  bool _useAndroidFavorites(Type contentType) =>
    contentType == Song && DeviceInfoControl.instance.useScopedStorageForFileModifications;

  @override
  Future<void> init() async {
    super.init();
    _showOnlyFavoritesNotifier.value = false;
    for (final contentType in Content.enumerate()) {
      final favoriteSet = _favoriteSetsMap.getValue(contentType) ?? {};
      if (_useAndroidFavorites(contentType)) {
        for (final song in ContentControl.instance.state.allSongs.songs) {
          if (song.isFavoriteInMediaStore!) {
            favoriteSet.add(song.sourceId);
          }
        }
      } else {
        final serializer = repository.serializersMap.getValue(contentType);
        await serializer!.init();
        final savedIds = await serializer.read();
        favoriteSet.addAll(savedIds);
      }
      _favoriteSetsMap.setValue(favoriteSet, key: contentType);
    }
  }

  @override
  void dispose() {
    _favoriteSetsMap.clear();
    super.dispose();
  }

  ValueListenable<bool> get onShowOnlyFavorites => _showOnlyFavoritesNotifier;
  final ValueNotifier<bool> _showOnlyFavoritesNotifier = ValueNotifier(false);

  /// Whether tabs route currently should filter and only show favorite content.
  bool get showOnlyFavorites => _showOnlyFavoritesNotifier.value;

  void toggleShowOnlyFavorites() {
    _showOnlyFavoritesNotifier.value = !_showOnlyFavoritesNotifier.value;
  }

  /// Whether the given [content] is favorite.
  bool isFavorite<T extends Content>(T content) {
    final favoriteSet = _favoriteSetsMap.getValue<T>(content.runtimeType);
    if (content is Song)
      return favoriteSet!.contains(content.sourceId);
    return favoriteSet!.contains(content.id);
  }

  /// Sets whether a given tuple of content is favorite.
  Future<void> setFavorite({
    required ContentTuple contentTuple,
    required bool value
  }) async {
    for (final contentType in Content.enumerate()) {
      final contentList = contentTuple.get(contentType);
      final newFavoriteSet = _favoriteSetsMap.getValue(contentType)!.toSet();
      Iterable<int> ids;
      if (contentType == Song) {
        ids = (contentList as List<Song>).map((el) => el.sourceId);
      } else {
        ids = contentList.map((el) => el.id);
      }

      if (ids.isEmpty) {
        continue;
      }

      if (value) {
        newFavoriteSet.addAll(ids);
      } else {
        newFavoriteSet.removeAll(ids);
      }

      try {
        if (_useAndroidFavorites(contentType)) {
          final songs = (contentList as List<Song>).toSet();
          await ContentControl.instance.setSongsFavorite(songs, value);
        } else {
          final serializer = repository.serializersMap.getValue(contentType);
          await serializer!.save(newFavoriteSet.toList());
        }
        _favoriteSetsMap.setValue(newFavoriteSet, key: contentType);
        ContentControl.instance.emitContentChange();
        QueueControl.instance.emitQueueChange();
      } catch (ex, stack) {
        FirebaseCrashlytics.instance.recordError(
          ex,
          stack,
          reason: 'in setFavorite',
        );
        ShowFunctions.instance.showToast(
          msg: staticl10n.oopsErrorOccurred,
        );
        debugPrint('setFavorite error: $ex');
      }
    }
  }

  /// Switches current song favorite status.
  Future<void> toggleFavoriteCurrentSong() {
    final currentSong = PlaybackControl.instance.currentSong;
    return FavoritesControl.instance.setFavorite(
      contentTuple: ContentTuple(
        [currentSong],
        const [],
        const [],
        const [],
      ),
      value: !currentSong.isFavorite,
    );
  }
}
