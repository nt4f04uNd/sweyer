// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en_US locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

// @dart = 2.7

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en_US';

  static m0(count) => "${Intl.plural(count, zero: 'Albums', one: 'Album', two: 'Albums', few: 'Albums', many: 'Albums', other: 'Albums')}";

  static m1(count) => "${Intl.plural(count, zero: 'Artists', one: 'Artist', two: 'Artists', few: 'Artists', many: 'Artists', other: 'Artists')}";

  static m2(remainingClicks) => "only ${remainingClicks} clicks remaining...";

  static m3(count) => "${Intl.plural(count, zero: 'Playlists', one: 'Playlist', two: 'Playlists', few: 'Playlists', many: 'Playlists', other: 'Playlists')}";

  static m4(count) => "${Intl.plural(count, zero: 'Tracks', one: 'Track', two: 'Tracks', few: 'Tracks', many: 'Tracks', other: 'Tracks')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "actions" : MessageLookupByLibrary.simpleMessage("Actions"),
    "add" : MessageLookupByLibrary.simpleMessage("Add"),
    "addToFavorites" : MessageLookupByLibrary.simpleMessage("Add to favorites"),
    "addToPlaylist" : MessageLookupByLibrary.simpleMessage("Add to playlist"),
    "addToQueue" : MessageLookupByLibrary.simpleMessage("Add to queue"),
    "albumNotFound" : MessageLookupByLibrary.simpleMessage("Album not found"),
    "albums" : MessageLookupByLibrary.simpleMessage("Albums"),
    "albumsPlural" : m0,
    "allAlbums" : MessageLookupByLibrary.simpleMessage("All albums"),
    "allArtists" : MessageLookupByLibrary.simpleMessage("All artitst"),
    "allPlaylists" : MessageLookupByLibrary.simpleMessage("All playlists"),
    "allTracks" : MessageLookupByLibrary.simpleMessage("All tracks"),
    "allowAccessToExternalStorage" : MessageLookupByLibrary.simpleMessage("Please, allow access to storage"),
    "allowAccessToExternalStorageManually" : MessageLookupByLibrary.simpleMessage("Allow access to storage manually"),
    "almostThere" : MessageLookupByLibrary.simpleMessage("You\'re almost there"),
    "and" : MessageLookupByLibrary.simpleMessage("And"),
    "arbitraryQueue" : MessageLookupByLibrary.simpleMessage("Arbitrary queue"),
    "areYouSure" : MessageLookupByLibrary.simpleMessage("Are you sure?"),
    "areYouSureYouWantTo" : MessageLookupByLibrary.simpleMessage("Are you sure you want to"),
    "artistNotFound" : MessageLookupByLibrary.simpleMessage("Artist not found"),
    "artistUnknown" : MessageLookupByLibrary.simpleMessage("Unknown artist"),
    "artists" : MessageLookupByLibrary.simpleMessage("Artists"),
    "artistsPlural" : m1,
    "byQuery" : MessageLookupByLibrary.simpleMessage("By query"),
    "create" : MessageLookupByLibrary.simpleMessage("Create"),
    "dateAdded" : MessageLookupByLibrary.simpleMessage("Date added"),
    "dateModified" : MessageLookupByLibrary.simpleMessage("Date modified"),
    "debug" : MessageLookupByLibrary.simpleMessage("Debug"),
    "delete" : MessageLookupByLibrary.simpleMessage("Delete"),
    "deletion" : MessageLookupByLibrary.simpleMessage("Deletion"),
    "deletionError" : MessageLookupByLibrary.simpleMessage("Deletion error"),
    "details" : MessageLookupByLibrary.simpleMessage("Details"),
    "devAnimationsSlowMo" : MessageLookupByLibrary.simpleMessage("Slow down animations"),
    "devModeGreet" : MessageLookupByLibrary.simpleMessage("Done! You are now a developer"),
    "devTestToast" : MessageLookupByLibrary.simpleMessage("Test toast"),
    "done" : MessageLookupByLibrary.simpleMessage("Done"),
    "edit" : MessageLookupByLibrary.simpleMessage("Edit"),
    "editMetadata" : MessageLookupByLibrary.simpleMessage("Edit metadata"),
    "errorDetails" : MessageLookupByLibrary.simpleMessage("Error details"),
    "found" : MessageLookupByLibrary.simpleMessage("Found"),
    "general" : MessageLookupByLibrary.simpleMessage("General"),
    "goToAlbum" : MessageLookupByLibrary.simpleMessage("Go to album"),
    "goToArtist" : MessageLookupByLibrary.simpleMessage("Go to artist"),
    "grant" : MessageLookupByLibrary.simpleMessage("Grant"),
    "loopOff" : MessageLookupByLibrary.simpleMessage("Loop off"),
    "loopOn" : MessageLookupByLibrary.simpleMessage("Loop on"),
    "minutesShorthand" : MessageLookupByLibrary.simpleMessage("min"),
    "modified" : MessageLookupByLibrary.simpleMessage("Modified"),
    "more" : MessageLookupByLibrary.simpleMessage("More"),
    "name" : MessageLookupByLibrary.simpleMessage("Name"),
    "newPlaylist" : MessageLookupByLibrary.simpleMessage("New playlist"),
    "next" : MessageLookupByLibrary.simpleMessage("Next"),
    "noMusic" : MessageLookupByLibrary.simpleMessage("There\'s no music on your device"),
    "nothingHere" : MessageLookupByLibrary.simpleMessage("There\'s nothing here"),
    "numberOfAlbums" : MessageLookupByLibrary.simpleMessage("Number of albums"),
    "numberOfTracks" : MessageLookupByLibrary.simpleMessage("Number of tracks"),
    "onThePathToDevMode" : MessageLookupByLibrary.simpleMessage("Something should happen now..."),
    "onThePathToDevModeClicksRemaining" : m2,
    "onThePathToDevModeLastClick" : MessageLookupByLibrary.simpleMessage("only 1 click remaining..."),
    "oopsErrorOccurred" : MessageLookupByLibrary.simpleMessage("Oops! An error occurred"),
    "openAppSettingsError" : MessageLookupByLibrary.simpleMessage("Error opening the app settings"),
    "pause" : MessageLookupByLibrary.simpleMessage("Pause"),
    "play" : MessageLookupByLibrary.simpleMessage("Play"),
    "playContentList" : MessageLookupByLibrary.simpleMessage("Play"),
    "playNext" : MessageLookupByLibrary.simpleMessage("Play next"),
    "playRecent" : MessageLookupByLibrary.simpleMessage("Play recent"),
    "playback" : MessageLookupByLibrary.simpleMessage("Playback"),
    "playbackControls" : MessageLookupByLibrary.simpleMessage("Playback controls"),
    "playbackError" : MessageLookupByLibrary.simpleMessage("An error occurred during the playback"),
    "playlistDoesNotExistError" : MessageLookupByLibrary.simpleMessage("Can\'t find the playlist, perhaps it was deleted"),
    "playlists" : MessageLookupByLibrary.simpleMessage("Playlists"),
    "playlistsPlural" : m3,
    "pressOnceAgainToExit" : MessageLookupByLibrary.simpleMessage("Press once again to exit"),
    "previous" : MessageLookupByLibrary.simpleMessage("Previous"),
    "quitDevMode" : MessageLookupByLibrary.simpleMessage("Quit the developer mode"),
    "quitDevModeDescription" : MessageLookupByLibrary.simpleMessage("Stop being a developer?"),
    "refresh" : MessageLookupByLibrary.simpleMessage("Refresh"),
    "remove" : MessageLookupByLibrary.simpleMessage("Remove"),
    "removeFromQueue" : MessageLookupByLibrary.simpleMessage("Remove from queue"),
    "reset" : MessageLookupByLibrary.simpleMessage("Reset"),
    "save" : MessageLookupByLibrary.simpleMessage("Save"),
    "search" : MessageLookupByLibrary.simpleMessage("Search"),
    "searchClearHistory" : MessageLookupByLibrary.simpleMessage("Clear search history?"),
    "searchHistory" : MessageLookupByLibrary.simpleMessage("Search history"),
    "searchHistoryPlaceholder" : MessageLookupByLibrary.simpleMessage("Your search history will be displayed here"),
    "searchHistoryRemoveEntryDescriptionP1" : MessageLookupByLibrary.simpleMessage("Are you sure you want to remove "),
    "searchHistoryRemoveEntryDescriptionP2" : MessageLookupByLibrary.simpleMessage(" from your search history?"),
    "searchNothingFound" : MessageLookupByLibrary.simpleMessage("Nothing found"),
    "searchingForTracks" : MessageLookupByLibrary.simpleMessage("Searching for tracks..."),
    "secondsShorthand" : MessageLookupByLibrary.simpleMessage("s"),
    "selectAll" : MessageLookupByLibrary.simpleMessage("Select all"),
    "selected" : MessageLookupByLibrary.simpleMessage("Selected"),
    "selectedPlural" : MessageLookupByLibrary.simpleMessage("Selected"),
    "settingLightMode" : MessageLookupByLibrary.simpleMessage("Light mode"),
    "settings" : MessageLookupByLibrary.simpleMessage("Settings"),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "shuffleAll" : MessageLookupByLibrary.simpleMessage("Shuffle all"),
    "shuffleContentList" : MessageLookupByLibrary.simpleMessage("Shuffle"),
    "shuffled" : MessageLookupByLibrary.simpleMessage("Shuffled"),
    "songInformation" : MessageLookupByLibrary.simpleMessage("Track information"),
    "sort" : MessageLookupByLibrary.simpleMessage("Sort"),
    "stop" : MessageLookupByLibrary.simpleMessage("Stop"),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "title" : MessageLookupByLibrary.simpleMessage("Title"),
    "tracks" : MessageLookupByLibrary.simpleMessage("Tracks"),
    "tracksPlural" : m4,
    "upNext" : MessageLookupByLibrary.simpleMessage("Up next"),
    "year" : MessageLookupByLibrary.simpleMessage("Year")
  };
}
