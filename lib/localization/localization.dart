export 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Gets [AppLocalizations].
AppLocalizations getl10n(BuildContext context) => AppLocalizations.of(context)!;

/// Gets [AppLocalizations] without context.
AppLocalizations get staticl10n {
  try {
    return lookupAppLocalizations(WidgetsBinding.instance.window.locale);
  } catch (ex) {
    // Load default locale.
    return lookupAppLocalizations(const Locale('en', 'US'));
  }
}

extension AppLocalizationsExtension on AppLocalizations {
  //* Content ******************

  /// Picks a string of a [ContentType] in plural form.
  /// For example "tracks".
  String contents(ContentType contentType) {
    switch (contentType) {
      case ContentType.song:
        return tracks;
      case ContentType.album:
        return albums;
      case ContentType.playlist:
        return playlists;
      case ContentType.artist:
        return artists;
    }
  }

  /// Calls a `plural` getter from Intl for a [ContentType].
  /// Returns string in form "5 songs".
  String contentsPlural(ContentType contentType, int count) {
    switch (contentType) {
      case ContentType.song:
        return tracksPlural(count);
      case ContentType.album:
        return albumsPlural(count);
      case ContentType.playlist:
        return playlistsPlural(count);
      case ContentType.artist:
        return artistsPlural(count);
    }
  }

  String sortFeature<T extends Content>(ContentType contentType, SortFeature<T> feature) {
    switch (contentType) {
      case ContentType.song:
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
            return album;
          default:
            throw UnimplementedError();
        }
      case ContentType.album:
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
      case ContentType.playlist:
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
      case ContentType.artist:
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
    }
  }

  /// Transforms the [text] so it can be safely embedded into [StyledText] text.
  /// See: https://pub.dev/packages/styled_text#escaping--special-characters
  String escapeStyled(String text) {
    return text.replaceAllMapped(RegExp('["\'&<> ]'), (match) {
      switch (match.group(0)) {
        case '"':
          return '&quot;';
        case '\'':
          return '&apos;';
        case '&':
          return '&amp;';
        case '<':
          return '&lt;';
        case '>':
          return '&gt;';
        case ' ':
          return '&space;';
      }
      throw UnimplementedError('"${match.group(0)}" is not implemented');
    });
  }
}
