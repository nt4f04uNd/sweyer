import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/track_list.dart';
import 'package:app/constants/prefs.dart';
import 'package:app/musicPlayer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongsSearchDelegate extends SearchDelegate<Song> {
  List<String> _suggestions = [];

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(primaryColor: Color(0xff070707));
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  /// Function to fetch user search from shared preferences
  Future<void> _fetchSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    var searchHistoryList =
        prefs.getStringList(PrefKeys.searchHistoryStringList);
    if (searchHistoryList == null)
      _suggestions = [];
    else
      _suggestions = searchHistoryList;
  }

  /// Function to save user search input to shared preferences
  void _writeInputToSearchHistory(String input) async {
    final prefs = await SharedPreferences.getInstance();
    var searchHistoryList =
        prefs.getStringList(PrefKeys.searchHistoryStringList);
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
    prefs.setStringList(PrefKeys.searchHistoryStringList, searchHistoryList);
  }

  Widget _buildResultsAndSuggestions(BuildContext context) {
    final Iterable<Song> searched = MusicPlayer.getInstance.searchSongs(query);

    // Display suggestions
    if (searched == null) {
      return FutureBuilder<void>(
          future: _fetchSearchHistory(),
          builder: (context, snapshot) {
            // I could use snapshot from builder to display returned suggestions from `_fetchSearchHistory`, but if I would do, the search would blink on mount, so I user `_suggestions` array that is set in `_fetchSearchHistory`
            return Stack(
              children: <Widget>[
                Container(
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        leading: const Icon(Icons.history),
                        onTap: () {
                          // Do search onTap
                          query = _suggestions[index];
                          showResults(context);
                        },
                      );
                    },
                  ),
                ),
                BottomTrackPanel(),
              ],
            );
          });
    }

    // Display when nothing has been found
    if (searched != null && searched.length == 0) {
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

    // Display tiles
    List<TrackTile> tiles = searched.map((el) {
      return TrackTile(
        MusicPlayer.getInstance.getSongIndexById(el.id),
        additionalClickCallback: () {
          MusicPlayer.getInstance.setPlaylist(searched.toList());
        },
      );
    }).toList();

    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 55.0),
          child: ListView(
              padding: EdgeInsets.only(bottom: 10, top: 5), children: tiles),
        ),
        BottomTrackPanel(),
      ],
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
          : IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
            ),
    ];
  }
}
