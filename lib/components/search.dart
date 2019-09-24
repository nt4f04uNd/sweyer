import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/track_list.dart';
import 'package:app/constants/prefs.dart';
import 'package:app/player/player.dart';
import 'package:app/player/song.dart';
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

  /// Delete item from search history by its index
  Future<void> _deleteItemFromHistory(BuildContext context, int index) async {
    final prefs = await SharedPreferences.getInstance();
    var searchHistoryList =
        prefs.getStringList(PrefKeys.searchHistoryStringList);
    searchHistoryList.removeAt(index);
    prefs.setStringList(PrefKeys.searchHistoryStringList, searchHistoryList);
    _suggestions.removeAt(index); // Remove element from _suggestions list too
    showSuggestions(context); // Update suggestions ListView
  }

  /// Function to save user search input to shared preferences
  Future<void> _writeInputToSearchHistory(String input) async {
    input = input.trim(); // Remove any whitespaces
    if (input.isNotEmpty) {
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
  }

  Future<void> _resetSearchHistory(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(PrefKeys.searchHistoryStringList, []);
    _suggestions = [];
    showSuggestions(context); // Update suggestions ListView
  }

  Widget _buildResultsAndSuggestions(BuildContext context) {
    final Iterable<Song> searched = MusicPlayer.getInstance.playlistControl
        .searchSongs(query.trim() /* Remove any whitespaces*/);

    // Display suggestions
    if (searched == null) {
      return FutureBuilder<void>(
          future: _fetchSearchHistory(),
          builder: (context, snapshot) {
            // I could use snapshot from builder to display returned suggestions from `_fetchSearchHistory`, but if I would do, the search would blink on mount, so I user `_suggestions` array that is set in `_fetchSearchHistory`
            return Stack(
              children: <Widget>[
                Container(
                  child: _suggestions.length > 0
                      ? ListView.builder(
                          // TODO: exctract this to constnant
                          // key: PageStorageKey('SearchListView'),
                          itemCount: _suggestions.length +
                              1, // Plus 1 'cause we need to render list header
                          itemBuilder: (context, index) {
                            if (index == 0)
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 5.0, left: 13.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text("История поиска",
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Theme.of(context).hintColor,
                                        )),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline),
                                      color: Theme.of(context).hintColor,
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  title: Text(
                                                      "Очистить историю поиска"),
                                                  content: Text(
                                                      "Вы действительно хотите очистить историю?"),
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          top: 24.0,
                                                          left: 24.0,
                                                          right: 24.0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(10),
                                                    ),
                                                  ),
                                                  actions: <Widget>[
                                                    ButtonBar(
                                                      children: <Widget>[
                                                        FlatButton(
                                                          child:
                                                              Text('Удалить'),
                                                          textColor: Colors
                                                              .red.shade200,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  5),
                                                            ),
                                                          ),
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            await _resetSearchHistory(
                                                                context);
                                                          },
                                                        ),
                                                        FlatButton(
                                                          child: Text('Отмена'),
                                                          textColor:
                                                              Colors.white,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  5),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            // Minus 1 'cause we need to render list header
                            index -= 1;

                            return ListTile(
                              title: Text(_suggestions[index]),
                              leading: const Icon(Icons.history),
                              onLongPress: () {
                                // Show dialog to remove element from search hisory
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          title: Text("Удалить запрос"),
                                          content: Text(
                                              "Вы действительно хотите удалить этот запрос из истории?"),
                                          contentPadding: EdgeInsets.only(
                                              top: 24.0,
                                              left: 24.0,
                                              right: 24.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            ButtonBar(
                                              children: <Widget>[
                                                FlatButton(
                                                  child: Text('Удалить'),
                                                  textColor:
                                                      Colors.red.shade200,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    Navigator.of(context).pop();
                                                    await _deleteItemFromHistory(
                                                        context, index);
                                                  },
                                                ),
                                                FlatButton(
                                                  child: Text('Отмена'),
                                                  textColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                )
                                              ],
                                            ),
                                          ],
                                        ));
                              },
                              onTap: () {
                                // Do search onTap
                                query = _suggestions[index];
                                showResults(context);
                              },
                            );
                          },
                        )
                      : Center(
                          child: Text(
                              'Здесь будет отображаться история вашего поиска'),
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
    List<TrackTile> tiles = [];
    searched.toList().asMap().forEach((index, el) {
      tiles.add(TrackTile(
        index,
        song: el,
        additionalClickCallback: () {
          _writeInputToSearchHistory(query);
          MusicPlayer.getInstance.playlistControl
              .setPlaylist(searched.toList());
        },
      ));
    });

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
