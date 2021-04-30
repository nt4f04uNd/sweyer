/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/logic/logic.dart';

/// Inteface for other sort feature enums.
abstract class SortFeature<T extends Content> extends Enum<String> {
  const SortFeature._(String value) : super(value);

  /// Returns sort feature values for a given content.
  static List<SortFeature> getValuesForContent<T extends Content>() {
    return contentPick<T, ValueGetter<List<SortFeature>>>(
      song: () => SongSortFeature.values,
      album: () => AlbumSortFeature.values,
      playlist: () => PlaylistSortFeature.values,
      artist: () => ArtistSortFeature.values,
    )();
  }

  /// Whether the default order is ASC.
  bool get defaultOrderAscending;
}

/// Features to sort by a [Song] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [SongSortFeature] the new default sort order is applied.
class SongSortFeature extends SortFeature<Song> {
  const SongSortFeature._(String value) : super._(value);

  @override
  bool get defaultOrderAscending => this != dateModified && this != dateAdded;

  static List<SongSortFeature> get values {
    return [dateModified, dateAdded, title, artist, album];
  }

  /// Sort by the [Song.dateModified].
  /// Default sort order is DESC.
  static const dateModified = SongSortFeature._('dateModified');

  /// Sort by the [Song.dateAdded].
  /// Default sort order is DESC.
  static const dateAdded = SongSortFeature._('dateAdded');

  /// Sort by the [Song.title].
  /// Default sort order is ASC.
  static const title = SongSortFeature._('title');

  /// Sort by the [Song.artist].
  /// Default sort order is ASC.
  static const artist = SongSortFeature._('artist');

  /// Sort by the [Song.album].
  /// Default sort order is ASC.
  static const album = SongSortFeature._('album');
}

/// Features to sort by a [Album] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [AlbumSortFeature] the new default sort order is applied.
class AlbumSortFeature extends SortFeature<Album> {
  const AlbumSortFeature._(String value) : super._(value);

  @override
  bool get defaultOrderAscending => this != year;

  static List<AlbumSortFeature> get values {
    return [title, artist, year, numberOfSongs];
  }

  /// Sort by the [Album.album].
  /// Default sort order is ASC.
  static const title = AlbumSortFeature._('title');

  /// Sort by the [Album.artist].
  /// Default sort order is ASC.
  static const artist = AlbumSortFeature._('artist');

  /// Sort by the [Album.lastYear].
  /// Default sort order is DESC.
  static const year = AlbumSortFeature._('year');

  /// Sort by the [Album.numberOfSongs].
  /// Default sort order is ASC.
  static const numberOfSongs = AlbumSortFeature._('numberOfSongs');
}

/// Features to sort by a [Playlist] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [PlaylistSortFeature] the new default sort order is applied.
class PlaylistSortFeature extends SortFeature<Playlist> {
  const PlaylistSortFeature._(String value) : super._(value);

  @override
  bool get defaultOrderAscending => this != dateModified && this != dateAdded;

  static List<PlaylistSortFeature> get values {
    return [dateAdded, dateModified, name];
  }

  /// Sort by the [Playlist.dateModified].
  /// Default sort order is DESC.
  static const dateModified = PlaylistSortFeature._('dateModified');

  /// Sort by the [Playlist.dateAdded].
  /// Default sort order is DESC.
  static const dateAdded = PlaylistSortFeature._('dateAdded');

  /// Sort by the [Playlist.name].
  /// Default sort order is ASC.
  static const name = PlaylistSortFeature._('name');
}

/// Features to sort by a [Artist] list.
///
/// Each feature also has the default sort order - ASC or DESC.
/// When user changes the [ArtistSortFeature] the new default sort order is applied.
class ArtistSortFeature extends SortFeature<Artist> {
  const ArtistSortFeature._(String value) : super._(value);

  @override
  bool get defaultOrderAscending => true;

  static List<ArtistSortFeature> get values {
    return [name, numberOfAlbums, numberOfTracks];
  }

