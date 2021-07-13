/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// TODO: remove this (and other similar) when intl_translation supports nnbd https://github.com/dart-lang/intl_translation/issues/134
// @dart = 2.7

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:multiple_localization/multiple_localization.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

import 'gen/messages_all.dart';

/// Gets [AppLocalizations].
AppLocalizations getl10n(BuildContext context) => AppLocalizations.of(context);

/// Gets [AppLocalizations] without context.
/// If you want to use [AppLocalizations] without flutter app mounting,
/// you have to [AppLocalizations.init] first.
AppLocalizations get staticl10n => AppLocalizations.instance;

class AppLocalizations {
  AppLocalizations._();
  static final instance = AppLocalizations._();
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Can be used to load the delegate before/without flutter app mounting
  /// by using the current system locale.
  static Future<void> init() async {
    await load(WidgetsBinding.instance.window.locale);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    return MultipleLocalizations.load(
      initializeMessages,
      locale,
      (locale) => AppLocalizations.instance,
      /// I chosen to override `defaultLocale` because of this issue
      /// https://github.com/dart-lang/intl_translation/issues/141
      setDefaultLocale: true,
    );
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  //* Used in notification ******************
  
  /// Used as notification channel name.
  String get playback {
    return Intl.message(
      "Playback",
      name: 'playback',
    );
  }

  /// Used as notification channel description.
  String get playbackControls {
    return Intl.message(
      "Playback controls",
      name: 'playbackControls',
    );
  }

  String get play {
    return Intl.message(
      "Play",
      name: 'play',
    );
  }

  String get pause {
    return Intl.message(
      "Pause",
      name: 'pause',
    );
  }

  String get stop {
    return Intl.message(
      "Stop",
      name: 'stop',
    );
  }

  String get next {
    return Intl.message(
      "Next",
      name: 'next',
    );
  }

  String get previous {
    return Intl.message(
      "Previous",
      name: 'previous',
    );
  }

  String get loopOff {
    return Intl.message(
      "Loop off",
      name: 'loopOff',
    );
  }

  String get loopOn {
    return Intl.message(
      "Loop on",
      name: 'loopOn',
    );
  }

  //* Quick actions ******************
  
  String get search {
    return Intl.message(
      "Search",
      name: 'search',
    );
  }

  String get shuffleAll {
    return Intl.message(
      "Shuffle all",
      name: 'shuffleAll',
    );
  }

  String get playRecent {
    return Intl.message(
      "Play recent",
      name: 'playRecent',
    );
  }

  //* Content ******************

  /// Label for unknown artist.
  String get artistUnknown {
    return Intl.message(
      "Unknown artist",
      name: 'artistUnknown',
    );
  }

  String get track {
    return tracksPlural(1);
  }

  String get album {
    return albumsPlural(1);
  }

  String get playlist {
    return playlistsPlural(1);
  }

  String get artist {
    return artistsPlural(1);
  }

  String get tracks {
    return Intl.message(
      "Tracks",
      name: 'tracks',
    );
  }

  String get albums {
    return Intl.message(
      "Albums",
      name: 'albums',
    );
  }

  String get playlists {
    return Intl.message(
      "Playlists",
      name: 'playlists',
    );
  }

  String get artists {
    return Intl.message(
      "Artists",
      name: 'artists',
    );
  }

  /// Picks a string of a [Content] in plural form.
  /// For example "tracks".
  String contents<T extends Content>([Type contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => tracks,
      album: () => albums,
      playlist: () => playlists,
      artist: () => artists,
    )();
  }

  String tracksPlural(int count) {
    return Intl.plural(
      count,
      zero: "Tracks",
      one: "Track",
      two: "Tracks",
      few: "Tracks",
      many: "Tracks",
      other: "Tracks",
      args: [count],
      name: 'tracksPlural',
    );
  }

  String albumsPlural(int count) {
    return Intl.plural(
      count,
      zero: "Albums",
      one: "Album",
      two: "Albums",
      few: "Albums",
      many: "Albums",
      other: "Albums",
      args: [count],
      name: 'albumsPlural',
    );
  }

  String playlistsPlural(int count) {
    return Intl.plural(
      count,
      zero: "Playlists",
      one: "Playlist",
      two: "Playlists",
      few: "Playlists",
      many: "Playlists",
      other: "Playlists",
      args: [count],
      name: 'playlistsPlural',
    );
  }

  String artistsPlural(int count) {
    return Intl.plural(
      count,
      zero: "Artists",
      one: "Artist",
      two: "Artists",
      few: "Artists",
      many: "Artists",
      other: "Artists",
      args: [count],
      name: 'artistsPlural',
    );
  }

  /// Returns string in form "5 songs".
  String contentsPluralWithCount<T extends Content>(int count, [Type contentType]) {
    return '$count ${contentsPlural<T>(count, contentType).toLowerCase()}';
  }

  /// Calls a `plural` getter from Intl for a [Content].
  String contentsPlural<T extends Content>(int count, [Type contentType]) {
    return contentPick<T, ValueGetter<String>>(
      contentType: contentType,
      song: () => tracksPlural(count),
      album: () => albumsPlural(count),
      playlist: () => playlistsPlural(count),
      artist: () => artistsPlural(count),
    )();
  }

  String get albumNotFound {
    return Intl.message(
      "Album not found",
      name: 'albumNotFound',
    );
  }

  String get artistNotFound {
    return Intl.message(
      "Artist not found",
      name: 'artistNotFound',
    );
  }

  String get allTracks {
    return Intl.message(
      "All tracks",
      name: 'allTracks',
    );
  }

  String get allAlbums {
    return Intl.message(
      "All albums",
      name: 'allAlbums',
    );
  }

  String get allPlaylists {
    return Intl.message(
      "All playlists",
      name: 'allPlaylists',
    );
  }

  String get allArtists {
    return Intl.message(
      "All artitst",
      name: 'allArtists',
    );
  }

  String get arbitraryQueue {
    return Intl.message(
      "Arbitrary queue",
      name: 'arbitraryQueue',
    );
  }

  // NOTE: currently unused
  String get shuffled {
    return Intl.message(
      "Shuffled",
      name: 'shuffled',
    );
  }

  // NOTE: currently unused
  String get modified {
    return Intl.message(
      "Modified",
      name: 'modified',
    );
  }

  String get byQuery {
    return Intl.message(
      "By query",
      name: 'byQuery',
    );
  }

  /// Should be in plural form
  String get selectedPlural {
    return Intl.message(
      "Selected",
      name: 'selectedPlural',
    );
  }

  //* Playlists **********

  String get newPlaylist {
    return Intl.message(
      "New playlist",
      name: 'newPlaylist',
    );
  }

  String get trackAfterWhichToInsert {
    return Intl.message(
      "Track after which to insert",
      name: 'trackAfterWhichToInsert',
    );
  }

  String get insertAtTheBeginning {
    return Intl.message(
      "Insert at the beginning",
      name: 'insertAtTheBeginning',
    );
  }

  String get saveQueueAsPlaylist {
    return Intl.message(
      "Save queue as playlist",
      name: 'saveQueueAsPlaylist',
    );
  }

  //* Generic ******************

  /// Displayed in list headers in button to play it.
  String get playContentList {
    return Intl.message(
      "Play",
      name: 'playContentList',
    );
  }

  /// Displayed in list headers in button to shuffle it.
  String get shuffleContentList {
    return Intl.message(
      "Shuffle",
      name: 'shuffleContentList',
    );
  }

  String get debug {
    return Intl.message(
      'Debug',
      name: 'debug',
    );
  }

  String get areYouSure {
    return Intl.message(
      "Are you sure?",
      name: 'areYouSure',
    );
  }

  String get areYouSureYouWantTo {
    return Intl.message(
      "Are you sure you want to",
      name: 'areYouSureYouWantTo',
    );
  }

  String get reset {
    return Intl.message(
      "Reset",
      name: 'reset',
    );
  }

  String get save {
    return Intl.message(
      "Save",
      name: 'save',
    );
  }

  String get saved {
    return Intl.message(
      "Saved",
      name: 'saved',
    );
  }

  String get view {
    return Intl.message(
      "View",
      name: 'view',
    );
  }

  // TODO: currently unused
  String get secondsShorthand {
    return Intl.message(
      "s",
      name: 'secondsShorthand',
    );
  }

  // TODO: currently unused
  String get minutesShorthand {
    return Intl.message(
      "min",
      name: 'minutesShorthand',
    );
  }

  String get and {
    return Intl.message(
      "And",
      name: 'and',
    );
  }

  String get more {
    return Intl.message(
      "More",
      name: 'more',
    );
  }

  /// "And 3 more"
  String andNMore(int count) {
    return "${and.toLowerCase()} $count ${more.toLowerCase()}";
  }

  String get done {
    return Intl.message(
      "Done",
      name: 'done',
    );
  }

  String get create {
    return Intl.message(
      "Create",
      name: 'create',
    );
  }

  String get add {
    return Intl.message(
      "Add",
      name: 'add',
    );
  }

  String get remove {
    return Intl.message(
      "Remove",
      name: 'remove',
    );
  }

  String get delete {
    return Intl.message(
      "Delete",
      name: 'delete',
    );
  }

  String get deletion {
    return Intl.message(
      "Deletion",
      name: 'deletion',
    );
  }

  String get edit {
    return Intl.message(
      "Edit",
      name: 'edit',
    );
  }

  String get refresh {
    return Intl.message(
      "Refresh",
      name: 'refresh',
    );
  }

  String get grant {
    return Intl.message(
      "Grant",
      name: 'grant',
    );
  }

  String get nothingHere {
    return Intl.message(
      "There's nothing here",
      name: 'nothingHere',
    );
  }

  String get details {
    return Intl.message(
      "Details",
      name: 'details',
    );
  }

  String get songInformation {
    return Intl.message(
      "Track information",
      name: 'songInformation',
    );
  }

  // TODO: currently unused
  String get editMetadata {
    return Intl.message(
      "Edit metadata",
      name: 'editMetadata',
    );
  }

  String get found {
    return Intl.message(
      "Found",
      name: 'found',
    );
  }

  String get upNext {
    return Intl.message(
      "Up next",
      name: 'upNext',
    );
  }

  String get almostThere {
    return Intl.message(
      "You're almost there",
      name: 'almostThere',
    );
  }

  String get pressOnceAgainToExit {
    return Intl.message(
      "Press once again to exit",
      name: 'pressOnceAgainToExit',
    );
  }

  String get noMusic {
    return Intl.message(
      "There's no music on your device",
      name: 'noMusic',
    );
  }

  String get searchingForTracks {
    return Intl.message(
      "Searching for tracks...",
      name: 'searchingForTracks',
    );
  }

  String get allowAccessToExternalStorage {
    return Intl.message(
      "Please, allow access to storage",
      name: 'allowAccessToExternalStorage',
    );
  }

  String get allowAccessToExternalStorageManually {
    return Intl.message(
      "Allow access to storage manually",
      name: 'allowAccessToExternalStorageManually',
    );
  }

  String get selected {
    return Intl.message(
      "Selected",
      name: 'selected',
    );
  }

  // TODO: currently unused
  String get actions {
    return Intl.message(
      "Actions",
      name: 'actions',
    );
  }

  String get goToAlbum {
    return Intl.message(
      "Go to album",
      name: 'goToAlbum',
    );
  }

  String get goToArtist {
    return Intl.message(
      "Go to artist",
      name: 'goToArtist',
    );
  }

  String get playNext {
    return Intl.message(
      "Play next",
      name: 'playNext',
    );
  }

  String get addToPlaylist {
    return Intl.message(
      "Add to playlist",
      name: 'addToPlaylist',
    );
  }

  String get removeFromPlaylist {
    return Intl.message(
      "Remove from playlist",
      name: 'removeFromPlaylist',
    );
  }

  // TODO: currently unused
  String get addToFavorites {
    return Intl.message(
      "Add to favorites",
      name: 'addToFavorites',
    );
  }
  
  String get addToQueue {
    return Intl.message(
      "Add to queue",
      name: 'addToQueue',
    );
  }

  String get removeFromQueue {
    return Intl.message(
      "Remove from queue",
      name: 'removeFromQueue',
    );
  }

  // TODO: currently unused
  String get share {
    return Intl.message(
      "Share",
      name: 'share',
    );
  }

  String get selectAll {
    return Intl.message(
      "Select all",
      name: 'selectAll',
    );
  }

  //* Sort *****************

  String get sort {
    return Intl.message(
      "Sort",
      name: 'sort',
    );
  }
  
  String get title {
    return Intl.message(
      "Title",
      name: 'title',
    );
  }

  String get name {
    return Intl.message(
      "Name",
      name: 'name',
    );
  }

  String get dateModified {
    return Intl.message(
      "Date modified",
      name: 'dateModified',
    );
  }

  String get dateAdded {
    return Intl.message(
      "Date added",
      name: 'dateAdded',
    );
  }

  String get year {
    return Intl.message(
      "Year",
      name: 'year',
    );
  }

  String get numberOfTracks {
    return Intl.message(
      "Number of tracks",
      name: 'numberOfTracks',
    );
  }

  String get numberOfAlbums {
    return Intl.message(
      "Number of albums",
      name: 'numberOfAlbums',
    );
  }

  String sortFeature<T extends Content>(SortFeature<T> feature, [Type contentType]) {
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

  //* Dev route ******************
  String get devModeGreet {
    return Intl.message(
      "Done! You are now a developer",
      name: 'devModeGreet',
    );
  }

  /// Shown when user tapped 4 times on app logo
  String get onThePathToDevMode {
    return Intl.message(
      "Something should happen now...",
      name: 'onThePathToDevMode',
    );
  }

  /// Shown when user is about to become a developer, part 2
  String get onThePathToDevModeLastClick {
    return Intl.message(
      "only 1 click remaining...",
      name: 'onThePathToDevModeLastClick',
    );
  }

  /// Shown when user is about to become a developer, part 2, plural
  String onThePathToDevModeClicksRemaining(int remainingClicks) {
    return Intl.message(
      "only $remainingClicks clicks remaining...",
      name: 'onThePathToDevModeClicksRemaining',
      args: [remainingClicks],
    );
  }

  String get devTestToast {
    return Intl.message(
      "Test toast",
      name: 'devTestToast',
    );
  }

  String get devAnimationsSlowMo {
    return Intl.message(
      "Slow down animations",
      name: 'devAnimationsSlowMo',
    );
  }

  String get quitDevMode {
    return Intl.message(
      "Quit the developer mode",
      name: 'quitDevMode',
    );
  }

  String get quitDevModeDescription {
    return Intl.message(
      "Stop being a developer?",
      name: 'quitDevModeDescription',
    );
  }

  //* Settings routes ******************

  String get settings {
    return Intl.message(
      "Settings",
      name: 'settings',
    );
  }

  String get general {
    return Intl.message(
      "General",
      name: 'general',
    );
  }

  String get theme {
    return Intl.message(
      "Theme",
      name: 'theme',
    );
  }

  String get settingLightMode {
    return Intl.message(
      "Light mode",
      name: 'settingLightMode',
    );
  }

  //* Search route ******************

  String get searchHistory {
    return Intl.message(
      "Search history",
      name: 'searchHistory',
    );
  }

  String get searchHistoryPlaceholder {
    return Intl.message(
      "Your search history will be displayed here",
      name: 'searchHistoryPlaceholder',
    );
  }

  String get searchNothingFound {
    return Intl.message(
      "Nothing found",
      name: 'searchNothingFound',
    );
  }

  /// The [entry] is the history entry to delete.
  /// The description is being splitted into rich text there.
  String get searchHistoryRemoveEntryDescriptionP1 {
    return Intl.message(
      "Are you sure you want to remove ",
      name: 'searchHistoryRemoveEntryDescriptionP1',
    );
  }

  String get searchHistoryRemoveEntryDescriptionP2 {
    return Intl.message(
      " from your search history?",
      name: 'searchHistoryRemoveEntryDescriptionP2',
    );
  }

  String get searchClearHistory {
    return Intl.message(
      "Clear search history?",
      name: 'searchClearHistory',
    );
  }

  //* Errors ******************
  String get oopsErrorOccurred {
    return Intl.message(
      "Oops! An error occurred",
      name: 'oopsErrorOccurred',
    );
  }

  String get errorDetails {
    return Intl.message(
      "Error details",
      name: 'errorDetails',
    );
  }

  String get deletionError {
    return Intl.message(
      "Deletion error",
      name: 'deletionError',
    );
  }

  String get playlistDoesNotExistError {
    return Intl.message(
      "Can't find the playlist, perhaps it was deleted",
      name: 'playlistDoesNotExistError',
    );
  }

  String get playbackError {
    return Intl.message(
      "An error occurred during the playback",
      name: 'playbackError',
    );
  }

  String get openAppSettingsError {
    return Intl.message(
      "Error opening the app settings",
      name: 'openAppSettingsError',
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return Constants.Config.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return true;
  }
}
