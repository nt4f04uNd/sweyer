/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Chromium Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

/// Shows a full screen search page and returns the search result selected by
/// the user when the page is closed.
///
/// The search page consists of an app bar with a search field and a body which
/// can either show suggested search queries or the search results.
///
/// The appearance of the search page is determined by the provided
/// [delegate]. The initial query string is given by [query], which defaults
/// to the empty string. When [query] is set to null, [delegate.query] will
/// be used as the initial query.
///
/// This method returns the selected search result, which can be set in the
/// [SearchDelegate.close] call. If the search page is closed with the system
/// back button, it returns null.
///
/// A given [SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
///
/// The transition to the search page triggered by this method looks best if the
/// screen triggering the transition contains an [AppBar] at the top and the
/// transition is called from an [IconButton] that's part of [AppBar.actions].
/// The animation provided by [SearchDelegate.transitionAnimation] can be used
/// to trigger additional animations in the underlying page while the search
/// page fades in or out. This is commonly used to animate an [AnimatedIcon] in
/// the [AppBar.leading] position e.g. from the hamburger menu to the back arrow
/// used to exit the search page.
///
/// See also:
///
///  * [SearchDelegate] to define the content of the search page.
Future<void> showCustomSearch({
  @required BuildContext context,
  @required SearchDelegate delegate,
  String query = '',
  bool openKeyboard = true,
}) {
  assert(delegate != null);
  assert(context != null);
  delegate.query = query ?? delegate.query;
  delegate._currentBody = _SearchBody.suggestions;
  delegate._disableAutoKeyboard = !openKeyboard;
  // Pass delegate through route options
  return Navigator.of(context).pushNamed(
    Constants.HomeRoutes.search.value,
    arguments: SearchPageRoute(delegate: delegate),
  );
}

/// Delegate for [showSearch] to define the content of the search page.
///
/// The search page always shows an [AppBar] at the top where users can
/// enter their search queries. The buttons shown before and after the search
/// query text field can be customized via [SearchDelegate.leading] and
/// [SearchDelegate.actions].
///
/// The body below the [AppBar] can either show suggested queries (returned by
/// [SearchDelegate.buildSuggestions]) or - once the user submits a search  - the
/// results of the search as returned by [SearchDelegate.buildResults].
///
/// [SearchDelegate.query] always contains the current query entered by the user
/// and should be used to build the suggestions and results.
///
/// The results can be brought on screen by calling [SearchDelegate.showResults]
/// and you can go back to showing the suggestions by calling
/// [SearchDelegate.showSuggestions].
///
/// Once the user has selected a search result, [SearchDelegate.close] should be
/// called to remove the search page from the top of the navigation stack and
/// to notify the caller of [showSearch] about the selected search result.
///
/// A given [SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
abstract class SearchDelegate {
  /// Suggestions shown in the body of the search page while the user types a
  /// query into the search field.
  ///
  /// The delegate method is called whenever the content of [query] changes.
  /// The suggestions should be based on the current [query] string. If the query
  /// string is empty, it is good practice to show suggested queries based on
  /// past queries or the current context.
  ///
  /// Usually, this method will return a [ListView] with one [ListTile] per
  /// suggestion. When [ListTile.onTap] is called, [query] should be updated
  /// with the corresponding suggestion and the results page should be shown
  /// by calling [showResults].
  Widget buildSuggestions(BuildContext context);

  /// The results shown after the user submits a search from the search page.
  ///
  /// The current value of [query] can be used to determine what the user
  /// searched for.
  ///
  /// This method might be applied more than once to the same query.
  /// If your [buildResults] method is computationally expensive, you may want
  /// to cache the search results for one or more queries.
  ///
  /// Typically, this method returns a [ListView] with the search results.
  /// When the user taps on a particular search result, [close] should be called
  /// with the selected result as argument. This will close the search page and
  /// communicate the result back to the initial caller of [showSearch].
  Widget buildResults(BuildContext context);

  /// A widget to display before the current query in the [AppBar].
  ///
  /// Typically an [IconButton] configured with a [BackButtonIcon] that exits
  /// the search with [close]. One can also use an [AnimatedIcon] driven by
  /// [transitionAnimation], which animates from e.g. a hamburger menu to the
  /// back button as the search overlay fades in.
  ///
  /// Returns null if no widget should be shown.
  ///
  /// See also:
  ///
  ///  * [AppBar.leading], the intended use for the return value of this method.
  Widget buildLeading(BuildContext context);