  /// Sort by the [Artist.artist].
  /// Default sort order is ASC.
  static const name = ArtistSortFeature._('name');

  /// Sort by the [Artist.numberOfAlbums].
  /// Default sort order is ASC.
  static const numberOfAlbums = ArtistSortFeature._('numberOfAlbums');

  /// Sort by the [Artist.numberOfTracks].
  /// Default sort order is ASC.
  static const numberOfTracks = ArtistSortFeature._('numberOfTracks');
}

abstract class Sort<T extends Content> extends Equatable {
  const Sort({
    required this.feature,
    required this.orderAscending,
  });
  Sort.defaultOrder(this.feature)
      : orderAscending = feature.defaultOrderAscending;

  final SortFeature<T> feature;
  final bool orderAscending;

  @override
  List<Object> get props => [feature, orderAscending];

  Sort<T> copyWith({SortFeature? feature, bool? orderAscending});
  Sort<T> get withDefaultOrder;

  Comparator<T> get comparator;

  Map<String, dynamic> toMap() => {
      'feature': feature.value,
      'orderAscending': orderAscending,
    };
}

class SongSort extends Sort<Song> {
  const SongSort({
    required SongSortFeature feature,
    bool orderAscending = true,
  }) : super(feature: feature, orderAscending: orderAscending);
  SongSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory SongSort.fromMap(Map map) => SongSort(
        feature: EnumToString.fromString(
          SongSortFeature.values,
          map['feature'],
        )!,
        orderAscending: map['orderAscending'],
      );

  @override
  SongSort copyWith({
    covariant SongSortFeature? feature,
    bool? orderAscending,
  }) {
    return SongSort(
      feature: feature ?? this.feature as SongSortFeature,
      orderAscending: orderAscending ?? this.orderAscending,
    );
  }

