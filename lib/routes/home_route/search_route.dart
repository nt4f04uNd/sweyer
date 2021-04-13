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
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

class _Notifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class SearchDelegate {
  /// Whether to automatically open the keyboard when page is opened.
  bool autoKeyboard = false;

  final _Notifier _setStateNotifier = _Notifier();
  /// Updates the search route.
  void setState() {
    _setStateNotifier.notify();
  }

  /// The current query string shown in the [AppBar].
  String get query => _queryTextController.text;
  final TextEditingController _queryTextController = TextEditingController();
  set query(String value) {
    assert(query != null);
    _queryTextController.text = value;
  }
}


/// Search results container.
class _Results {
  Map<Type, List<Content>> map = {
    Song: [],
    Album: [],
  };

  List<Song> get songs => map[Song];
  List<Album> get albums => map[Album];

  bool get empty => map.values.every((element) => element.isEmpty);
  bool get notEmpty => map.values.any((element) => element.isNotEmpty);

  void clear() {
    for (final value in map.values) {
      value.clear();
    }
  }

  void search(query) {
    map[Song] = ContentControl.search<Song>(query);
    map[Album] = ContentControl.search<Album>(query);
  }
}

class _SearchStateDelegate {
  _SearchStateDelegate({
    @required TickerProvider vsync,
    @required this.searchDelegate,
  }) : scrollController = ScrollController(),
    singleListScrollController = ScrollController(),
    selectionController = ContentSelectionController<SelectionEntry>(
      animationController: AnimationController(
        vsync: vsync,
        duration: kSelectionDuration,
      ),
      actionsBuilder: (context) {
        final controller = ContentSelectionController.of(context);
        return SelectionActionsBar(
          controller: controller,
          left: const [ActionsSelectionTitle(closeButton: true)],
          right: const [
            GoToAlbumSelectionAction(),
            PlayNextSelectionAction(),
            AddToQueueSelectionAction(),
          ],
        );
      }
    ) {
    scrollController.addListener(() {
      bodyScrolledNotifier.value =
        scrollController.offset != scrollController.position.minScrollExtent;
    });
    singleListScrollController.addListener(() {
      bodyScrolledNotifier.value =
        singleListScrollController.offset != singleListScrollController.position.minScrollExtent;
    });
    selectionController.addListener(setState);
  }

  final ScrollController scrollController;
  final ScrollController singleListScrollController;
  final ContentSelectionController selectionController;
  final SearchDelegate searchDelegate;
  /// Used to check whether the body is scrolled.
  final ValueNotifier<bool> bodyScrolledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Type> contentTypeNotifier = ValueNotifier(null);
  _Results results = _Results();
  String prevQuery = '';
  String trimmedQuery = '';

  void dispose() {
    scrollController.dispose();
    singleListScrollController.dispose();
    bodyScrolledNotifier.dispose();
    contentTypeNotifier.dispose();
    selectionController.dispose();
  }

  static _SearchStateDelegate _of(BuildContext context) {
    return _DelegateProvider.of(context).delegate;
  }

  /// SearchDelegate callbacks.
  String get query => searchDelegate.query;
  void setState() {
    searchDelegate.setState();
  }

  /// Content type to filter results by.
  ///
  /// When null results are displayed as list of sections, see [_ContentSection].
  Type get contentType => contentTypeNotifier.value;
  set contentType(Type value) {
    contentTypeNotifier.value = value;
    bodyScrolledNotifier.value = false;
  }

  void onSubmit() {
    SearchHistory.instance.save(query);
  }

  void onQueryChange() {
    trimmedQuery = query.trim();
    // Update results if previous query is distinct from current.
    if (trimmedQuery.isEmpty) {
      _onClear();
    } else if (prevQuery != query) {
      _onInput();
    }
    prevQuery = trimmedQuery;
  }
  
  void _onClear() {
    results.clear();
    contentType = null;
    // Scroll is reset when content type changes
    bodyScrolledNotifier.value = false;
  }

  void _onInput() {
    bodyScrolledNotifier.value = false;
    if (scrollController?.hasClients ?? false) {
      scrollController.jumpTo(0);
    }
    if (singleListScrollController?.hasClients ?? false) {
      singleListScrollController.jumpTo(0);
    }
    results.search(trimmedQuery);
  }

  /// Handles tap to different content tiles.
  VoidCallback getContentTileTapHandler<T extends Content>([Type contentType]) {
    return contentPick<T, VoidCallback>(
      contentType: contentType,
      song: () {
        if (ContentControl.state.queues.type != QueueType.searched || query != ContentControl.state.queues.searchQuery) {
          onSubmit();
          ContentControl.setSearchedQueue(query, results.songs);
        }
      },
      album: onSubmit,
    );
  }
}

