import 'dart:async';

import 'package:android_content_provider/android_content_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';

@visibleForTesting
class FavoritesRepository {
  final serializersMap = ContentMap<IntSerializerType>.fromFactory(
    (contentType) => IntListSerializer('favorites_${contentType.name}.json'),
  );
}

class FavoritesControl with Control {
  static FavoritesControl instance = FavoritesControl();

  @visibleForTesting
  final repository = FavoritesRepository();

  final _favoriteSetsMap = ContentMap.fromFactory((contentType) => <int>{});

  bool _useMediaStoreFavorites(ContentType contentType) =>
      contentType == ContentType.song &&
      DeviceInfoControl.instance.useScopedStorageForFileModifications &&
      Settings.useMediaStoreForFavoriteSongs.value;

  MediaStoreContentObserver? _mediaStoreContentObserver;

  @override
  Future<void> init() async {
    super.init();
    _showOnlyFavoritesNotifier.value = false;
    for (final contentType in ContentType.values) {
      await _initContentType(contentType);
    }
    _registerMediaStoreObserver();
    Settings.useMediaStoreForFavoriteSongs.addListener(_useMediaStoreForFavoriteSongsListener);
  }

  @override
  void dispose() {
    for (var element in _favoriteSetsMap.entries) {
      element.value.clear();
    }
    _disposeMediaStoreObserver();
    Settings.useMediaStoreForFavoriteSongs.removeListener(_useMediaStoreForFavoriteSongsListener);
    super.dispose();
  }

  Future<void> _initContentType(ContentType contentType) async {
    final Set<int> favoriteSet = {};
    if (_useMediaStoreFavorites(contentType)) {
      for (final song in ContentControl.instance.state.allSongs.songs) {
        if (song.isFavoriteInMediaStore!) {
          favoriteSet.add(song.sourceId);
        }
      }
    } else {
      final serializer = repository.serializersMap.get(contentType);
      await serializer.init();
      final savedIds = await serializer.read();
      favoriteSet.addAll(savedIds);
    }
    _favoriteSetsMap.set(favoriteSet, key: contentType);
  }

  Future<void> _useMediaStoreForFavoriteSongsListener() async {
    if (Settings.useMediaStoreForFavoriteSongs.value) {
      _registerMediaStoreObserver();
    } else {
      _disposeMediaStoreObserver();
    }
    await _initContentType(ContentType.song);
    ContentControl.instance.emitContentChange();
  }

  void _registerMediaStoreObserver() {
    _mediaStoreContentObserver = MediaStoreContentObserver(ContentType.song)
      ..onChangeStream.listen(_handleMediaStoreSongsChange)
      ..register();
  }

  void _disposeMediaStoreObserver() {
    _endMediaStoreUpdate();
    _mediaStoreContentObserver?.dispose();
    _mediaStoreContentObserver = null;
  }

  static const _mediaStoreUpdateDebounceInterval = Duration(milliseconds: 200);
  Timer? _mediaStoreUpdateTimer;
  void _endMediaStoreUpdate() {
    _mediaStoreUpdateTimer?.cancel();
    _mediaStoreUpdateTimer = null;
  }

  void _handleMediaStoreSongsChange(MediaStoreContentChangeEvent event) {
    if (event.flags & AndroidContentResolver.NOTIFY_UPDATE != 0) {
      _mediaStoreUpdateTimer?.cancel();
      _mediaStoreUpdateTimer = Timer(_mediaStoreUpdateDebounceInterval, () async {
        _endMediaStoreUpdate();
        await ContentControl.instance.refetch(ContentType.song);
        final favoriteSet = _favoriteSetsMap.get(ContentType.song);
        for (final song in ContentControl.instance.state.allSongs.songs) {
          if (song.isFavoriteInMediaStore! && !favoriteSet.contains(song.id)) {
            favoriteSet.add(song.id);
          } else if (!song.isFavoriteInMediaStore! && favoriteSet.contains(song.id)) {
            favoriteSet.remove(song.id);
          }
        }
      });
    }
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
    final favoriteSet = _favoriteSetsMap.get(content.type);
    if (content is Song) {
      return favoriteSet.contains(content.sourceId);
    }
    return favoriteSet.contains(content.id);
  }

  /// Sets whether a given tuple of content is favorite.
  Future<void> setFavorite({
    required ContentTuple contentTuple,
    required bool value,
  }) async {
    for (final contentType in ContentType.values) {
      final contentList = contentTuple.get(contentType);
      final newFavoriteSet = _favoriteSetsMap.get(contentType).toSet();
      Iterable<int> ids;
      if (contentType == ContentType.song) {
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
        if (_useMediaStoreFavorites(contentType)) {
          final songs = (contentList as List<Song>).toSet();
          await ContentControl.instance.setSongsFavorite(songs, value);
        } else {
          final serializer = repository.serializersMap.get(contentType);
          await serializer.save(newFavoriteSet.toList());
        }
        _favoriteSetsMap.set(newFavoriteSet, key: contentType);
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
        songs: [currentSong],
      ),
      value: !currentSong.isFavorite,
    );
  }
}
