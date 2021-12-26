/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Gets [AppLocalizations].
AppLocalizations getl10n(BuildContext context) => AppLocalizations.of(context)!;

/// Gets [AppLocalizations] without context.
///
/// If you want to use [AppLocalizations] without flutter app mounting,
/// you have to call [initL10n] first.
AppLocalizations get staticl10n => lookupAppLocalizations(WidgetsBinding.instance!.window.locale);

/// Can be used to load the current locale delegate before/without Flutter app mounting
/// to use [staticl10n].
Future<void> initL10n() async {
  await AppLocalizations.delegate.load(WidgetsBinding.instance!.window.locale);
}

extension AppLocalizationsUtils on AppLocalizations {
  _AppLocalizationsUtils get utils => _AppLocalizationsUtils(this);
}

class _AppLocalizationsUtils {
  _AppLocalizationsUtils(this._l);
  final AppLocalizations _l;

  //* Content ******************

  String get track {
    return _l.tracksPlural(1);
  }

  String get album {
    return _l.albumsPlural(1);
  }

  String get playlist {
    return _l.playlistsPlural(1);
  }

  String get artist {
    return _l.artistsPlural(1);
  }

  /// Picks a string of a [Content] in plural form.
  /// For example "tracks".
  String contents<T extends Content>([Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => _l.tracks,
      album: () => _l.albums,
      playlist: () => _l.playlists,
      artist: () => _l.artists,
    )();
  }

  /// Returns string in form "5 songs".
  String contentsPluralWithCount<T extends Content>(int count, [Type? contentType]) {
    return '$count ${contentsPlural<T>(count, contentType).toLowerCase()}';
  }

  /// Calls a `plural` getter from Intl for a [Content].
  String contentsPlural<T extends Content>(int count, [Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => _l.tracksPlural(count),
      album: () => _l.albumsPlural(count),
      playlist: () => _l.playlistsPlural(count),
      artist: () => _l.artistsPlural(count),
    )();
  }

  String sortFeature<T extends Content>(SortFeature<T> feature, [Type? contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () {
        switch (feature as SongSortFeature) {
          case SongSortFeature.dateModified:
            return _l.dateModified;
          case SongSortFeature.dateAdded:
            return _l.dateAdded;
          case SongSortFeature.title:
            return _l.title;
          case SongSortFeature.artist:
            return artist;
          case SongSortFeature.album:
            return _l.albumsPlural(1);
          default:
            throw UnimplementedError();
        }
      },
      album: () {
        switch (feature as AlbumSortFeature) {
          case AlbumSortFeature.title:
            return _l.title;
          case AlbumSortFeature.artist:
            return artist;
          case AlbumSortFeature.year:
            return _l.year;
          case AlbumSortFeature.numberOfSongs:
            return _l.numberOfTracks;
          default:
            throw UnimplementedError();
        }
      },
      playlist: () {
        switch (feature as PlaylistSortFeature) {
          case PlaylistSortFeature.dateModified:
            return _l.dateModified;
          case PlaylistSortFeature.dateAdded:
            return _l.dateAdded;
          case PlaylistSortFeature.name:
            return _l.title;
          default:
            throw UnimplementedError();
        }
      },
      artist: () {
        switch (feature as ArtistSortFeature) {
          case ArtistSortFeature.name:
            return _l.name;
          case ArtistSortFeature.numberOfAlbums:
            return _l.numberOfAlbums;
          case ArtistSortFeature.numberOfTracks:
            return _l.numberOfTracks;
          default:
            throw UnimplementedError();
        }
      },
    )();
  }
}