  /// Widgets to display after the search query in the [AppBar].
  ///
  /// If the [query] is not empty, this should typically contain a button to
  /// clear the query and show the suggestions again (via [showSuggestions]) if
  /// the results are currently shown.
  ///
  /// Returns null if no widget should be shown
  ///
  /// See also:
  ///
  ///  * [AppBar.actions], the intended use for the return value of this method.
  List<Widget> buildActions(BuildContext context);

  /// The theme used to style the [AppBar].
  ///
  /// By default, a white theme is used.
  ///
  /// See also:
  ///
  ///  * [AppBar.backgroundColor], which is set to [ThemeData.primaryColor].
  ///  * [AppBar.iconTheme], which is set to [ThemeData.primaryIconTheme].
  ///  * [AppBar.textTheme], which is set to [ThemeData.primaryTextTheme].
  ///  * [AppBar.brightness], which is set to [ThemeData.primaryColorBrightness].
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = ThemeControl.theme;
    assert(theme != null);
    return theme.copyWith(
      primaryColor: Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
      primaryColorBrightness: Brightness.light,
      primaryTextTheme: theme.textTheme,
      backgroundColor: theme.backgroundColor,
    );
  }

  /// The current query string shown in the [AppBar].
  ///
  /// The user manipulates this string via the keyboard.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] this
  /// string should be updated to that suggestion via the setter.
  String get query => _queryTextController.text;

  set query(String value) {
    assert(query != null);
    _queryTextController.text = value;
  }

  /// Transition from the suggestions returned by [buildSuggestions] to the
  /// [query] results returned by [buildResults].
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] the
  /// screen should typically transition to the page showing the search
  /// results for the suggested query. This transition can be triggered
  /// by calling this method.
  ///
  /// See also:
  ///
  ///  * [showSuggestions] to show the search suggestions again.
  void showResults(BuildContext context) {
    _focusNode?.unfocus();
    _currentBody = _SearchBody.results;
  }

  /// Transition from showing the results returned by [buildResults] to showing
  /// the suggestions returned by [buildSuggestions].
  ///
  /// Calling this method will also put the input focus back into the search
  /// field of the [AppBar].
  ///
  /// If the results are currently shown this method can be used to go back
  /// to showing the search suggestions.
  ///
  /// See also:
  ///
  ///  * [showResults] to show the search results.
  void showSuggestions(BuildContext context) {
    assert(_focusNode != null,
        '_focusNode must be set by route before showSuggestions is called.');
    _focusNode.requestFocus();
    _currentBody = _SearchBody.suggestions;
  }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for [result] is used as the return value of the call
  /// to [showSearch] that launched the search initially.
  void close(BuildContext context, dynamic result) {
    _currentBody = null;
    _focusNode?.unfocus();
    Navigator.of(context)
      ..popUntil((Route<dynamic> route) => route == _route)
      ..pop(result);
  }

  /// [Animation] triggered when the search pages fades in or out.
  ///
  /// This animation is commonly used to animate [AnimatedIcon]s of
  /// [IconButton]s returned by [buildLeading] or [buildActions]. It can also be
  /// used to animate [IconButton]s contained within the route below the search
  /// page.
  Animation<double> get transitionAnimation => _proxyAnimation;

  /// Override this property to change route property [maintainState]
  ///
  /// Copied from route docs:
  ///
  /// Whether the route should remain in memory when it is inactive.
  /// If this is true, then the route is maintained, so that any futures it is holding from the next route will properly resolve when the next route pops.
  /// If this is not necessary this can be set to false to allow the framework to entirely discard the route's widget hierarchy when it is not visible.
  /// The value of this getter should not change during the lifetime of the object. It is used by [createOverlayEntries], which is called by [install] near the beginning of the route lifecycle.
  bool get maintainState => false;

  /// Getter to test whether delegate should update, similar to React.
  ///
  /// Affects only results.
  // bool get shouldUpdateResults => true;

  // The focus node to use for manipulating focus on the search page. This is
  // managed, owned, and set by the SearchPageRoute using this delegate.
  FocusNode _focusNode;

  /// Will disable the keyboard will be opened with [_SearchBody.suggestions] for one time.
  /// When any animation is complete (even to [_SearchBody.results]), will become `false` again.
  bool _disableAutoKeyboard = false;

  final TextEditingController _queryTextController = TextEditingController();

  final ProxyAnimation _proxyAnimation =
      ProxyAnimation(kAlwaysDismissedAnimation);

  final ValueNotifier<_SearchBody> _currentBodyNotifier =
      ValueNotifier<_SearchBody>(null);

  _SearchBody get _currentBody => _currentBodyNotifier.value;

  set _currentBody(_SearchBody value) {
    _currentBodyNotifier.value = value;
  }

  SearchPageRoute _route;
}

