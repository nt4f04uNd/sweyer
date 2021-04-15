/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

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
  AppLocalizations._(this.localeName);
  static AppLocalizations _instance;
  static AppLocalizations get instance => _instance;
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  final String localeName;

    /// Can be used to load the delegate before/without flutter app mounting
  /// by using the current system locale.
  static Future<void> init() async {
    await load(WidgetsBinding.instance.window.locale);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    return MultipleLocalizations.load(
      initializeMessages,
      locale,
      (locale) {
        _instance = AppLocalizations._(locale);
        return AppLocalizations.instance;
      },
    );
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  //* Used in notification
  String get play {
    return Intl.message(
      'Play',
      name: 'play',
      locale: localeName,
    );
  }

  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
      locale: localeName,
    );
  }

  String get stop {
    return Intl.message(
      'Stop',
      name: 'stop',
      locale: localeName,
    );
  }

  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      locale: localeName,
    );
  }

  String get previous {
    return Intl.message(
      'Previous',
      name: 'previous',
      locale: localeName,
    );
  }

  String get loopOff {
    return Intl.message(
      'Loop off',
      name: 'loopOff',
      locale: localeName,
    );
  }

  String get loopOn {
    return Intl.message(
      'Loop on',
      name: 'loopOn',
      locale: localeName,
    );
  }
  //*------------------------------------

  /// Label for unknown artist.
  String get artistUnknown {
    return Intl.message(
      'Unknown artist',
      name: 'artistUnknown',
      locale: localeName,
    );
  }

  String get track {
    return tracksPlural(1);
  }

  String get album {
    return albumsPlural(1);
  }

  String get tracks {
    return Intl.message(
      'Tracks',
      name: 'tracks',
      locale: localeName,
    );
  }

  String get albums {
    return Intl.message(
      'Albums',
      name: 'albums',
      locale: localeName,
    );
  }

  String tracksPlural(int count) {
    return Intl.plural(
      count,
      zero: 'Tracks',
      one: 'Track',
      two: 'Tracks',
      few: 'Tracks',
      many: 'Tracks',
      other: 'Tracks',
      args: [count],
      name: 'tracksPlural',
      locale: localeName,
    );
  }

  String albumsPlural(int count) {
    return Intl.plural(
      count,
      zero: 'Albums',
      one: 'Album',
      two: 'Albums',
      few: 'Albums',
      many: 'Albums',
      other: 'Albums',
      args: [count],
      name: 'albumsPlural',
      locale: localeName,
    );
  }

  String get allTracks {
    return Intl.message(
      "All tracks",
      name: 'allTracks',
      locale: localeName,
    );
  }

  String get playlist {
    return Intl.message(
      "Playlist",
      name: 'playlist',
      locale: localeName,
    );
  }

  String get arbitraryQueue {
    return Intl.message(
      'Arbitrary queue',
      name: 'arbitraryQueue',
      locale: localeName,
    );
  }

  String get allAlbums {
    return Intl.message(
      'All albums',
      name: 'allAlbums',
      locale: localeName,
    );
  }

  /// Converts [ArbitraryQueueOrigin] to human readable text.
  /// Returns `null` from `null` argument.
  String arbitraryQueueOrigin(ArbitraryQueueOrigin origin) {
    if (origin == null)
      return null;
    switch (origin) {
      case ArbitraryQueueOrigin.allAlbums: return allAlbums;
      default: throw UnimplementedError();
    }
  }

  // NOTE: currently unused
  String get shuffled {
    return Intl.message(
      "Shuffled",
      name: 'shuffled',
      locale: localeName,
    );
  }

  // NOTE: currently unused
  String get modified {
    return Intl.message(
      "Modified",
      name: 'modified',
      locale: localeName,
    );
  }

  String get byQuery {
    return Intl.message(
      "By query",
      name: 'byQuery',
      locale: localeName,
    );
  }

  /// Displayed in list headers in button to play it.
  String get playContentList {
    return Intl.message(
      "Play",
      name: 'playContentList',
      locale: localeName,
    );
  }

  /// Displayed in list headers in button to shuffle it.
  String get shuffleContentList {
    return Intl.message(
      "Shuffle",
      name: 'shuffleContentList',
      locale: localeName,
    );
  }

  String get debug {
    return Intl.message(
      'Debug',
      name: 'debug',
      locale: localeName,
    );
  }

  String get areYouSure {
    return Intl.message(
      'Are you sure?',
      name: 'areYouSure',
      locale: localeName,
    );
  }

  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      locale: localeName,
    );
  }

  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      locale: localeName,
    );
  }

  // todo: currently unused
  String get secondsShorthand {
    return Intl.message(
      's',
      name: 'secondsShorthand',
      locale: localeName,
    );
  }

  // todo: currently unused
  String get minutesShorthand {
    return Intl.message(
      'min',
      name: 'minutesShorthand',
      locale: localeName,
    );
  }

  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
      locale: localeName,
    );
  }

  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      locale: localeName,
    );
  }

  String get deletion {
    return Intl.message(
      'Deletion',
      name: 'deletion',
      locale: localeName,
    );
  }

  String get deletionError {
    return Intl.message(
      'Deletion error',
      name: 'deletionError',
      locale: localeName,
    );
  }

  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      locale: localeName,
    );
  }

  String get refresh {
    return Intl.message(
      'Refresh',
      name: 'refresh',
      locale: localeName,
    );
  }

  String get grant {
    return Intl.message(
      'Grant',
      name: 'grant',
      locale: localeName,
    );
  }

  String get errorMessage {
    return Intl.message(
      'Oops! An error occurred',
      name: 'errorMessage',
      locale: localeName,
    );
  }

  String get errorDetails {
    return Intl.message(
      'Error details',
      name: 'errorDetails',
      locale: localeName,
    );
  }

  String get playbackErrorMessage {
    return Intl.message(
      'An error occurred during the playback, removing the track',
      name: 'playbackErrorMessage',
      locale: localeName,
    );
  }

  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      locale: localeName,
    );
  }

  String get songInformation {
    return Intl.message(
      'Track information',
      name: 'songInformation',
      locale: localeName,
    );
  }

  String get editMetadata {
    return Intl.message(
      'Edit metadata',
      name: 'editMetadata',
      locale: localeName,
    );
  }

  String get unknownRoute {
    return Intl.message(
      'Unknown route!',
      name: 'unknownRoute',
      locale: localeName,
    );
  }

  String get found {
    return Intl.message(
      'Found',
      name: 'found',
      locale: localeName,
    );
  }

  String get upNext {
    return Intl.message(
      'Up next',
      name: 'upNext',
      locale: localeName,
    );
  }

  String get almostThere {
    return Intl.message(
      "You're almost there",
      name: 'almostThere',
      locale: localeName,
    );
  }

  String get pressOnceAgainToExit {
    return Intl.message(
      "Press once again to exit",
      name: 'pressOnceAgainToExit',
      locale: localeName,
    );
  }

  String get noMusic {
    return Intl.message(
      "There's no music on your device",
      name: 'noMusic',
      locale: localeName,
    );
  }

  String get searchingForTracks {
    return Intl.message(
      "Searching for tracks...",
      name: 'searchingForTracks',
      locale: localeName,
    );
  }

  String get allowAccessToExternalStorage {
    return Intl.message(
      "Please, allow access to storage",
      name: 'allowAccessToExternalStorage',
      locale: localeName,
    );
  }

  String get allowAccessToExternalStorageManually {
    return Intl.message(
      "Allow access to storage manually",
      name: 'allowAccessToExternalStorageManually',
      locale: localeName,
    );
  }

  String get openAppSettingsError {
    return Intl.message(
      "Error opening the app settings",
      name: 'openAppSettingsError',
      locale: localeName,
    );
  }

  String get actions {
    return Intl.message(
      "Actions",
      name: 'actions',
      locale: localeName,
    );
  }

  String get goToAlbum {
    return Intl.message(
      "Go to album",
      name: 'goToAlbum',
      locale: localeName,
    );
  }

  String get playNext {
    return Intl.message(
      "Play next",
      name: 'playNext',
      locale: localeName,
    );
  }

  String get addToQueue {
    return Intl.message(
      "Add to queue",
      name: 'addToQueue',
      locale: localeName,
    );
  }

  String get sort {
    return Intl.message(
      'Sort',
      name: 'sort',
      locale: localeName,
    );
  }

  String get artist {
    return Intl.message(
      'Artist',
      name: 'artist',
      locale: localeName,
    );
  }

  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      locale: localeName,
    );
  }

  String get dateModified {
    return Intl.message(
      'Date modified',
      name: 'dateModified',
      locale: localeName,
    );
  }

  String get dateAdded {
    return Intl.message(
      'Date added',
      name: 'dateAdded',
      locale: localeName,
    );
  }

  String get year {
    return Intl.message(
      'Year',
      name: 'year',
      locale: localeName,
    );
  }

  String get numberOfTracks {
    return Intl.message(
      'Number of tracks',
      name: 'numberOfTracks',
      locale: localeName,
    );
  }

  /// Picks a string of a [Content] in plural form.
  /// For example "tracks".
  String contents<T extends Content>([Type contentType]) {
    return contentPick<T, String Function()>(
      contentType: contentType,
      song: () => tracks,
      album: () => albums,
    )();
  }

  String sortFeature<T extends Content>(SortFeature<T> feature) {
    return contentPick<T, String Function()>(
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
    )();
  }

  //****************** Prompts ******************
  // Specific section for prompts localizations that are not concretely tied with some route
  /// The description is being splitted into rich text there.
  String get deletionPromptDescriptionP1 {
    return Intl.message(
      'Are you sure you want to delete ',
      name: 'deletionPromptDescriptionP1',
      locale: localeName,
    );
  }

  String get deletionPromptDescriptionP2 {
    return Intl.message(
      ' selected tracks?',
      name: 'deletionPromptDescriptionP2',
      locale: localeName,
    );
  }

  //****************** Dev route ******************
  String get devModeGreet {
    return Intl.message(
      'Done! You are now a developer',
      name: 'devModeGreet',
      locale: localeName,
    );
  }

  /// Shown when user tapped 4 times on app logo
  String get onThePathToDevMode {
    return Intl.message(
      'Something should happen now...',
      name: 'onThePathToDevMode',
      locale: localeName,
    );
  }

  /// Shown when user is about to become a developer, part 2
  String get onThePathToDevModeLastClick {
    return Intl.message(
      "only 1 click remaining...",
      name: 'onThePathToDevModeLastClick',
      locale: localeName,
    );
  }

  /// Shown when user is about to become a developer, part 2, plural
  String onThePathToDevModeClicksRemaining(int remainingClicks) {
    return Intl.message(
      "only $remainingClicks clicks remaining...",
      name: 'onThePathToDevModeClicksRemaining',
      args: [remainingClicks],
      locale: localeName,
    );
  }

  String get devStopService {
    return Intl.message(
      'Stop the service',
      name: 'devStopService',
      locale: localeName,
    );
  }

  String get devTestToast {
    return Intl.message(
      'Test toast',
      name: 'devTestToast',
      locale: localeName,
    );
  }

  String get devErrorSnackbar {
    return Intl.message(
      'Show error snackbar',
      name: 'devErrorSnackbar',
      locale: localeName,
    );
  }

  String get devImportantSnackbar {
    return Intl.message(
      'Show important snackbar',
      name: 'devImportantSnackbar',
      locale: localeName,
    );
  }

  String get devAnimationsSlowMo {
    return Intl.message(
      'Slow down animations',
      name: 'devAnimationsSlowMo',
      locale: localeName,
    );
  }

  String get quitDevMode {
    return Intl.message(
      'Quit the developer mode',
      name: 'quitDevMode',
      locale: localeName,
    );
  }

  String get quitDevModeDescription {
    return Intl.message(
      'Stop being a developer?',
      name: 'quitDevModeDescription',
      locale: localeName,
    );
  }

  //****************** Settings routes (extended is also included) ******************

  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      locale: localeName,
    );
  }

  String get general {
    return Intl.message(
      'General',
      name: 'general',
      locale: localeName,
    );
  }

  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      locale: localeName,
    );
  }

  String get settingLightMode {
    return Intl.message(
      'Light mode',
      name: 'settingLightMode',
      locale: localeName,
    );
  }

  //****************** Search route ******************

  String get searchHistory {
    return Intl.message(
      'Search history',
      name: 'searchHistory',
      locale: localeName,
    );
  }

  String get searchHistoryPlaceholder {
    return Intl.message(
      'Your search history will be displayed here',
      name: 'searchHistoryPlaceholder',
      locale: localeName,
    );
  }

  String get searchNothingFound {
    return Intl.message(
      'Nothing found',
      name: 'searchNothingFound',
      locale: localeName,
    );
  }

  /// The [entry] is the history entry to delete.
  /// The description is being splitted into rich text there.
  String get searchHistoryRemoveEntryDescriptionP1 {
    return Intl.message(
      'Are you sure you want to remove ',
      name: 'searchHistoryRemoveEntryDescriptionP1',
      locale: localeName,
    );
  }

  String get searchHistoryRemoveEntryDescriptionP2 {
    return Intl.message(
      ' from your search history?',
      name: 'searchHistoryRemoveEntryDescriptionP2',
      locale: localeName,
    );
  }

  String get searchClearHistory {
    return Intl.message(
      'Clear search history?',
      name: 'searchClearHistory',
      locale: localeName,
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
