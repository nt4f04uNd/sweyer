/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Chromium Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SearchDelegate;
import 'package:flutter/services.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

class _Notifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

abstract class SearchDelegate {
  /// Force rubuild the delegate body.
  ///
  /// Most of the time this is not needed, because all delegate is automatically rebuilt
  /// when [query] changes.
  void rebuildBody() {
    _bodyNotifier.notify();
  }
  _Notifier _bodyNotifier = _Notifier();

  /// Build the delegate body.
  Widget buildBody(BuildContext context);

  /// A widget to display before the current query in the [AppBar].
  Widget buildLeading(BuildContext context);

  /// Widgets to display after the search query in the [AppBar].
  List<Widget> buildActions(BuildContext context);

  /// Widget to display across the bottom of the [AppBar].
  PreferredSizeWidget buildBottom(BuildContext context) => null;

  /// The theme used to style the [AppBar].
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
  String get query => _queryTextController.text;

  set query(String value) {
    assert(query != null);
    _queryTextController.text = value;
  }

  /// Called whenever [query] changes.
  void onQueryChange() { } 

  /// Called when user submits the input.
  void onSubmit() { }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for [result] is used as the return value of the call
  /// to [showSearch] that launched the search initially.
  void close(BuildContext context, dynamic result) {
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
  bool get maintainState => false;

  // The focus node to use for manipulating focus on the search page. This is
  // managed, owned, and set by the SearchPageRoute using this delegate.
  FocusNode _focusNode;

  /// Will disable the keyboard will be opened with [_SearchBody.suggestions] for one time.
  /// When any animation is complete (even to [_SearchBody.results]), will become `false` again.
  bool disableAutoKeyboard = false;

  final TextEditingController _queryTextController = TextEditingController();

  final ProxyAnimation _proxyAnimation = ProxyAnimation(kAlwaysDismissedAnimation);

  _SearchPageRoute _route;
}

class SearchPage extends Page<void> {
  SearchPage({
    LocalKey key,
    @required this.delegate,
    this.transitionSettings,
    String name,
  }) : super(key: key, name: name);

  final SearchDelegate delegate;
  final RouteTransitionSettings transitionSettings;

  @override
  _SearchPageRoute createRoute(BuildContext context) {
    return _SearchPageRoute(page: this);
  }
}

class _SearchPageRoute extends RouteTransition<_SearchPage> {
  _SearchPageRoute({
    @required this.page,
  })  : assert(page != null),
        super(
          settings: page,
          transitionSettings: page.transitionSettings,
        ) {
    assert(
      delegate._route == null,
      'The ${delegate.runtimeType} instance is currently used by another active '
      'search. Please close that search by calling close() on the SearchDelegate '
      'before opening another search with the same delegate instance.',
    );
    delegate._route = this;
  }

  final SearchPage page;

  SearchDelegate get delegate => page.delegate;

  @override
  bool get maintainState => delegate.maintainState;
  

  GlobalKey<_SearchPageState> pageKey = GlobalKey();

  @override
  Widget buildContent(BuildContext context) {
    return _SearchPage(
      key: pageKey,
      delegate: delegate,
      animation: animation,
    );
  }

  @override
  Widget buildAnimation(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
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
  void didComplete(result) {
    super.didComplete(result);
    assert(delegate._route == this);
    delegate._route = null;
  }
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    Key key,
    this.delegate,
    this.animation,
  }) : super(key: key);

  final SearchDelegate delegate;
  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> with SingleTickerProviderStateMixin, PlayerRouteControllerMixin {
  // This node is owned, but not hosted by, the search page. Hosting is done by
  // the text field.
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.delegate._queryTextController.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
    focusNode.addListener(_onFocusChanged);
    widget.delegate._focusNode = focusNode;
    playerRouteController.addStatusListener(_handlePlayerRouteStatusChange);
  }

