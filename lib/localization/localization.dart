/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:flutter/material.dart';
import 'package:multiple_localization/multiple_localization.dart';
import 'package:devicelocale/devicelocale.dart';
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
    final preferredLocales = await Devicelocale.preferredLanguagesAsLocales;
    await load(preferredLocales[0]);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final systemLocale = await findSystemLocale();
    Intl.systemLocale = systemLocale;
    return MultipleLocalizations.load(
      initializeMessages,
      locale,
      (locale) => AppLocalizations.instance,
      setDefaultLocale: Intl.systemLocale != Intl.defaultLocale,
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
    );
  }

  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
    );
  }

  String get stop {
    return Intl.message(
      'Stop',
      name: 'stop',
    );
  }

  String get next {
    return Intl.message(
      'Next',
      name: 'next',
    );
  }

  String get previous {
    return Intl.message(
      'Previous',
      name: 'previous',
    );
  }

  String get loopOff {
    return Intl.message(
      'Loop off',
      name: 'loopOff',
    );
  }

  String get loopOn {
    return Intl.message(
      'Loop on',
      name: 'loopOn',
    );
  }
  //*------------------------------------

  /// Label for unknown artist.
  String get artistUnknown {
    return Intl.message(
      'Unknown artist',
      name: 'artistUnknown',
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
    );
  }

  String get albums {
    return Intl.message(
      'Albums',
      name: 'albums',
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
    );
  }

  String get allTracks {
    return Intl.message(
      "All tracks",
      name: 'allTracks',
    );
  }

  String get playlist {
    return Intl.message(
      "Playlist",
      name: 'playlist',
    );
  }

  String get arbitraryQueue {
    return Intl.message(
      'Arbitrary queue',
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

  String get debug {
    return Intl.message(
      'Debug',
      name: 'debug',
    );
  }

  String get areYouSure {
    return Intl.message(
      'Are you sure?',
      name: 'areYouSure',
    );
  }

  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
    );
  }

  String get save {
    return Intl.message(
      'Save',
      name: 'save',
    );
  }

  // todo: currently unused
  String get secondsShorthand {
    return Intl.message(
      's',
      name: 'secondsShorthand',
    );
  }

  // todo: currently unused
  String get minutesShorthand {
    return Intl.message(
      'min',
      name: 'minutesShorthand',
    );
  }

  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
    );
  }

  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
    );
  }

  String get deletion {
    return Intl.message(
      'Deletion',
      name: 'deletion',
    );
  }

  String get deletionError {
    return Intl.message(
      'Deletion error',
      name: 'deletionError',
    );
  }

  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
    );
  }

  String get refresh {
    return Intl.message(
      'Refresh',
      name: 'refresh',
    );
  }

  String get grant {
    return Intl.message(
      'Grant',
      name: 'grant',
    );
  }

  String get errorMessage {
    return Intl.message(
      'Oops! An error occurred',
      name: 'errorMessage',
    );
  }

  String get errorDetails {
    return Intl.message(
      'Error details',
      name: 'errorDetails',
    );
  }

  String get playbackErrorMessage {
    return Intl.message(
      'An error occurred during the playback, removing the track',
      name: 'playbackErrorMessage',
    );
  }

  String get details {
    return Intl.message(
      'Details',
      name: 'details',
    );
  }

  String get songInformation {
    return Intl.message(
      'Track information',
      name: 'songInformation',
    );
  }

  String get editMetadata {
    return Intl.message(
      'Edit metadata',
      name: 'editMetadata',
    );
  }

  String get unknownRoute {
    return Intl.message(
      'Unknown route!',
      name: 'unknownRoute',
    );
  }

  String get found {
    return Intl.message(
      'Found',
      name: 'found',
    );
  }

  String get upNext {
    return Intl.message(
      'Up next',
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

  String get openAppSettingsError {
    return Intl.message(
      "Error opening the app settings",
      name: 'openAppSettingsError',
    );
  }

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

  String get playNext {
    return Intl.message(
      "Play next",
      name: 'playNext',
    );
  }

  String get addToQueue {
    return Intl.message(
      "Add to queue",
      name: 'addToQueue',
    );
  }

  String get sort {
    return Intl.message(
      'Sort',
      name: 'sort',
    );
  }

  String get artist {
    return Intl.message(
      'Artist',
      name: 'artist',
    );
  }

  String get title {
    return Intl.message(
      'Title',
      name: 'title',
    );
  }

  String get dateModified {
    return Intl.message(
      'Date modified',
      name: 'dateModified',
    );
  }

  String get dateAdded {
    return Intl.message(
      'Date added',
      name: 'dateAdded',
    );
  }

  String get year {
    return Intl.message(
      'Year',
      name: 'year',
    );
  }

  String get numberOfTracks {
    return Intl.message(
      'Number of tracks',
      name: 'numberOfTracks',
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
    );
  }

  String get deletionPromptDescriptionP2 {
    return Intl.message(
      ' selected tracks?',
      name: 'deletionPromptDescriptionP2',
    );
  }

  //****************** Dev route ******************
  String get devModeGreet {
    return Intl.message(
      'Done! You are now a developer',
      name: 'devModeGreet',
    );
  }

  /// Shown when user tapped 4 times on app logo
  String get onThePathToDevMode {
    return Intl.message(
      'Something should happen now...',
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

  String get devStopService {
    return Intl.message(
      'Stop the service',
      name: 'devStopService',
    );
  }

  String get devTestToast {
    return Intl.message(
      'Test toast',
      name: 'devTestToast',
    );
  }

  String get devErrorSnackbar {
    return Intl.message(
      'Show error snackbar',
      name: 'devErrorSnackbar',
    );
  }

  String get devImportantSnackbar {
    return Intl.message(
      'Show important snackbar',
      name: 'devImportantSnackbar',
    );
  }

  String get devAnimationsSlowMo {
    return Intl.message(
      'Slow down animations',
      name: 'devAnimationsSlowMo',
    );
  }

  String get quitDevMode {
    return Intl.message(
      'Quit the developer mode',
      name: 'quitDevMode',
    );
  }

  String get quitDevModeDescription {
    return Intl.message(
      'Stop being a developer?',
      name: 'quitDevModeDescription',
    );
  }

  //****************** Settings routes (extended is also included) ******************

  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
    );
  }

  String get general {
    return Intl.message(
      'General',
      name: 'general',
    );
  }

  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
    );
  }

  String get settingLightMode {
    return Intl.message(
      'Light mode',
      name: 'settingLightMode',
    );
  }

  //****************** Search route ******************

  String get searchHistory {
    return Intl.message(
      'Search history',
      name: 'searchHistory',
    );
  }

  String get searchHistoryPlaceholder {
    return Intl.message(
      'Your search history will be displayed here',
      name: 'searchHistoryPlaceholder',
    );
  }

  String get searchNothingFound {
    return Intl.message(
      'Nothing found',
      name: 'searchNothingFound',
    );
  }

  /// The [entry] is the history entry to delete.
  /// The description is being splitted into rich text there.
  String get searchHistoryRemoveEntryDescriptionP1 {
    return Intl.message(
      'Are you sure you want to remove ',
      name: 'searchHistoryRemoveEntryDescriptionP1',
    );
  }

  String get searchHistoryRemoveEntryDescriptionP2 {
    return Intl.message(
      ' from your search history?',
      name: 'searchHistoryRemoveEntryDescriptionP2',
    );
  }

  String get searchClearHistory {
    return Intl.message(
      'Clear search history?',
      name: 'searchClearHistory',
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
