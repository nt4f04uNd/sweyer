import 'package:equatable/equatable.dart';
import 'package:sweyer/sweyer.dart';

/// The order of a sort operation.
enum SortOrder {
  /// Ascending sort order ("lower" values first, "higher" values last).
  ascending,

  /// Descending sort order ("higher" values first, "lower" values last).
  descending;

  /// The inversion of the sort order.
  SortOrder get inverted => switch (this) {
        SortOrder.ascending => SortOrder.descending,
        SortOrder.descending => SortOrder.ascending,
      };
}

/// Interface for other sort feature enums.
abstract interface class SortFeature<T extends Content> {
  /// Returns sort feature values for a given content.
  static List<SortFeature<T>> getValuesForContent<T extends Content>(ContentType<T> contentType) {
    switch (contentType as ContentType) {
      case ContentType.song:
        return SongSortFeature.values as List<SortFeature<T>>;
      case ContentType.album:
        return AlbumSortFeature.values as List<SortFeature<T>>;
      case ContentType.playlist:
        return PlaylistSortFeature.values as List<SortFeature<T>>;
      case ContentType.artist:
        return ArtistSortFeature.values as List<SortFeature<T>>;
    }
  }

  /// An identifier for this feature.
  String get id;

  /// The default sorting order of the feature.
  SortOrder get defaultSortingOrder;
}

/// Features to sort by a [Song] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [SongSortFeature] the new default sort order is applied.
enum SongSortFeature implements SortFeature<Song> {
  /// Sort by the [Song.dateModified].
  dateModified(SortOrder.descending),

  /// Sort by the [Song.dateAdded].
  dateAdded(SortOrder.descending),

  /// Sort by the [Song.title].
  title(SortOrder.ascending),

  /// Sort by the [Song.artist].
  artist(SortOrder.ascending),

  /// Sort by the [Song.album].
  album(SortOrder.ascending);

  const SongSortFeature(this.defaultSortingOrder);

  @override
  String get id => name;

  @override
  final SortOrder defaultSortingOrder;
}

/// Features to sort by a [Album] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [AlbumSortFeature] the new default sort order is applied.
enum AlbumSortFeature implements SortFeature<Album> {
  /// Sort by the [Album.album].
  title(SortOrder.ascending),

  /// Sort by the [Album.artist].
  artist(SortOrder.ascending),

  /// Sort by the [Album.lastYear].
  year(SortOrder.descending),

  /// Sort by the [Album.numberOfSongs].
  numberOfSongs(SortOrder.ascending);

  const AlbumSortFeature(this.defaultSortingOrder);

  @override
  String get id => name;

  @override
  final SortOrder defaultSortingOrder;
}

/// Features to sort by a [Playlist] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [PlaylistSortFeature] the new default sort order is applied.
enum PlaylistSortFeature implements SortFeature<Playlist> {
  /// Sort by the [Playlist.dateModified].
  dateModified(SortOrder.descending),

  /// Sort by the [Playlist.dateAdded].
  dateAdded(SortOrder.descending),

  /// Sort by the [Playlist.name].
  name(SortOrder.ascending);

  const PlaylistSortFeature(this.defaultSortingOrder);

  @override
  String get id => this.name;

  @override
  final SortOrder defaultSortingOrder;
}

/// Features to sort by a [Artist] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [ArtistSortFeature] the new default sort order is applied.
enum ArtistSortFeature implements SortFeature<Artist> {
  /// Sort by the [Artist.artist].
  name(SortOrder.ascending),

  /// Sort by the [Artist.numberOfAlbums].
  numberOfAlbums(SortOrder.ascending),

  /// Sort by the [Artist.numberOfTracks].
  numberOfTracks(SortOrder.ascending);

  const ArtistSortFeature(this.defaultSortingOrder);

  @override
  String get id => this.name;

  @override
  final SortOrder defaultSortingOrder;
}