class SearchPage extends Page<void> {
  const SearchPage({
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
  }) : super(
         settings: page,
         transitionSettings: page.transitionSettings,
       );

  final SearchPage page;

  @override
  bool get maintainState => true;

  @override
  Widget buildContent(BuildContext context) {
    return _SearchPage(
      route: this,
      animation: animation,
      delegate: page.delegate,
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
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    Key key,
    this.route,
    this.animation,
    this.delegate,
  }) : super(key: key);

  final PageRoute route;
  final Animation animation;
  final SearchDelegate delegate;

  @override
  State<StatefulWidget> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> with TickerProviderStateMixin {
  // This node is owned, but not hosted by, the search page. Hosting is done by
  // the text field.
  FocusNode focusNode = FocusNode();
  _SearchStateDelegate stateDelegate;

  @override
  void initState() {
    super.initState();
    stateDelegate = _SearchStateDelegate(
      vsync: this,
      searchDelegate: widget.delegate,
    );
    widget.delegate._setStateNotifier.addListener(_handleSetState);
    widget.delegate._queryTextController.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
    focusNode.addListener(_onFocusChanged);
    playerRouteController.addStatusListener(_handlePlayerRouteStatusChange);
  }

  @override
  void dispose() {
    focusNode.dispose();
    stateDelegate.dispose();
    widget.delegate._setStateNotifier.removeListener(_handleSetState);
    widget.delegate._queryTextController.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    playerRouteController.removeStatusListener(_handlePlayerRouteStatusChange);
    super.dispose();
  }

  void _handleSetState() {
    setState(() {
      /// React to [SearchDelegate.setState]
    });
  }

  void _handlePlayerRouteStatusChange(AnimationStatus status) {
    if (playerRouteController.opened) {
      setState(() {
        // Unfocus keyboard when player route is opened.
        focusNode.unfocus();
      });
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate.autoKeyboard) {
      focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(_SearchPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      oldWidget.delegate._queryTextController.removeListener(_onQueryChanged);
      widget.delegate._queryTextController.addListener(_onQueryChanged);
    }
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) {
      if (widget.delegate.autoKeyboard) {
        setState(() { });
      }
    }
  }

  void _onQueryChanged() {
    stateDelegate.onQueryChange();
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for [result] is used as the return value.
  void close(BuildContext context, dynamic result) {
    focusNode?.unfocus();
    Navigator.of(context)
      ..popUntil((Route<dynamic> route) => route == widget.route)
      ..pop(result);
  }

  void _handlePushNext() {
    // Unfocus when other route opened above the search.
    focusNode.unfocus();
  }

  ThemeData buildAppBarTheme() {
    final ThemeData theme = ThemeControl.theme;
    return theme.copyWith(
      primaryColor: theme.backgroundColor,
      primaryColorBrightness: theme.appBarTheme.brightness,
      appBarTheme: theme.appBarTheme.copyWith(elevation: 0.0),
      textTheme: const TextTheme(
        headline6: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildLeading() {
    return NFBackButton(
      onPressed: () {
        final selectionController = stateDelegate.selectionController;
        if (selectionController.inSelection) {
          selectionController.close();
        }
        close(context, null);
      },
    );
  }

  List<Widget> buildActions() {
    return <Widget>[
      if (widget.delegate.query.isEmpty)
        const SizedBox.shrink()
      else
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: NFIconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              widget.delegate.query = '';
            },
          ),
        ),
    ];
  }

  PreferredSizeWidget buildBottom() {
    const bottomPadding = 12.0;
    final contentTypeEntries = stateDelegate.results.map.entries
      .where((el) => el.value.isNotEmpty)
      .toList();
    final showChips = stateDelegate.results.notEmpty && contentTypeEntries.length > 1;
    return PreferredSize(
      preferredSize: Size.fromHeight(
        showChips
          ? AppBarBorder.height + 34.0 + bottomPadding
          : AppBarBorder.height,
      ),
      child: ValueListenableBuilder<Type>(
        valueListenable: stateDelegate.contentTypeNotifier,
        builder: (context, contentTypeValue, child) {
          return !showChips
            ? child
            : Column(
              children: [
                SizedBox(
                  height: 34.0,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 12.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: contentTypeEntries.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                    itemBuilder: (context, index) => _ContentChip(
                      delegate: stateDelegate,
                      contentType: contentTypeEntries[index].key,
                    ),
                  ),
                ),
                const SizedBox(height: bottomPadding),
                child,
              ],
            );
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: stateDelegate.bodyScrolledNotifier,
          builder: (context, scrolled, child) => AppBarBorder(shown: scrolled)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final theme = buildAppBarTheme();
    final bottom = buildBottom();
    final String searchFieldLabel = MaterialLocalizations.of(context).searchFieldLabel;
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
    return RouteAwareWidget(
      onPushNext: _handlePushNext,
      child: Builder(
        builder: (context) => Semantics(
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          label: routeName,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kNFAppBarPreferredSize + bottom.preferredSize.height),
              child: SelectionAppBar(
                selectionController: stateDelegate.selectionController,
                onMenuPressed: null,
                titleSelection: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: SelectionCounter(controller: stateDelegate.selectionController),
                ),
                actionsSelection: [
                  DeleteSongsAppBarAction<Content>(
                    controller: stateDelegate.selectionController,
                  )
                ],
                elevationSelection: 0.0,
                elevation: theme.appBarTheme.elevation,
                backgroundColor: theme.primaryColor,
                iconTheme: theme.primaryIconTheme,
                textTheme: theme.primaryTextTheme,
                brightness: theme.primaryColorBrightness,
                leading: buildLeading(),
                actions: buildActions(),
                bottom: bottom,
                title: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextField(
                    selectionControls: NFTextSelectionControls(),
                    controller: widget.delegate._queryTextController,
                    focusNode: focusNode,
                    style: theme.textTheme.headline6,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (String _) => stateDelegate.onSubmit(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: searchFieldLabel,
                      hintStyle: theme.inputDecorationTheme.hintStyle,
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: _DelegateProvider(
                delegate: stateDelegate,
                child: GestureDetector(
                  onTap: () => focusNode.unfocus(),
                  onVerticalDragDown: (_) => focusNode.unfocus(),
                  child: _DelegateBuilder(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DelegateProvider extends InheritedWidget {
  const _DelegateProvider({
    Key key, 
    @required this.delegate,
    Widget child,
  }) : super(key: key, child: child);

  final _SearchStateDelegate delegate;

  static _DelegateProvider of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_DelegateProvider>().widget as _DelegateProvider;
  }

  @override
  bool updateShouldNotify(_DelegateProvider oldWidget) => false;
}

class _DelegateBuilder extends StatelessWidget {
  _DelegateBuilder({Key key}) : super(key: key);

  Future<bool> _handlePop(_SearchStateDelegate delegate) async {
    if (delegate.contentType != null) {
      delegate.contentType = null;
      return true;
    }
    return false;
  }

  bool _handleNotification(_SearchStateDelegate delegate, ScrollNotification notification) {
    delegate.bodyScrolledNotifier.value = notification.metrics.pixels != notification.metrics.minScrollExtent;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final delegate = _SearchStateDelegate._of(context);
    final results = delegate.results;
    final l10n = getl10n(context);
    return ValueListenableBuilder<Type>(
      valueListenable: delegate.contentTypeNotifier,
      builder: (context, contentType, child) {
        if (delegate.trimmedQuery.isEmpty) {
          return _Suggestions();
        } else if (results.empty) {
          // Displays a message that there's nothing found
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
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
          final contentTypeEntries = results.map.entries
            .where((el) => el.value.isNotEmpty)
            .toList();
          final single = contentTypeEntries.length == 1;
          final showSingleCategoryContentList = single || contentType != null;
          final contentListContentType = single ? contentTypeEntries.single.key : contentType;
          return NFBackButtonListener(
            onBackButtonPressed: () => _handlePop(delegate),
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
                key: ValueKey(contentType),
                child: showSingleCategoryContentList
                    ? NotificationListener<ScrollNotification>(
                        onNotification: (notification) => _handleNotification(delegate, notification),
                        child: ContentListView(
                          contentType: contentListContentType,
                          controller: delegate.singleListScrollController,
                          selectionController: delegate.selectionController,
                          onItemTap: delegate.getContentTileTapHandler(contentListContentType),
                          list: single ? contentTypeEntries.single.value : contentPick<Content, List<Content>>(
                            contentType: contentType,
                            song: delegate.results.songs,
                            album: delegate.results.albums,
                          ),
                        ),
                      )
                    : 
                    // AppScrollbar( // TODO: enable this when i have more content on search screen
                    //     controller: delegate.scrollController,
                    //     child: 
                        ListView(
                          controller: delegate.scrollController,
                          children: [
                            for (final entry in contentTypeEntries)
                              if (entry.value.isNotEmpty)
                                _ContentSection(
                                  contentType: entry.key,
                                  items: results.map[entry.key],
                                  onTap: () => delegate.contentType = entry.key,
                                ),
                          ],
                        ),
                ),
              ),
            );
        }
      },
    );
  }
}


class _ContentChip extends StatefulWidget {
  const _ContentChip({
    Key key,
    @required this.delegate,
    @required this.contentType,
  }) : super(key: key);

  final _SearchStateDelegate delegate;
  final Type contentType;

  @override
  _ContentChipState createState() => _ContentChipState();
}

class _ContentChipState extends State<_ContentChip> with SingleTickerProviderStateMixin {
  static const borderRadius = BorderRadius.all(Radius.circular(50.0));

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
      if (widget.delegate.singleListScrollController.hasClients) {
        widget.delegate.singleListScrollController.jumpTo(0);
      }
      widget.delegate.contentType = widget.contentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final colorScheme =  ThemeControl.theme.colorScheme;
    final colorTween = ColorTween(
      begin: colorScheme.secondary,
      end: Constants.Theme.contrast.auto,
    );
    final baseAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final colorAnimation = colorTween.animate(baseAnimation);
    final textColorAnimation = ColorTween(
      begin: colorScheme.onBackground,
      end: Constants.Theme.contrast.autoReverse,
    ).animate(baseAnimation);
    final splashColorAnimation = ColorTween(
      begin: Constants.Theme.glowSplashColor.auto,
      end: Constants.Theme.glowSplashColor.autoReverse,
    ).animate(baseAnimation);
    if (active) {
      controller.forward();
    } else {
      controller.reverse();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Material(
        color: colorAnimation.value,
        borderRadius: borderRadius,
        child: NFInkWell(
          borderRadius: borderRadius,
          splashColor: splashColorAnimation.value,
          onTap: _handleTap,
            child: IgnorePointer(
              child: Theme(
                data: ThemeControl.theme.copyWith(canvasColor: Colors.transparent),
                child: RawChip(
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: Constants.Theme.contrast.auto.withOpacity(0.05),
                      width: 1.0
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  label: Text(
                    l10n.contents(widget.contentType),
                    style: TextStyle(
                      color: textColorAnimation.value,
                      fontWeight: FontWeight.w800,
                    ),
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
    this.contentType,
    @required this.items,
    @required this.onTap,
  }) : super(key: key);

  final Type contentType;
  final List<Content> items;
  final VoidCallback onTap;

  String getHeaderText(BuildContext context) {
    final l10n = getl10n(context);
    return contentPick<T, String>(
      contentType: contentType,
      song: l10n.tracks,
      album: l10n.albums,
    );
  }

  @override
  Widget build(BuildContext context) {
    final delegate = _SearchStateDelegate._of(context);
    final builder = contentPick<T, Widget Function(int)>(
      contentType: contentType,
      song: (index) {
        final song = items[index] as Song;
        return SongTile.selectable(
          index: index,
          selected: delegate.selectionController.data.contains(
            SelectionEntry<Song>(
              data: song,
              index: 0,
            ),
          ),
          song: song,
          selectionController: delegate.selectionController,
          horizontalPadding: 12.0,
          onTap: delegate.getContentTileTapHandler<Song>(),
        );
      },
      album: (index) {
        final album = items[index] as Album;
        return AlbumTile.selectable(
          index: index,
          selected: delegate.selectionController.data.contains(
            SelectionEntry<Album>(
              data: album,
              index: 0,
            ),
          ),
          album: items[index] as Album,
          selectionController: delegate.selectionController,
          small: false,
          horizontalPadding: 12.0,
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
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ), 
          ),
        ),
        Column(
          children: [
            for (int index = 0; index < math.min(5, items.length); index ++)
              builder(index),
          ],
        )
      ],
    );
  }
}

class _Suggestions extends StatefulWidget {
  _Suggestions({Key key}) : super(key: key);

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
          return const Center(
            child: Spinner(),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: SearchHistory.instance.history.isEmpty
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
    _SearchStateDelegate._of(context).searchDelegate.setState();
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
          icon: const Icon(Icons.delete_sweep_rounded),
          color: ThemeControl.theme.hintColor,
          onPressed: () {
            ShowFunctions.instance.showDialog(
              context,
              ui: Constants.UiTheme.modalOverGrey.auto,
              title: Text(l10n.searchClearHistory),
              buttonSplashColor: Constants.Theme.glowSplashColor.auto,
              acceptButton: NFButton.accept(
                text: l10n.delete,
                splashColor: Constants.Theme.glowSplashColor.auto,
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
  void _removeEntry(BuildContext context, int index) {
    SearchHistory.instance.remove(index);
    _SearchStateDelegate._of(context).searchDelegate.setState();
  }

  void _handleTap(context) {
    final delegate = _SearchStateDelegate._of(context);
    delegate.searchDelegate.query = SearchHistory.instance.history[index];
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
          buttonSplashColor: Constants.Theme.glowSplashColor.auto,
          acceptButton: NFButton.accept(
            text: l10n.remove,
            splashColor: Constants.Theme.glowSplashColor.auto,
            textStyle: const TextStyle(color: Constants.AppColors.red),
            onPressed: () => _removeEntry(context, index)
          ),
        );
      },
    );
  }
}
