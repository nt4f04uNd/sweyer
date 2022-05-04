export 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Gets [AppLocalizations].
AppLocalizations getl10n(BuildContext context) => AppLocalizations.of(context)!;

/// Gets [AppLocalizations] without context.
AppLocalizations get staticl10n {
  try {
    return lookupAppLocalizations(WidgetsBinding.instance!.window.locale);
  } catch (ex) {
    // Load default locale.
    return lookupAppLocalizations(const Locale('en', 'US'));
  }
}

extension AppLocalizationsExtension on AppLocalizations {
  //* Content ******************

  /// Picks a string of a [Content] in plural form.
  /// For example "tracks".
  String contents<T extends Content>([Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => tracks,
      album: () => albums,
      playlist: () => playlists,
      artist: () => artists,
    )();
  }

  /// Calls a `plural` getter from Intl for a [Content].
  /// Returns string in form "5 songs".
  String contentsPlural<T extends Content>(int count, [Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => tracksPlural(count),
      album: () => albumsPlural(count),
      playlist: () => playlistsPlural(count),
      artist: () => artistsPlural(count),
    )();
  }

  String sortFeature<T extends Content>(SortFeature<T> feature, [Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () {
        switch (feature as SongSortFeature) {
          case SongSortFeature.dateModified:
            return dateModified;
          case SongSortFeature.dateAdded:
            return dateAdded;
          case SongSortFeature.title:
            return title;
          case SongSortFeature.artist:
            return artist;
          case SongSortFeature.album:
            return albumsPlural(1);
          default:
            throw UnimplementedError();
        }
      },
      album: () {
        switch (feature as AlbumSortFeature) {
          case AlbumSortFeature.title:
            return title;
          case AlbumSortFeature.artist:
            return artist;
          case AlbumSortFeature.year:
            return year;
          case AlbumSortFeature.numberOfSongs:
            return numberOfTracks;
          default:
            throw UnimplementedError();
        }
      },
      playlist: () {
        switch (feature as PlaylistSortFeature) {
          case PlaylistSortFeature.dateModified:
            return dateModified;
          case PlaylistSortFeature.dateAdded:
            return dateAdded;
          case PlaylistSortFeature.name:
            return title;
          default:
            throw UnimplementedError();
        }
      },
      artist: () {
        switch (feature as ArtistSortFeature) {
          case ArtistSortFeature.name:
            return name;
          case ArtistSortFeature.numberOfAlbums:
            return numberOfAlbums;
          case ArtistSortFeature.numberOfTracks:
            return numberOfTracks;
          default:
            throw UnimplementedError();
        }
      },
    )();
  }
}