  @override
  void dispose() {
    widget.delegate._queryTextController.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    widget.delegate._focusNode = null;
    playerRouteController.removeStatusListener(_handlePlayerRouteStatusChange);
    focusNode.dispose();
    super.dispose();
  }

  void _handlePlayerRouteStatusChange(AnimationStatus status) {
    if (playerRouteController.opened) {
      setState(() {
        // Hide keyboard when player route is opened.
        focusNode.unfocus();
      });
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate.disableAutoKeyboard) {
      widget.delegate.disableAutoKeyboard = false;
    } else {
      focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(_SearchPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      oldWidget.delegate._queryTextController.removeListener(_onQueryChanged);
      widget.delegate._queryTextController.addListener(_onQueryChanged);
      oldWidget.delegate._focusNode = null;
      widget.delegate._focusNode = focusNode;
    }
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) {
      if (widget.delegate.disableAutoKeyboard) {
        widget.delegate.disableAutoKeyboard = false;
      } else {
        setState(() { });
      }
    }
  }

  void _onQueryChanged() {
    widget.delegate.onQueryChange();
    setState(() {
      // rebuild ourselves because query changed.
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
    final String searchFieldLabel = MaterialLocalizations.of(context).searchFieldLabel;
    final PreferredSizeWidget bottom = widget.delegate.buildBottom(context);
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
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kNFAppBarPreferredSize + bottom.preferredSize.height),
              child: AppBar(
                elevation: theme.appBarTheme.elevation,
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
                      onSubmitted: (String _) => widget.delegate.onSubmit(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: searchFieldLabel,
                        hintStyle: theme.inputDecorationTheme.hintStyle,
                      ),
                    ),
                  ),
                ),
                actions: widget.delegate.buildActions(context),
                bottom: bottom,
              ),
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: AnimatedBuilder(
                  animation: widget.delegate._bodyNotifier,
                  builder: (context, child) => widget.delegate.buildBody(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search results container.
/// Updated on each query change.
class _Results {
  Map<Type, List<Content>> _map = {
    Song: [],
    Album: [],
  };

  List<Song> get songs => _map[Song];
  List<Album> get albums => _map[Album];

  bool get empty => _map.values.every((element) => element.isEmpty);
  bool get notEmpty => _map.values.any((element) => element.isNotEmpty);

  void clear() {
    for (final value in _map.values) {
      value.clear();
    }
  }

  void search(query) {
    _map[Song] = ContentControl.search<Song>(query);
    _map[Album] = ContentControl.search<Album>(query);
  }
}

class AppSearchDelegate extends SearchDelegate {
  /// Content type to filter results by.
  ///
  /// When null results are displayed as list of sections, see [_ContentSection].
  ContentType get contentType => contentTypeNotifier.value;
  final ValueNotifier<ContentType> contentTypeNotifier = ValueNotifier(null);
  set contentType(ContentType value) {
    contentTypeNotifier.value = value;
    bodyScrolledNotifier.value = false;
    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: 0);
    }
  }

  _Results results = _Results();
  String _prevQuery = '';
  String _trimmedQuery = '';
  ScrollController scrollController;
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  void onQueryChange() {
    _trimmedQuery = query.trim();
    // Update results if previous query is distinct from current.
    if (_trimmedQuery.isEmpty) {
      results.clear();
      contentType = null;
      // Scroll is reset when content type changes
      bodyScrolledNotifier.value = false;
    } else if (_prevQuery != query) {
      bodyScrolledNotifier.value = false;
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      if (itemScrollController.isAttached) {
        itemScrollController.jumpTo(index: 0);
      }
      results.search(_trimmedQuery);
    }
    _prevQuery = _trimmedQuery;
  }

  @override
  void onSubmit() {
    SearchHistory.instance.save(query);
  }

  /// Handles tap to different content tiles.
  VoidCallback getContentTileTapHandler<T extends Content>([ContentType contentType]) {
    return contentPick<T, VoidCallback>(
      contentType: contentType,
      song: () {
        if (ContentControl.state.queues.type != QueueType.searched || query != ContentControl.state.queues.searchQuery) {
          onSubmit();
          ContentControl.setQueue(
            type: QueueType.searched,
            searchQuery: query,
            modified: false,
            shuffled: false,
            songs: results.songs,
          );
        }
      },
      album: onSubmit,
    );
  }

  // Maintain search state
  // That is needed we want to preserve state when user navigates to player route
  @override
  bool get maintainState => true;

  /// Used to check whether the body is scrolled.
  final ValueNotifier<bool> bodyScrolledNotifier = ValueNotifier<bool>(false);

  static AppSearchDelegate _of(BuildContext context) {
    return _DelegateProvider.of(context).delegate;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = ThemeControl.theme;
    assert(theme != null);

    return theme.copyWith(
      primaryColor: ThemeControl.theme.backgroundColor,
      primaryColorBrightness: ThemeControl.theme.appBarTheme.brightness,
      appBarTheme: ThemeControl.theme.appBarTheme.copyWith(elevation: 0.0),
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
              },
            ),
          ),
    ];
  }

  @override
  PreferredSizeWidget buildBottom(BuildContext context) {
    final contentTypeEntries = results._map.entries
      .where((el) => el.value.isNotEmpty)
      .toList();
    final showChips = results.notEmpty && contentTypeEntries.length > 1;
    return PreferredSize(
      preferredSize: Size.fromHeight(
        showChips
          ? AppBarBorder.height + 34.0 + 4.0
          : AppBarBorder.height,
      ),
      child: ValueListenableBuilder<ContentType>(
        valueListenable: contentTypeNotifier,
        builder: (context, contentTypeValue, child) {
          return !showChips
            ? child
            : Column(
              children: [
                SizedBox(
                  height: 34.0,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 8.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: contentTypeEntries.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                    itemBuilder: (context, index) => _ContentChip(delegate: this, contentType: ContentType(contentTypeEntries[index].key)),
                  ),
                ),
                const SizedBox(height: 4.0),
                child,
              ],
            );
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: bodyScrolledNotifier,
          builder: (context, scrolled, child) => AppBarBorder(shown: scrolled)
        ),
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    if (scrollController == null) {
      scrollController = ScrollController()..addListener(() { 
        bodyScrolledNotifier.value = scrollController.offset != scrollController.position.minScrollExtent;
      });
    }
    return _DelegateProvider(
      delegate: this,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        onVerticalDragStart: (_) => FocusScope.of(context).unfocus(),
        onVerticalDragCancel: () => FocusScope.of(context).unfocus(),
        onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
        onVerticalDragEnd: (_) => FocusScope.of(context).unfocus(),
        onVerticalDragUpdate: (_) => FocusScope.of(context).unfocus(),
        child: _DelegateBuilder()
      ),
    );
  }
}