  @override
  SongSort get withDefaultOrder {
    return copyWith(orderAscending: feature.defaultOrderAscending);
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
          if (compare == 0)
            return _fallbackTitle(a, b);
          return compare;
        };
        break;
      case SongSortFeature.dateAdded:
        c = (a, b) {
          final compare = a.dateAdded.compareTo(b.dateAdded);
          if (compare == 0)
            return _fallbackTitle(a, b);
          return compare;
        };
        break;
      case SongSortFeature.title:
        c = (a, b) {
          final compare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (compare == 0)
            return _fallbackDateModified(a, b);
          return compare;
        };
        break;
      case SongSortFeature.artist:
        c = (a, b) {
          final compare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (compare == 0)
            return _fallbackTitle(a, b);
          return compare;
        };
        break;
      case SongSortFeature.album:
        c = (a, b) {
          final compare = a.album!.toLowerCase().compareTo(b.album!.toLowerCase());
          if (compare == 0)
            return _fallbackTitle(a, b);
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (!orderAscending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}

class AlbumSort extends Sort<Album> {
  const AlbumSort({
    required AlbumSortFeature feature,
    bool orderAscending = true,
  }) : super(feature: feature, orderAscending: orderAscending);
  AlbumSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory AlbumSort.fromMap(Map map) => AlbumSort(
        feature: EnumToString.fromString(
          AlbumSortFeature.values,
          map['feature'],
        )!,
        orderAscending: map['orderAscending'],
      );

  @override
  Map<String, dynamic> toMap() => {
        'feature': feature.value,
        'orderAscending': orderAscending,
      };

  @override
  AlbumSort copyWith({
    covariant AlbumSortFeature? feature,
    bool? orderAscending,
  }) {
    return AlbumSort(
      feature: feature ?? this.feature as AlbumSortFeature,
      orderAscending: orderAscending ?? this.orderAscending,
    );
  }

  @override
  AlbumSort get withDefaultOrder {
    return copyWith(orderAscending: feature.defaultOrderAscending);
  }

  int _fallbackYear(Album a, Album b) {
    return a.year.compareTo(b.year);
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
          if (compare == 0)
            return _fallbackYear(a, b);
          return compare;
        };
        break;
      case AlbumSortFeature.artist:
        c = (a, b) {
          final compare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (compare == 0)
            return _fallbackYear(a, b);
          return compare;
        };
        break;
      case AlbumSortFeature.year:
        c = (a, b) {
          final compare = a.year.compareTo(b.year);
          if (compare == 0)
            return _fallbackTitle(a, b);
          return compare;
        };
        break;
      case AlbumSortFeature.numberOfSongs:
        c = (a, b) {
          final compare = a.numberOfSongs.compareTo(b.numberOfSongs);
          if (compare == 0)
            return _fallbackYear(a, b);
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (!orderAscending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}


class PlaylistSort extends Sort<Playlist> {
  const PlaylistSort({
    required PlaylistSortFeature feature,
    bool orderAscending = true,
  }) : super(feature: feature, orderAscending: orderAscending);
  PlaylistSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory PlaylistSort.fromMap(Map map) => PlaylistSort(
        feature: EnumToString.fromString(
          PlaylistSortFeature.values,
          map['feature'],
        )!,
        orderAscending: map['orderAscending'],
      );

  @override
  Map<String, dynamic> toMap() => {
        'feature': feature.value,
        'orderAscending': orderAscending,
      };

  @override
  PlaylistSort copyWith({
    covariant PlaylistSortFeature? feature,
    bool? orderAscending,
  }) {
    return PlaylistSort(
      feature: feature ?? this.feature as PlaylistSortFeature,
      orderAscending: orderAscending ?? this.orderAscending,
    );
  }

  @override
  PlaylistSort get withDefaultOrder {
    return copyWith(orderAscending: feature.defaultOrderAscending);
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
          if (compare == 0)
            return _fallbackName(a, b);
          return compare;
        };
        break;
      case PlaylistSortFeature.dateAdded:
        c = (a, b) {
          final compare = a.dateAdded.compareTo(b.dateAdded);
          if (compare == 0)
            return _fallbackName(a, b);
          return compare;
        };
        break;
      case PlaylistSortFeature.name:
        c = (a, b) {
          final compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (compare == 0)
            return _fallbackDateModified(a, b);
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (!orderAscending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}

class ArtistSort extends Sort<Artist> {
  const ArtistSort({
    required ArtistSortFeature feature,
    bool orderAscending = true,
  }) : super(feature: feature, orderAscending: orderAscending);
  ArtistSort.defaultOrder(feature) : super.defaultOrder(feature);

  factory ArtistSort.fromMap(Map map) => ArtistSort(
        feature: EnumToString.fromString(
          ArtistSortFeature.values,
          map['feature'],
        )!,
        orderAscending: map['orderAscending'],
      );

  @override
  Map<String, dynamic> toMap() => {
        'feature': feature.value,
        'orderAscending': orderAscending,
      };

  @override
  ArtistSort copyWith({
    covariant ArtistSortFeature? feature,
    bool? orderAscending,
  }) {
    return ArtistSort(
      feature: feature ?? this.feature as ArtistSortFeature,
      orderAscending: orderAscending ?? this.orderAscending,
    );
  }

  @override
  ArtistSort get withDefaultOrder {
    return copyWith(orderAscending: feature.defaultOrderAscending);
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
          if (compare == 0)
            return _fallbackNumberOfTracks(a, b);
          return compare;
        };
        break;
      case ArtistSortFeature.numberOfAlbums:
        c = (a, b) {
          final compare = a.numberOfAlbums.compareTo(b.numberOfAlbums);
          if (compare == 0)
            return _fallbackName(a, b);
          return compare;
        };
        break;
      case ArtistSortFeature.numberOfTracks:
        c = (a, b) {
          final compare = a.numberOfTracks.compareTo(b.numberOfTracks);
          if (compare == 0)
            return _fallbackName(a, b);
          return compare;
        };
        break;
      default:
        throw UnimplementedError();
    }
    if (!orderAscending) {
      return (a, b) => c(b, a);
    }
    return c;
  }
}
