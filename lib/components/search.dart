import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/buttons.dart';
import 'package:app/components/custom_icon_button.dart';
import 'package:app/components/show_functions.dart';
import 'package:app/components/track_list.dart';
import 'package:app/constants/themes.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/prefs.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:app/components/custom_search.dart' as custom_search;

class SongsSearchDelegate extends custom_search.SearchDelegate<Song> {
  SongsSearchDelegate();
  List<String> _suggestions = [];

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);

    return theme.copyWith(
      primaryColor: Theme.of(context).appBarTheme.color,
      primaryColorBrightness: Theme.of(context).appBarTheme.brightness,
      textTheme: TextTheme(
        title: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return CustomIconButton(
      splashColor: AppTheme.splash.auto(context),
      icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
      onPressed: () {
        close(context, null);
      },
    );
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

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      query.isEmpty
          ? SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CustomIconButton(
                splashColor: AppTheme.splash.auto(context),
                icon: const Icon(Icons.clear),
                color: Theme.of(context).iconTheme.color,
                onPressed: () {
                  query = '';
                  showSuggestions(context);
                },
              ),
            ),
    ];
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
    var prefs = await Prefs.sharedInstance;
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
      final prefs = await Prefs.sharedInstance;
      var searchHistoryList =
          await Prefs.byKey.searchHistoryStringList.getPref(prefs);
      if (searchHistoryList == null) {
        searchHistoryList = <String>[input];
      } else {
        if (!searchHistoryList.contains(input))
          searchHistoryList.insert(0, input);
        if (searchHistoryList.length > 6) {
          // Remove last element from history if length is greater than 5
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

  /// This method called both for build suggestions and results
  ///
  /// This because we need user to see actual suggestions only when query is empty
  ///
  /// And when query is not empty - found songs will be displayed
  Widget _buildResultsAndSuggestions(BuildContext context) {
    /// Search songs on every call
    final Iterable<Song> searched =
        PlaylistControl.searchSongs(query.trim() /* Remove any whitespaces*/);

    // Display suggestions on start screen
    if (searched == null) return _buildSuggestions();

    // Display when nothing has been found
    if (searched != null && searched.length == 0) return _buildEmptyResults();

    // Display results if something had been found
    final List<Song> searchedList = searched.toList();

    return Stack(
      children: <Widget>[
        Scrollbar(
          child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              // FIXME add gesture detector that closes keyboard on scroll
              padding: EdgeInsets.only(bottom: 65, top: 0),
              itemCount: searched.length,
              itemBuilder: (context, index) {
                return StreamBuilder(
                    stream: PlaylistControl.onSongChange,
                    builder: (context, snapshot) {
                      return TrackTile(
                        index,
                        key: UniqueKey(),
                        song: searchedList[index],
                        playing: searchedList[index].id ==
                            PlaylistControl.currentSong?.id,
                        additionalClickCallback: () {
                          _writeInputToSearchHistory(query);
                          FocusScope.of(context).requestFocus(FocusNode());
                          PlaylistControl.setSearchedPlaylist(
                              searched.toList());
                        },
                      );
                    });
              }),
        ),
        BottomTrackPanel(),
      ],
    );
  }

  /// Method that builds suggestions list
  Widget _buildSuggestions() {
    return FutureBuilder<void>(
        future: _fetchSearchHistory(),
        builder: (context, snapshot) {
          // I could use snapshot from builder to display returned suggestions from `_fetchSearchHistory`, but if I would do, the search would blink on mount, so I user `_suggestions` array that is set in `_fetchSearchHistory`
          return Stack(
            children: <Widget>[
              Container(
                child: _suggestions.length > 0
                    ? ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length +
                            1, // Plus 1 'cause we need to render list header
                        itemBuilder: (context, index) {
                          if (index == 0)
                            return _buildSuggestionsHeader(context);
                          // Minus 1 'cause we need to render list header
                          index -= 1;

                          return _buildSuggestionTile(context, index);
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                              'Здесь будет отображаться история вашего поиска'),
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
          Text("История поиска",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Theme.of(context).hintColor,
              )),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Padding(
              padding: const EdgeInsets.only(right: 3.0, top: 5.0),
              child: CustomIconButton(
                  splashColor: AppTheme.splash.auto(context),
                  icon: Icon(Icons.delete),
                  // size: 45.0,
                  color: Theme.of(context).hintColor,
                  onPressed: () {
                    ShowFunctions.showDialog(
                      context,
                      title: Text("Очистить историю поиска"),
                      content:
                          Text("Вы действительно хотите очистить историю?"),
                      acceptButton: DialogFlatButton(
                        child: Text('Удалить'),
                        textColor: AppTheme.redFlatButton.auto(context),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _resetSearchHistory(context);
                        },
                      ),
                      declineButton: DialogFlatButton(
                        child: Text('Отмена'),
                        textColor: AppTheme.declineButton.auto(context),
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
      title: Text(_suggestions[index]),
      leading: const Icon(Icons.history),
      onLongPress: () {
        ShowFunctions.showDialog(
          context,
          title: Text("Удалить запрос"),
          content:
              Text("Вы действительно хотите удалить этот запрос из истории?"),
          acceptButton: DialogFlatButton(
            child: Text('Удалить'),
            textColor: AppTheme.redFlatButton.auto(context),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItemFromHistory(context, index);
            },
          ),
          declineButton: DialogFlatButton(
            child: Text('Отмена'),
            textColor: AppTheme.declineButton.auto(context),
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