class _DelegateProvider extends InheritedWidget {
  _DelegateProvider({
    Key key, 
    @required this.delegate,
    this.child,
  }) : super(key: key, child: child);

  final Widget child;
  final AppSearchDelegate delegate;

  static _DelegateProvider of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_DelegateProvider>().widget as _DelegateProvider;
  }

  @override
  bool updateShouldNotify(_DelegateProvider oldWidget) => false;
}

class _DelegateBuilder extends StatelessWidget {
  _DelegateBuilder({Key key}) : super(key: key);

  Future<bool> _handlePop(AppSearchDelegate delegate) async {
    if (delegate.contentType != null) {
      delegate.contentType = null;
      return true;
    }
    return false;
  }

  bool _handleNotification(AppSearchDelegate delegate, ScrollNotification notification) {
    delegate.bodyScrolledNotifier.value = notification.metrics.pixels != notification.metrics.minScrollExtent;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final delegate = AppSearchDelegate._of(context);
    final results = delegate.results;
    final l10n = getl10n(context);
    return ValueListenableBuilder<ContentType>(
      valueListenable: delegate.contentTypeNotifier,
      builder: (context, contentType, child) {
        if (delegate._trimmedQuery.isEmpty) {
          return _Suggestions();
        } else if (results.empty) {
          // Displays a message that there's nothing found
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
        } else {
          final contentTypeEntries = results._map.entries
            .where((el) => el.value.isNotEmpty)
            .toList();
          final single = contentTypeEntries.length == 1;
          final showSingleCategoryContentList = single || contentType != null;
          final contentListContentType = single ? ContentType(contentTypeEntries.single.key) : contentType;
          final controller = delegate.itemScrollController;
          return BackButtonListener(
            onPressed: () => _handlePop(delegate),
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 300),
              reverse: !single && contentType == null,
              transitionBuilder: (child, animation, secondaryAnimation) => SharedAxisTransition(
                  transitionType: SharedAxisTransitionType.vertical,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Colors.transparent,
                  child: child,
                ),
              child: Container(
                key: ValueKey("$single${contentType?.value}"),
                child: showSingleCategoryContentList
                    ? NotificationListener<ScrollNotification>(
                        onNotification: (notification) => _handleNotification(delegate, notification),
                        child: ContentListView(
                          // ItemScrollController can only be attached to one ScrollablePositionedList, see https://github.com/google/flutter.widgets/issues/219
                          itemScrollController: controller.isAttached ? null : controller,
                          contentType: contentListContentType,
                          onItemTap: delegate.getContentTileTapHandler(contentListContentType),
                          list: single ? contentTypeEntries.single.value : contentPick<Content, List<Content>>(
                            contentType: contentType,
                            song: delegate.results.songs,
                            album: delegate.results.albums,
                          ),
                        ),
                      )
                    : ListView(
                      controller: delegate.scrollController,
                      children: [
                        if (results.songs.isNotEmpty)
                          _ContentSection<Song>(
                            items: results.songs,
                            onTap: () => delegate.contentType = ContentType.song,
                          ),
                        if (results.albums.isNotEmpty)
                          _ContentSection<Album>(
                            items: results.albums,
                            onTap: () => delegate.contentType = ContentType.album,
                          ),
                      ],
                    ),
                ),
              ),
            );
        }
      }
    );
  }
}