/// Describes the body that is currently shown under the [AppBar] in the
/// search page.
enum _SearchBody {
  /// Suggested queries are shown in the body.
  ///
  /// The suggested queries are generated by [SearchDelegate.buildSuggestions].
  suggestions,

  /// Search results are currently shown in the body.
  ///
  /// The search results are generated by [SearchDelegate.buildResults].
  results,
}

class SearchPageRoute extends RouteTransition<_SearchPage> {
  SearchPageRoute({
    @required this.delegate,

    /// Here it is allowed to omit `super` call with `@required` [route] parameter because we the method [buildPage] is overridden
  })  : assert(delegate != null),
        super(
          route: null,
          transitionSettings: RouteTransitionSettings(
            checkSystemUi: () => Constants.UiTheme.grey.auto,
          ),
        ) {
    assert(
      delegate._route == null,
      'The ${delegate.runtimeType} instance is currently used by another active '
      'search. Please close that search by calling close() on the SearchDelegate '
      'before opening another search with the same delegate instance.',
    );
    delegate._route = this;
  }

  final SearchDelegate delegate;

  @override
  RouteSettings get settings =>
      RouteSettings(name: Constants.HomeRoutes.search.value);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => delegate.maintainState;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: NFDefaultAnimation(parent: animation),
      child: child,
    );
  }

  @override
  Animation<double> createAnimation() {
    final Animation<double> animation = super.createAnimation();
    delegate._proxyAnimation.parent = animation;
    return animation;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    handleChecks(animation, secondaryAnimation);
    return _SearchPage(
      delegate: delegate,
      animation: animation,
    );
  }

  @override
  void didComplete(result) {
    super.didComplete(result);
    assert(delegate._route == this);
    delegate._route = null;
    delegate._currentBody = null;
  }
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    this.delegate,
    this.animation,
  });

  final SearchDelegate delegate;
  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>>
    with SingleTickerProviderStateMixin, PlayerRouteControllerMixin {
  // This node is owned, but not hosted by, the search page. Hosting is done by
  // the text field.
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.delegate._queryTextController.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
    focusNode.addListener(_onFocusChanged);
    widget.delegate._focusNode = focusNode;
    playerRouteController.addStatusListener(_handlePlayerRouteStatusChange);
  }

  @override
  void dispose() {
    widget.delegate._queryTextController.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.removeListener(_onSearchBodyChanged);
    widget.delegate._focusNode = null;
    playerRouteController.removeStatusListener(_handlePlayerRouteStatusChange);
    focusNode.dispose();
    // Don't dispose [_playerRouteController] because this will cause multiple dispose error.
    // Apparently it is disposed somewhere in the tree below, as I pass it down the inherited state.
    super.dispose();
  }

  void _handlePlayerRouteStatusChange(AnimationStatus status) {
    if (playerRouteController.opened) {
      setState(() {
        // Hide keyboard when player route is opened.
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate._currentBody == _SearchBody.suggestions &&
        !widget.delegate._disableAutoKeyboard) {
      focusNode.requestFocus();
    }
    if (!widget.delegate._disableAutoKeyboard) {
      widget.delegate._disableAutoKeyboard = false;
    }
  }

  @override
  void didUpdateWidget(_SearchPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      oldWidget.delegate._queryTextController.removeListener(_onQueryChanged);
      widget.delegate._queryTextController.addListener(_onQueryChanged);
      oldWidget.delegate._currentBodyNotifier
          .removeListener(_onSearchBodyChanged);
      widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
      oldWidget.delegate._focusNode = null;
      widget.delegate._focusNode = focusNode;
    }
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus &&
        widget.delegate._currentBody != _SearchBody.suggestions) {
      widget.delegate.showSuggestions(context);
    }
  }

  void _onQueryChanged() {
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  void _onSearchBodyChanged() {
    setState(() {
      // rebuild ourselves because search body changed.
    });
  }

  Future<bool> _handlePop(context) async {
    if (playerRouteController.opened) {
      playerRouteController.close();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = widget.delegate.appBarTheme(context);
    final String searchFieldLabel =
        MaterialLocalizations.of(context).searchFieldLabel;
    Widget body;
    switch (widget.delegate._currentBody) {
      case _SearchBody.suggestions:
        // I removed KeyedSubtrees because results and suggestions are the same in my app.
        body = widget.delegate.buildSuggestions(context);
        // KeyedSubtree(
        //   key: const ValueKey<_SearchBody>(_SearchBody.suggestions),
        //   child:
        // );
        break;
      case _SearchBody.results:
        body = widget.delegate.buildResults(context);
        // KeyedSubtree(
        //   key: const ValueKey<_SearchBody>(_SearchBody.results),
        //   child:
        // );
        break;
    }
    String routeName;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        routeName = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        routeName = searchFieldLabel;
    }

    return Builder(
      builder: (context) => WillPopScope(
        onWillPop: () => _handlePop(context),
        child: Semantics(
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          label: routeName,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: kNFAppBarPreferredSize + 4.0,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: body,
                    ),
                  ),
                ),
                Positioned(
                  top: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: PreferredSize(
                    preferredSize: Size.fromHeight(kNFAppBarPreferredSize),
                    child: AppBar(
                      elevation: 2.0,
                      backgroundColor: theme.primaryColor,
                      iconTheme: theme.primaryIconTheme,
                      textTheme: theme.primaryTextTheme,
                      brightness: theme.primaryColorBrightness,
                      leading: widget.delegate.buildLeading(context),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 0.0, right: 8.0),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: Colors.red,
                            canvasColor: Colors.red,
                          ),
                          child: TextField(
                            selectionControls: NFTextSelectionControls(),
                            controller: widget.delegate._queryTextController,
                            focusNode: focusNode,
                            style: theme.textTheme.headline6,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (String _) {
                              widget.delegate.showResults(context);
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: searchFieldLabel,
                              hintStyle: theme.inputDecorationTheme.hintStyle,
                            ),
                          ),
                        ),
                      ),
                      actions: widget.delegate.buildActions(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SongsSearchDelegate extends SearchDelegate {
  SongsSearchDelegate() {
    fetchingFuture = SearchHistory.instance.load();
  }

  /// Needed to check if queue has to be updated
  bool dirty = true;
  List<Song> searched = [];
  String prevQuery = '';
  Future<void> fetchingFuture;

  // Maintain search state
  // That is needed we want to preserve state when user navigates to player route
  @override
  bool get maintainState => true;

  @override
  void close(BuildContext context, dynamic result) {
    super.close(context, result);
    dirty = true;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = ThemeControl.theme;
    assert(theme != null);

    return theme.copyWith(
      primaryColor: ThemeControl.theme.appBarTheme.color,
      primaryColorBrightness: ThemeControl.theme.appBarTheme.brightness,
      textTheme: TextTheme(
        headline6: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return NFBackButton(
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      query.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: NFIconButton(
                icon: const Icon(Icons.clear_rounded),
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
    SearchHistory.instance.save(query);
    return _buildResultsAndSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsAndSuggestions(context);
  }

  /// Delete item from search history by its index
  Future<void> _removeEntry(BuildContext context, int index) async {
    SearchHistory.instance.remove(index);
    showSuggestions(context);
  }

  Future<void> _clearSearchHistory(BuildContext context) async {
    SearchHistory.instance.clear();
    showSuggestions(context); // Update suggestions ListView
  }

  ItemScrollController _itemScrollController = ItemScrollController();

  /// This method called both for build suggestions and results
  ///
  /// This because we need user to see actual suggestions only when query is empty
  ///
  /// And when query is not empty - found songs will be displayed
  Widget _buildResultsAndSuggestions(BuildContext context) {
    final trimmedQuery = query.trim();

    /// Search songs if previous query is distinct from current
    if (prevQuery == '' || prevQuery != query) {
      searched = ContentControl.searchSongs(trimmedQuery)?.toList();
      dirty = true;
    }
    prevQuery = query.trim();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onVerticalDragStart: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragCancel: () => FocusScope.of(context).unfocus(),
      onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragEnd: (_) => FocusScope.of(context).unfocus(),
      onVerticalDragUpdate: (_) => FocusScope.of(context).unfocus(),
      child: (() {
        if (trimmedQuery == '') {
          // Display suggestions on start screen
          return _buildSuggestions();
        } else if (searched.length == 0) {
          // Display when nothing has been found
          return _buildEmptyResults(context);
        }
        final songs = searched;
        final itemCount = searched.length + 1;
        final l10n = getl10n(context);
        return StreamBuilder(
          stream: ContentControl.state.onSongChange,
          builder: (context, snapshot) {
            return JumpingDraggableScrollbar.songs(
              itemCount: itemCount,
              itemScrollController: _itemScrollController,
              labelBuilder: (context, progress, barPadHeight, jumpIndex) {
                return NFScrollLabel(
                  text: songs[
                          (jumpIndex - 1).clamp(0.0, songs.length - 1).round()]
                      .title[0]
                      .toUpperCase(),
                );
              },
              child: SingleTouchRecognizerWidget(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemCount: itemCount,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListHeader(
                        leading: Text(
                          l10n.found + ' ' + songs.length.toString(),
                        ),
                      );
                    }
                    return SongTile(
                      song: songs[index - 1],
                      current: songs[index - 1].sourceId ==
                          ContentControl.state.currentSong.sourceId,
                      onTap: () async {
                        if (dirty ||
                            ContentControl.state.queues.type !=
                                QueueType.searched) {
                          SearchHistory.instance.save(query);
                          ContentControl.setQueue(
                            type: QueueType.searched,
                            searchQuery: query,
                            modified: false,
                            shuffled: false,
                            songs: songs,
                          );
                          dirty = false;
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      })(),
    );
  }

  /// Method that builds suggestions list
  Widget _buildSuggestions() {
    return FutureBuilder<void>(
        future: fetchingFuture,
        // use pre-obtained future, see https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
        builder: (context, snapshot) {
          final l10n = getl10n(context);

          /// I could use snapshot from builder to display returned suggestions from [_fetchSearchHistory], but if I would do, the search would blink on mount, so I user [_suggestions] array that is set in [_fetchSearchHistory]
          return Container(
            width: double.infinity,
            child: SearchHistory.instance.history.length > 0
                ? ScrollConfiguration(
                    behavior: const NFScrollBehaviorGlowless(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      itemCount: SearchHistory.instance.history.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildSuggestionsHeader(context);
                        }
                        index--;
                        return _buildSuggestionTile(context, index);
                      },
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 3 - 50.0,
                      left: 50.0,
                      right: 50.0,
                    ),
                    child: Text(
                      l10n.searchHistoryPlaceholder,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ThemeControl.theme.colorScheme.onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
          );
        });
  }

  /// Builds screen with message that nothing had been found
  Widget _buildEmptyResults(BuildContext context) {
    final l10n = getl10n(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Icon(Icons.error_outline_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: Text(
              l10n.searchNothingFound,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsHeader(BuildContext context) {
    final l10n = getl10n(context);
    return ListHeader(
      margin: const EdgeInsets.only(
        top: 3.0,
        bottom: 0.0,
        left: 16.0,
        right: 7.0,
      ),
      leading: Text(l10n.searchHistory),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: NFIconButton(
          icon: Icon(Icons.delete_sweep_rounded),
          color: ThemeControl.theme.hintColor,
          onPressed: () {
            ShowFunctions.instance.showDialog(
              context,
              ui: Constants.UiTheme.modalOverGrey.auto,
              title: Text(l10n.searchClearHistory),
              buttonSplashColor: Constants.AppTheme.dialogButtonSplash.auto,
              acceptButton: NFButton(
                text: l10n.delete,
                splashColor: Constants.AppTheme.dialogButtonSplash.auto,
                textStyle: const TextStyle(color: Constants.AppColors.red),
                onPressed: () async {
                  await _clearSearchHistory(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, int index) {
    final l10n = getl10n(context);
    return NFListTile(
      title: Text(
        SearchHistory.instance.history[index],
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      dense: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 2.0),
        child: Icon(
          Icons.history_rounded,
          color: ThemeControl.theme.iconTheme.color,
        ),
      ),
      onLongPress: () {
        ShowFunctions.instance.showDialog(
          context,
          ui: Constants.UiTheme.modalOverGrey.auto,
          title: Text(l10n.searchHistory),
          titlePadding: defaultAlertTitlePadding.copyWith(bottom: 4.0),
          contentPadding: defaultAlertContentPadding.copyWith(bottom: 6.0),
          content: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 15.0),
              children: [
                TextSpan(text: l10n.searchHistoryRemoveEntryDescriptionP1),
                TextSpan(
                  text: '"${SearchHistory.instance.history[index]}"',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: l10n.searchHistoryRemoveEntryDescriptionP2),
              ],
            ),
          ),
          buttonSplashColor: Constants.AppTheme.dialogButtonSplash.auto,
          acceptButton: NFButton(
            text: l10n.remove,
            splashColor: Constants.AppTheme.dialogButtonSplash.auto,
            textStyle: const TextStyle(color: Constants.AppColors.red),
            onPressed: () {
              _removeEntry(context, index);
            },
          ),
        );
      },
      onTap: () {
        // Do search onTap
        query = SearchHistory.instance.history[index];
        showResults(context);
      },
    );
  }
}