abstract class Sort<T extends Content> extends Equatable {
  const Sort({
    required this.feature,
    required this.order,
  });
  Sort.defaultOrder(this.feature) : order = feature.defaultSortingOrder;

  final SortFeature<T> feature;
  final SortOrder order;

  @override
  List<Object> get props => [feature, order];

  Sort<T> copyWith({SortFeature<T>? feature, SortOrder? order});
  Sort<T> get withDefaultOrder => copyWith(order: feature.defaultSortingOrder);

  Comparator<T> get comparator;

  Map<String, dynamic> toMap() => {
        'feature': feature.id,
        'order': order,
      };
}

class SongSort extends Sort<Song> {
  const SongSort({
    required super.feature,
    super.order = SortOrder.ascending,
  });
  SongSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory SongSort.fromMap(Map map) => SongSort(
        feature: SongSortFeature.values.byName(map['feature']),
        order: SortOrder.values.byName(map['order'] ?? 'ascending'),
      );

  @override
  SongSort copyWith({
    covariant SongSortFeature? feature,
    SortOrder? order,
  }) {
    return SongSort(
      feature: feature ?? this.feature as SongSortFeature,
      order: order ?? this.order,
    );
  }

  int _fallbackTitle(Song a, Song b) {
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _fallbackDateModified(Song a, Song b) {
    return a.dateModified.compareTo(b.dateModified);
  }

  @override
  Comparator<Song> get comparator {
    Comparator<Song> c;
    switch (feature) {
      case SongSortFeature.dateModified:
        c = (a, b) {
          final compare = a.dateModified.compareTo(b.dateModified);
          if (compare == 0) {
            return _fallbackTitle(a, b);
          }
          return compare;
        };
        break;
      case SongSortFeature.dateAdded:
        c = (a, b) {
          final compare = a.dateAdded.compareTo(b.dateAdded);
          if (compare == 0) {
            return _fallbackTitle(a, b);
          }
          return compare;
        };
        break;
      case SongSortFeature.title:
        c = (a, b) {
          final compare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (compare == 0) {
            return _fallbackDateModified(a, b);
          }
          return compare;
        };
        break;
      case SongSortFeature.artist:
        c = (a, b) {
          final compare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (compare == 0) {
            return _fallbackTitle(a, b);
          }
          return compare;
        };
        break;
      case SongSortFeature.album:
        c = (a, b) {
          final compare = a.album!.toLowerCase().compareTo(b.album!.toLowerCase());
          if (compare == 0) {
            return _fallbackTitle(a, b);
          }
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (order == SortOrder.descending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}

class AlbumSort extends Sort<Album> {
  const AlbumSort({
    required super.feature,
    super.order = SortOrder.ascending,
  });
  AlbumSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory AlbumSort.fromMap(Map map) => AlbumSort(
        feature: AlbumSortFeature.values.byName(map['feature']),
        order: SortOrder.values.byName(map['order'] ?? 'ascending'),
      );

  @override
  AlbumSort copyWith({
    covariant AlbumSortFeature? feature,
    SortOrder? order,
  }) {
    return AlbumSort(
      feature: feature ?? this.feature as AlbumSortFeature,
      order: order ?? this.order,
    );
  }

  int _fallbackYear(Album a, Album b) {
    return (a.year ?? 0).compareTo((b.year ?? 0)); // TODO: Decide how to sort null values
  }

  int _fallbackTitle(Album a, Album b) {
    return a.album.toLowerCase().compareTo(b.album.toLowerCase());
  }

  @override
  Comparator<Album> get comparator {
    Comparator<Album> c;
    switch (feature) {
      case AlbumSortFeature.title:
        c = (a, b) {
          final compare = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          if (compare == 0) {
            return _fallbackYear(a, b);
          }
          return compare;
        };
        break;
      case AlbumSortFeature.artist:
        c = (a, b) {
          final compare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (compare == 0) {
            return _fallbackYear(a, b);
          }
          return compare;
        };
        break;
      case AlbumSortFeature.year:
        c = (a, b) {
          final compare = (a.year ?? 0).compareTo(b.year ?? 0); // TODO: Decide how to sort null values
          if (compare == 0) {
            return _fallbackTitle(a, b);
          }
          return compare;
        };
        break;
      case AlbumSortFeature.numberOfSongs:
        c = (a, b) {
          final compare = a.numberOfSongs.compareTo(b.numberOfSongs);
          if (compare == 0) {
            return _fallbackYear(a, b);
          }
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (order == SortOrder.descending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}

class PlaylistSort extends Sort<Playlist> {
  const PlaylistSort({
    required super.feature,
    super.order = SortOrder.ascending,
  });
  PlaylistSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory PlaylistSort.fromMap(Map map) => PlaylistSort(
        feature: PlaylistSortFeature.values.byName(map['feature']),
        order: SortOrder.values.byName(map['order'] ?? 'ascending'),
      );

  @override
  PlaylistSort copyWith({
    covariant PlaylistSortFeature? feature,
    SortOrder? order,
  }) {
    return PlaylistSort(
      feature: feature ?? this.feature as PlaylistSortFeature,
      order: order ?? this.order,
    );
  }

  int _fallbackName(Playlist a, Playlist b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _fallbackDateModified(Playlist a, Playlist b) {
    return a.dateModified.compareTo(b.dateModified);
  }

  @override
  Comparator<Playlist> get comparator {
    Comparator<Playlist> c;
    switch (feature) {
      case PlaylistSortFeature.dateModified:
        c = (a, b) {
          final compare = a.dateModified.compareTo(b.dateModified);
          if (compare == 0) {
            return _fallbackName(a, b);
          }
          return compare;
        };
        break;
      case PlaylistSortFeature.dateAdded:
        c = (a, b) {
          final compare = a.dateAdded.compareTo(b.dateAdded);
          if (compare == 0) {
            return _fallbackName(a, b);
          }
          return compare;
        };
        break;
      case PlaylistSortFeature.name:
        c = (a, b) {
          final compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (compare == 0) {
            return _fallbackDateModified(a, b);
          }
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (order == SortOrder.descending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}

class ArtistSort extends Sort<Artist> {
  const ArtistSort({
    required super.feature,
    super.order = SortOrder.ascending,
  });
  ArtistSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory ArtistSort.fromMap(Map map) => ArtistSort(
        feature: ArtistSortFeature.values.byName(map['feature']),
        order: SortOrder.values.byName(map['order'] ?? 'ascending'),
      );

  @override
  ArtistSort copyWith({
    covariant ArtistSortFeature? feature,
    SortOrder? order,
  }) {
    return ArtistSort(
      feature: feature ?? this.feature as ArtistSortFeature,
      order: order ?? this.order,
    );
  }

  int _fallbackName(Artist a, Artist b) {
    return a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
  }

  int _fallbackNumberOfTracks(Artist a, Artist b) {
    return a.numberOfTracks.compareTo(b.numberOfTracks);
  }

  @override
  Comparator<Artist> get comparator {
    Comparator<Artist> c;
    switch (feature) {
      case ArtistSortFeature.name:
        c = (a, b) {
          final compare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (compare == 0) {
            return _fallbackNumberOfTracks(a, b);
          }
          return compare;
        };
        break;
      case ArtistSortFeature.numberOfAlbums:
        c = (a, b) {
          final compare = a.numberOfAlbums.compareTo(b.numberOfAlbums);
          if (compare == 0) {
            return _fallbackName(a, b);
          }
          return compare;
        };
        break;
      case ArtistSortFeature.numberOfTracks:
        c = (a, b) {
          final compare = a.numberOfTracks.compareTo(b.numberOfTracks);
          if (compare == 0) {
            return _fallbackName(a, b);
          }
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (order == SortOrder.descending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}