class _ContentChip extends StatefulWidget {
  const _ContentChip({
    Key key,
    @required this.delegate,
    @required this.contentType,
  }) : super(key: key);

  final AppSearchDelegate delegate;
  final ContentType contentType;

  static const borderRadius = const BorderRadius.all(Radius.circular(50.0));

  @override
  _ContentChipState createState() => _ContentChipState();
}

class _ContentChipState extends State<_ContentChip> with SingleTickerProviderStateMixin {
  AnimationController controller;
  
  bool get active => widget.delegate.contentType == widget.contentType;

  @override
  void initState() { 
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (active) {
      controller.forward();
    }
  }

  @override
  void dispose() { 
    controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (active) {
      widget.delegate.contentType = null;
    } else {
      widget.delegate.contentType = widget.contentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final colorAnimation = ColorTween(
      begin: ThemeControl.theme.colorScheme.secondary,
      end: ThemeControl.theme.colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    if (active) {
      controller.forward();
    } else {
      controller.reverse();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Material(
        color: colorAnimation.value,
        borderRadius: _ContentChip.borderRadius,
        child: child,
      ),
      child: NFInkWell(
        borderRadius: _ContentChip.borderRadius,
        onTap: _handleTap,
        child: IgnorePointer(
          child: Theme(
            data: ThemeControl.theme.copyWith(canvasColor: Colors.transparent),
            child: RawChip(
              shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0)),
              backgroundColor: Colors.transparent,
              label: Text(
                l10n.contents(widget.contentType),
                style: TextStyle(
                  color: ThemeControl.theme.colorScheme.onBackground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The search results are split into a few sections - songs, albums, etc.
/// 
/// This widget renders a tappable header for such sections, and the sections
/// content.
class _ContentSection<T extends Content> extends StatelessWidget {
  const _ContentSection({
    Key key,
    @required this.items,
    @required this.onTap,
  }) : super(key: key);

  final List<T> items;
  final VoidCallback onTap;

  String getHeaderText(BuildContext context) {
    final l10n = getl10n(context);
    return contentPick<T, String>(
      song: l10n.tracks,
      album: l10n.albums,
    );
  }

  @override
  Widget build(BuildContext context) {
    final delegate = AppSearchDelegate._of(context);
    final builder = contentPick<T, Widget Function(int)>(
      song: (index) {
        final song = items[index] as Song;
        return SongTile(
          song: song,
          horizontalPadding: 12.0,
          // TODO: move to some place that contains all default tests + whatver else related
          current: song.sourceId == ContentControl.state.currentSong.sourceId,
          onTap: delegate.getContentTileTapHandler<Song>(),
        );
      },
      album: (index) {
        final album = items[index] as Album;
        return AlbumTile(
          album: items[index] as Album,
          small: true,
          horizontalPadding: 12.0,
          // TODO: move to some place that contains all default tests + whatver else related
          current: album == ContentControl.state.currentSongOrigin ||
                   album == ContentControl.state.queues.persistent,
          onTap: delegate.getContentTileTapHandler<Album>(),
        );
      },
    );
    return Column(
      children: [
        NFInkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  getHeaderText(context),
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ), 
          ),
        ),
        Column(
          children: [
            for (int index = 0; index < math.min(6, items.length); index ++)
              builder(index),
          ],
        )
      ],
    );
  }
}

class _Suggestions extends StatefulWidget {
  const _Suggestions({Key key}) : super(key: key);

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<_Suggestions> {
  Future<void> _loadFuture;

  @override
  void initState() { 
    super.initState();
    _loadFuture = SearchHistory.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (SearchHistory.instance.history == null) {
          return Center(
            child: Spinner(),
          );
        }
        return Container(
          width: double.infinity,
          child: SearchHistory.instance.history.length == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 160.0,
                      left: 50.0,
                      right: 50.0,
                    ),
                    child: Text(
                      l10n.searchHistoryPlaceholder,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ThemeControl.theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              : ScrollConfiguration(
                  behavior: const GlowlessScrollBehavior(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    itemCount: SearchHistory.instance.history.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _SuggestionsHeader();
                      }
                      index--;
                      return _SuggestionTile(index: index);
                    },
                  ),
                )
        );
      },
    );
  }
}


class _SuggestionsHeader extends StatelessWidget {
  const _SuggestionsHeader({Key key}) : super(key: key);

  void clearHistory(BuildContext context) {
    SearchHistory.instance.clear();
    AppSearchDelegate._of(context).rebuildBody();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return ListHeader(
      margin: const EdgeInsets.fromLTRB(16.0, 3.0, 7.0, 0.0),
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
              acceptButton: NFButton.accept(
                text: l10n.delete,
                splashColor: Constants.AppTheme.dialogButtonSplash.auto,
                textStyle: const TextStyle(color: Constants.AppColors.red),
                onPressed: () => clearHistory(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    Key key,
    @required this.index,
  }) : super(key: key);

  final int index;

  /// Deletes item from search history by its index.
  void _removeEntry(BuildContext context, int index) async {
    SearchHistory.instance.remove(index);
    AppSearchDelegate._of(context).rebuildBody();
  }

  void _handleTap(context) {
    final delegate = AppSearchDelegate._of(context);
    delegate.query = SearchHistory.instance.history[index];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return NFListTile(
      onTap: () => _handleTap(context),
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
          acceptButton: NFButton.accept(
            text: l10n.remove,
            splashColor: Constants.AppTheme.dialogButtonSplash.auto,
            textStyle: const TextStyle(color: Constants.AppColors.red),
            onPressed: () => _removeEntry(context, index)
          ),
        );
      },
    );
  }
}
