/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/components/custom/custom.dart' as custom_search;

class SongsSearchDelegate extends custom_search.SearchDelegate<Song> {
  SongsSearchDelegate() {
    _fetchingHistory = _fetchSearchHistory();
  }
  List<String> _suggestions = [];
  Iterable<Song> searched = [];

  String _prevQuery = "";
  Future<void> _fetchingHistory;

  // Maintain search state
  // That is needed we want to preserve state when user navigates to player route
  @override
  // bool get maintainState => true;

  @override
  bool get shouldUpdateResults => false;

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);

    return theme.copyWith(
      primaryColor: Theme.of(context).appBarTheme.color,
      primaryColorBrightness: Theme.of(context).appBarTheme.brightness,
      textTheme: TextTheme(
        title: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          // color: Constants.AppTheme.mainContrast.auto(context),
        ),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return SMMIconButton(
      splashColor: Constants.AppTheme.splash.auto(context),
      icon: Icon(
        Icons.arrow_back,
        color: Constants.AppTheme.mainContrast.auto(context),
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      query.isEmpty
          ? SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SMMIconButton(
                splashColor: Constants.AppTheme.splash.auto(context),
                icon: const Icon(Icons.clear),
                // color: Theme.of(context).iconTheme.color,
                color: Constants.AppTheme.mainContrast.auto(context),
                onPressed: () {
                  query = '';
                  showSuggestions(context);
                },
              ),
            ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    // Save search query to history when click submit button
    _writeInputToSearchHistory(query);
    return _buildResultsAndSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsAndSuggestions(context);
  }

  /// Function to fetch user search from shared preferences
  Future<void> _fetchSearchHistory() async {
    var searchHistoryList = await Prefs.byKey.searchHistoryStringList.getPref();
    if (searchHistoryList == null)
      _suggestions = [];
    else
      _suggestions = searchHistoryList;
  }

  /// Delete item from search history by its index
  Future<void> _deleteItemFromHistory(BuildContext context, int index) async {
    var prefs = await Prefs.getSharedInstance();
    var searchHistoryList =
        await Prefs.byKey.searchHistoryStringList.getPref(prefs);
    searchHistoryList.removeAt(index);
    await Prefs.byKey.searchHistoryStringList.setPref(searchHistoryList, prefs);
    _suggestions.removeAt(index); // Remove element from _suggestions list too
    showSuggestions(context); // Update suggestions ListView
  }

  /// Function to save user search input to shared preferences
  Future<void> _writeInputToSearchHistory(String input) async {
    input = input.trim(); // Remove any whitespaces
    if (input.isNotEmpty) {
      final prefs = await Prefs.getSharedInstance();
      var searchHistoryList =
          await Prefs.byKey.searchHistoryStringList.getPref(prefs);
      if (searchHistoryList == null) {
        searchHistoryList = <String>[input];
      } else {
        if (!searchHistoryList.contains(input))
          searchHistoryList.insert(0, input);
        if (searchHistoryList.length > Constants.Config.SEARCH_HISTORY_LENGTH) {
          // Remove last element from history if length is greater than constants constraint
          searchHistoryList.removeLast();
        }
      }

      await Prefs.byKey.searchHistoryStringList
          .setPref(searchHistoryList, prefs);
    }
  }

  Future<void> _resetSearchHistory(BuildContext context) async {
    await Prefs.byKey.searchHistoryStringList.setPref([]);
    _suggestions = [];
    showSuggestions(context); // Update suggestions ListView
  }

final key = UniqueKey();

  /// This method called both for build suggestions and results
  ///
  /// This because we need user to see actual suggestions only when query is empty
  ///
  /// And when query is not empty - found songs will be displayed
  Widget _buildResultsAndSuggestions(BuildContext context) {
    /// Search songs if previous query is distinct from current
    if (_prevQuery == '' || _prevQuery != query)
      searched =
          PlaylistControl.searchSongs(query.trim() /* Remove any whitespaces*/);

    _prevQuery = query.trim();

    return GestureDetector(
      key:key,
      onTap: () => FocusScope.of(context).unfocus(),
      onVerticalDragStart: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragCancel: () => FocusScope.of(context).unfocus(),
      onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragEnd: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragUpdate: (_) => FocusScope.of(context).unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(

          /// Show theme on some widget, to system ui could be consistent
          value: Constants.AppSystemUIThemes.mainScreen.auto(context),
          child: (() {
            // return
            // Display suggestions on start screen
            if (searched == null) return _buildSuggestions();

            // Display when nothing has been found
            if (searched != null && searched.length == 0)
              return _buildEmptyResults();

            // Display results if something had been found
            final List<Song> searchedList = searched.toList();

            return Stack(
              children: <Widget>[
                Scrollbar(
                  child: StreamBuilder(
                      stream: MusicPlayer.onDurationChanged,
                      builder: (context, snapshot) {
                        return ListView.builder(
                            physics: const SMMBouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 65, top: 0),
                            itemCount: searched.length,
                            itemBuilder: (context, index) {
                              return SongTile(
                                song: searchedList[index],
                                playing: searchedList[index].id ==
                                    PlaylistControl.currentSong?.id,
                                additionalClickCallback: () async {
                                  _writeInputToSearchHistory(query);
                                  // close(context, searchedList[index]);
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());

                                  // Wait before route animation completes
                                  await Future.delayed(
                                      Duration(milliseconds: 400));

                                  // TODO: maybe save last search query and update only if it has changed?
                                  // NOTE that it might cause bugs if playlist will accidentally update (e.g. fetch process will end)
                                  // So I maybe need to think about this a lil bit
                                  PlaylistControl.setSearchedPlaylist(
                                    searched.toList(),
                                  );
                                },
                              );
                            });
                      }),
                ),
                BottomTrackPanel(),
              ],
            );
          })()),
    );
  }

  /// Method that builds suggestions list
  Widget _buildSuggestions() {
    return FutureBuilder<void>(
        future:
            _fetchingHistory, // use pre-obtained future, see https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
        builder: (context, snapshot) {
          // I could use snapshot from builder to display returned suggestions from `_fetchSearchHistory`, but if I would do, the search would blink on mount, so I user `_suggestions` array that is set in `_fetchSearchHistory`
          return Stack(
            children: <Widget>[
              Container(
                child: _suggestions.length > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildSuggestionsHeader(context),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: SMMScrollBehaviorGlowless(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.only(bottom: 65, top: 0),
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) =>
                                    _buildSuggestionTile(context, index),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height / 3 - 50.0,
                          left: 50.0,
                          right: 50.0,
                        ),
                        child: Text(
                          'Здесь будет отображаться история вашего поиска',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Constants.AppTheme.mainContrast
                                .auto(context)
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
              ),
              BottomTrackPanel(),
            ],
          );
        });
  }

  /// Builds screen with message that nothing had been found
  Widget _buildEmptyResults() {
    return Stack(
      children: <Widget>[
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Icon(Icons.error_outline),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Text(
                  'Ничего не найдено',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        BottomTrackPanel(),
      ],
    );
  }

  Widget _buildSuggestionsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, left: 13.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "История поиска",
            style: TextStyle(
              // fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Theme.of(context).hintColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Padding(
              padding: const EdgeInsets.only(right: 3.0, top: 5.0),
              child: SMMIconButton(
                  splashColor: Constants.AppTheme.splash.auto(context),
                  icon: Icon(Icons.delete_sweep),
                  color: Theme.of(context).hintColor,
                  onPressed: () {
                    ShowFunctions.showDialog(
                      context,
                      title: Text("Очистить историю поиска"),
                      content:
                          Text("Вы действительно хотите очистить историю?"),
                      acceptButton: DialogFlatButton(
                        child: Text('Удалить'),
                        textColor:
                            Constants.AppTheme.acceptButton.auto(context),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _resetSearchHistory(context);
                        },
                      ),
                      declineButton: DialogFlatButton(
                        child: Text('Отмена'),
                        textColor:
                            Constants.AppTheme.declineButton.auto(context),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, int index) {
    return ListTile(
      title: Text(_suggestions[index], style: TextStyle(fontSize: 15.5)),
      dense: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 2.0),
        child: Icon(Icons.history,
            color: Constants.AppTheme.mainContrast.auto(context)),
      ),
      onLongPress: () {
        ShowFunctions.showDialog(
          context,
          title: Text("Удалить запрос"),
          content:
              Text("Вы действительно хотите удалить этот запрос из истории?"),
          acceptButton: DialogFlatButton(
            child: Text('Удалить'),
            textColor: Constants.AppTheme.acceptButton.auto(context),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItemFromHistory(context, index);
            },
          ),
          declineButton: DialogFlatButton(
            child: Text('Отмена'),
            textColor: Constants.AppTheme.declineButton.auto(context),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
      onTap: () {
        // Do search onTap
        query = _suggestions[index];
        showResults(context);
      },
    );
  }
}
