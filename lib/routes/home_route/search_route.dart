/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Chromium Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:styled_text/styled_text.dart';

import 'package:sweyer/constants.dart' as constants;
import 'package:sweyer/sweyer.dart';

class _Notifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class ContentSearchDelegate {
  ContentSearchDelegate();

  /// Whether to automatically open the keyboard when page is opened.
  bool autoKeyboard = false;

  final _Notifier _setStateNotifier = _Notifier();

  /// Updates the search route.
  void setState() {
    _setStateNotifier.notify();
  }

  /// Used in [HomeRouter.drawerCanBeOpened].
  bool get chipsBarDragged => _chipsBarDragged;
  bool _chipsBarDragged = false;

  /// The current query string shown in the [AppBar].
  String get query => _queryTextController.text;
  final TextEditingController _queryTextController = TextEditingController();
  set query(String value) {
    _queryTextController.text = value;
  }
}

/// Search results container.
class _Results {
  ContentMap<List<Content>> map = ContentMap({
    for (final contentType in Content.enumerate()) contentType: [],
  });

  List<Song> get songs => map.getValue<Song>()!.cast<Song>();
  List<Album> get albums => map.getValue<Album>()!.cast<Album>();
  List<Playlist> get playlists => map.getValue<Playlist>()!.cast<Playlist>();
  List<Artist> get artists => map.getValue<Artist>()!.cast<Artist>();

  bool get empty => map.values.every((element) => element.isEmpty);
  bool get notEmpty => map.values.any((element) => element.isNotEmpty);

  void clear() {
    for (final value in map.values) {
      value.clear();
    }
  }

  void search(String query) {
    for (final contentType in Content.enumerate()) {
      map.setValue(
        ContentControl.instance.search(query, contentType: contentType),
        key: contentType,
      );
    }
  }
}

class _SearchStateDelegate {
  _SearchStateDelegate(this.selectionController, this.searchDelegate)
      : scrollController = ScrollController(),
        singleListScrollController = ScrollController() {
    /// Initalize [prevQuery] and [trimmedQuery] values.
    onQueryChange();
  }

  // This node is owned, but not hosted by, the search page. Hosting is done by
  // the text field.
  FocusNode focusNode = FocusNode();
  final ScrollController scrollController;
  final ScrollController singleListScrollController;
  final ContentSelectionController selectionController;
  final ContentSearchDelegate searchDelegate;

  /// Used to check whether the body is scrolled.
  final ValueNotifier<bool> bodyScrolledNotifier = ValueNotifier<bool>(false);
  _Results results = _Results();
  String prevQuery = '';
  String trimmedQuery = '';

  void dispose() {
    focusNode.dispose();
    scrollController.dispose();
    singleListScrollController.dispose();
    bodyScrolledNotifier.dispose();
  }

  static _SearchStateDelegate? _of(BuildContext context) {
    return _DelegateProvider.of(context).delegate;
  }

  /// SearchDelegate callbacks.
  String get query => searchDelegate.query;
  void setState() {
    searchDelegate.setState();
  }

  ValueListenable<Type?> get onContentTypeChange => selectionController.onContentTypeChange;

  /// Content type to filter results by.
  ///
  /// When null results are displayed as list of sections, see [ContentSection].
  Type? get contentType => selectionController.primaryContentType;
  set contentType(Type? value) {
    selectionController.primaryContentType = value;
    bodyScrolledNotifier.value = false;
    if (value != null) {
      // Scroll to chip
      ensureVisible(
        chipContextMap.getValue(value)!,
        duration: kTabScrollDuration,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    }
  }

  ContentMap<BuildContext> chipContextMap = ContentMap();

  /// Saves chips context to be able to scroll it when [contentType] changes.
  void registerChipContext(BuildContext context, Type contentType) {
    chipContextMap.setValue(context, key: contentType);
  }

  final showOnlyFavoritesNotifier = ValueNotifier(false);
  bool get showOnlyFavorites => showOnlyFavoritesNotifier.value;
  void toggleShowOnlyFavorites() {
    showOnlyFavoritesNotifier.value = !showOnlyFavoritesNotifier.value;
  }

  void onSubmit() {
    SearchHistory.instance.add(query);
  }

  void onQueryChange() {
    trimmedQuery = query.trim();
    // Update results if previous query is distinct from current.
    if (prevQuery != query) {
      if (trimmedQuery.isEmpty) {
        results.clear();
        contentType = null;
      } else {
        bodyScrolledNotifier.value = false;
        results.search(trimmedQuery);
      }
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      if (singleListScrollController.hasClients) {
        singleListScrollController.jumpTo(0);
      }
    }
    prevQuery = trimmedQuery;
  }

  /// Handles tap to different content tiles.
  void handleContentTap<T extends Content>([Type? contentType]) {
    return contentPick<T, VoidCallback>(
      contentType: contentType,
      song: () {
        onSubmit();
        QueueControl.instance.setSearchedQueue(query, results.songs);
      },
      album: onSubmit,
      playlist: onSubmit,
      artist: onSubmit,
    )();
  }

  /// Scrolls the scrollables that enclose the given context so as to make the
  /// given context visible.
  ///
  /// Copied from [Scrollable.ensureVisible].
  static Future<void> ensureVisible(
    BuildContext context, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
  }) {
    final List<Future<void>> futures = <Future<void>>[];

    // The `targetRenderObject` is used to record the first target renderObject.
    // If there are multiple scrollable widgets nested, we should let
    // the `targetRenderObject` as visible as possible to improve the user experience.
    // Otherwise, let the outer renderObject as visible as possible maybe cause
    // the `targetRenderObject` invisible.
    // Also see https://github.com/flutter/flutter/issues/65100
    RenderObject? targetRenderObject;
    ScrollableState? scrollable = Scrollable.of(context);
    while (scrollable != null) {
      futures.add(_ensureVisible(
        scrollable.position,
        context.findRenderObject()!,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
        targetRenderObject: targetRenderObject,
      ));

      targetRenderObject = targetRenderObject ?? context.findRenderObject();
      context = scrollable.context;
      scrollable = Scrollable.of(context);
    }

    if (futures.isEmpty || duration == Duration.zero) {
      return Future<void>.value();
    }
    if (futures.length == 1) {
      return futures.single;
    }
    return Future.wait<void>(futures).then<void>((List<void> _) => null);
  }

  /// Copied from [ScrollPosition.ensureVisible].
  ///
  /// By default [ScrollPosition.ensureVisible] will always scroll to the
  /// given alignment, no matter what. I need it to scroll only in certain
  /// conditions, so I changed it a little bit.
  static Future<void> _ensureVisible(
    ScrollPosition position,
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
  }) {
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object)!;

    Rect? targetRect;
    if (targetRenderObject != null && targetRenderObject != object) {
      targetRect = MatrixUtils.transformRect(
        targetRenderObject.getTransformTo(object),
        object.paintBounds.intersect(targetRenderObject.paintBounds),
      );
    }

    double target;
    switch (alignmentPolicy) {
      case ScrollPositionAlignmentPolicy.explicit:
        target = viewport
            .getOffsetToReveal(object, alignment, rect: targetRect)
            .offset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtEnd:
        target = viewport
            .getOffsetToReveal(object, 1.0, rect: targetRect)
            .offset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        if (target < position.pixels) {
          target = position.pixels;
        }
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtStart:
        target = viewport
            .getOffsetToReveal(object, 0.0, rect: targetRect)
            .offset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        if (target > position.pixels) {
          target = position.pixels;
        }
        break;
    }

    if (position.pixels > position.viewportDimension / 2 &&
        (position.pixels - target).abs() < position.viewportDimension / 2 - 50) {
      return Future<void>.value();
    }

    if (duration == Duration.zero) {
      position.jumpTo(target);
      return Future<void>.value();
    }

    return position.animateTo(target, duration: duration, curve: curve);
  }
}

class SearchPage extends Page<void> {
  const SearchPage({
    LocalKey? key,
    required this.child,
    this.transitionSettings,
    String? name,
  }) : super(key: key, name: name);

  final Widget child;
  final RouteTransitionSettings? transitionSettings;

  @override
  SearchPageRoute createRoute(BuildContext context) {
    return SearchPageRoute(
      settings: this,
      child: child,
      transitionSettings: transitionSettings,
    );
  }
}

class SearchPageRoute extends RouteTransition<SearchPage> {
  SearchPageRoute({
    required this.child,
    RouteSettings? settings,
    RouteTransitionSettings? transitionSettings,
  }) : super(
          settings: settings,
          transitionSettings: transitionSettings,
        );

  final Widget child;

  @override
  bool get maintainState => true;

  @override
  Widget buildContent(BuildContext context) {
    return child;
  }

  @override
  Widget buildAnimation(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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

class SearchRoute extends StatefulWidget {
  const SearchRoute({
    Key? key,
    required this.delegate,
  }) : super(key: key);

  final ContentSearchDelegate delegate;

  @override
  _SearchRouteState createState() => _SearchRouteState();
}

class _SearchRouteState extends State<SearchRoute> with SelectionHandlerMixin {
  late _SearchStateDelegate stateDelegate;
  FocusNode get focusNode => stateDelegate.focusNode;
  late ModalRoute _route;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    initSelectionController(() => ContentSelectionController.create(
          vsync: AppRouter.instance.navigatorKey.currentState!,
          context: context,
          closeButton: true,
          ignoreWhen: () =>
              playerRouteController.opened || HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.search),
        ));

    stateDelegate = _SearchStateDelegate(selectionController, widget.delegate);
    widget.delegate._setStateNotifier.addListener(_handleSetState);
    widget.delegate._queryTextController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        _route = ModalRoute.of(context)!;
        _animation = _route.animation!;
        _animation.addStatusListener(_onAnimationStatusChanged);
      }
    });
    focusNode.addListener(_onFocusChanged);
    playerRouteController.addStatusListener(_handlePlayerRouteStatusChange);
  }

  @override
  void dispose() {
    stateDelegate.dispose();
    disposeSelectionController();
    widget.delegate._setStateNotifier.removeListener(_handleSetState);
    widget.delegate._queryTextController.removeListener(_onQueryChanged);
    widget.delegate._chipsBarDragged = false;
    _animation.removeStatusListener(_onAnimationStatusChanged);
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
    _animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate.autoKeyboard) {
      focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(SearchRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      oldWidget.delegate._queryTextController.removeListener(_onQueryChanged);
      widget.delegate._queryTextController.addListener(_onQueryChanged);
    }
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) {
      if (widget.delegate.autoKeyboard) {
        setState(() {});
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
    focusNode.unfocus();
    Navigator.of(context)
      ..popUntil((Route<dynamic> route) => route == _route)
      ..pop(result);
  }

  void _handlePushNext() {
    // Unfocus when other route opened above the search.
    focusNode.unfocus();
  }

  ThemeData buildAppBarTheme() {
    final ThemeData theme = ThemeControl.instance.theme;
    return theme.copyWith(
      primaryColor: theme.backgroundColor,
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
        close(context, null);
      },
    );
  }

  PreferredSizeWidget buildBottom() {
    const bottomPadding = 12.0;
    final contentTypeEntries = stateDelegate.results.map.entries
        .where(
          (el) => el.value.isNotEmpty,
        )
        .toList();
    final showChips = stateDelegate.results.notEmpty;
    return PreferredSize(
      preferredSize: Size.fromHeight(
        showChips ? AppBarBorder.height + _ContentChip.height + bottomPadding : AppBarBorder.height,
      ),
      child: ValueListenableBuilder<Type?>(
        valueListenable: stateDelegate.onContentTypeChange,
        builder: (context, contentTypeValue, child) {
          if (!showChips) {
            return child!;
          }

          final List<Widget> children = [
            _ContentChip.favorites(
              delegate: stateDelegate,
            ),
          ];
          if (contentTypeEntries.length > 1) {
            for (int i = 0; i < contentTypeEntries.length; i++) {
              children.add(const SizedBox(width: 8.0));
              children.add(_ContentChip(
                delegate: stateDelegate,
                contentType: contentTypeEntries[i].key,
              ));
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _ContentChip.height,
                child: GestureDetector(
                  onPanDown: (_) {
                    widget.delegate._chipsBarDragged = true;
                  },
                  onPanCancel: () {
                    widget.delegate._chipsBarDragged = false;
                  },
                  onPanEnd: (_) {
                    widget.delegate._chipsBarDragged = false;
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: children,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: bottomPadding),
              child!,
            ],
          );
        },
        child: ValueListenableBuilder<bool>(
            valueListenable: stateDelegate.bodyScrolledNotifier,
            builder: (context, scrolled, child) => AppBarBorder(shown: scrolled)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final theme = buildAppBarTheme();
    final bottom = buildBottom();
    final String searchFieldLabel = MaterialLocalizations.of(context).searchFieldLabel;
    String? routeName;
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
    final title = TextField(
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
    );
    final selectAllAction = ValueListenableBuilder<Type?>(
      valueListenable: stateDelegate.onContentTypeChange,
      builder: (context, contentType, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => EmergeAnimation(
          animation: animation,
          child: child,
        ),
        child: stateDelegate.contentType == null
            ? const SizedBox.shrink()
            : SelectAllSelectionAction<Content>(
                controller: selectionController,
                entryFactory: (content, index) => SelectionEntry.fromContent(
                  content: content,
                  index: index,
                  context: context,
                ),
                getAll: () {
                  final list = stateDelegate.results.map.getValue(contentType)!;
                  return stateDelegate.showOnlyFavorites ? ContentUtils.filterFavorite(list).toList() : list;
                },
              ),
      ),
    );
    return _DelegateProvider(
      delegate: stateDelegate,
      child: RouteAwareWidget(
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
                preferredSize: Size.fromHeight(kToolbarHeight + bottom.preferredSize.height),
                child: SelectionAppBar(
                  selectionController: stateDelegate.selectionController,
                  onMenuPressed: null,
                  showMenuButton: false,
                  titleSelection: selectionRoute
                      ? title
                      : Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: SelectionCounter(controller: stateDelegate.selectionController),
                        ),
                  actionsSelection: selectionRoute
                      ? [
                          if (widget.delegate.query.isNotEmpty) selectAllAction,
                          if (widget.delegate.query.isNotEmpty) const _ClearButton(),
                        ]
                      : [
                          DeleteSongsAppBarAction<Content>(
                            controller: stateDelegate.selectionController,
                          ),
                          selectAllAction,
                        ],
                  elevationSelection: 0.0,
                  elevation: theme.appBarTheme.elevation!,
                  toolbarHeight: kToolbarHeight,
                  backgroundColor: theme.primaryColor,
                  iconTheme: theme.primaryIconTheme,
                  textTheme: theme.primaryTextTheme,
                  leading: buildLeading(),
                  actions: selectionRoute
                      ? const []
                      : [
                          if (widget.delegate.query.isNotEmpty) const _ClearButton(),
                        ],
                  bottom: bottom,
                  title: !selectionRoute ? title : const SizedBox.shrink(),
                ),
              ),
              body: SafeArea(
                child: GestureDetector(
                  onTap: () => focusNode.unfocus(),
                  onVerticalDragDown: (_) => focusNode.unfocus(),
                  child: const _DelegateBuilder(),
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
    Key? key,
    required this.delegate,
    required Widget child,
  }) : super(key: key, child: child);

  final _SearchStateDelegate? delegate;

  static _DelegateProvider of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_DelegateProvider>()!.widget as _DelegateProvider;
  }

  @override
  bool updateShouldNotify(_DelegateProvider oldWidget) => false;
}

class _DelegateBuilder extends StatefulWidget {
  const _DelegateBuilder({Key? key}) : super(key: key);

  @override
  _DelegateBuilderState createState() => _DelegateBuilderState();
}

class _DelegateBuilderState extends State<_DelegateBuilder> {
  // TODO: remove when https://github.com/flutter/flutter/issues/82046 is resolved
  bool _onTop = true;
  int _prevIndex = -1;

  Future<bool> _handlePop(_SearchStateDelegate delegate) async {
    if (_onTop && delegate.contentType != null) {
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
    final delegate = _SearchStateDelegate._of(context)!;
    final results = delegate.results;
    final l10n = getl10n(context);
    return RouteAwareWidget(
      onPushNext: () => _onTop = false,
      onPopNext: () => _onTop = true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => _handleNotification(delegate, notification),
        child: ValueListenableBuilder<bool>(
          valueListenable: delegate.showOnlyFavoritesNotifier,
          builder: (context, showOnlyFavorites, child) => ValueListenableBuilder<Type?>(
            valueListenable: delegate.onContentTypeChange,
            builder: (context, contentType, child) {
              if (delegate.trimmedQuery.isEmpty) {
                return const _Suggestions();
              } else if (results.empty) {
                return const _NothingFound();
              } else {
                final contentTypeEntries = results.map.entries
                    .where(
                      (el) => el.value.isNotEmpty,
                    )
                    .toList();
                final single = contentTypeEntries.length == 1;
                final showSingleCategoryContentList = single || contentType != null;
                final contentListContentType = single ? contentTypeEntries.single.key : contentType;
                final index = contentType == null ? -1 : Content.enumerate().indexOf(contentType);
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  _prevIndex = index;
                });
                return BackButtonListener(
                  onBackButtonPressed: () => _handlePop(delegate),
                  child: StreamBuilder(
                    stream: PlaybackControl.instance.onSongChange,
                    builder: (context, snapshot) => StreamBuilder(
                      stream: ContentControl.instance.onContentChange,
                      builder: (context, snapshot) {
                        IndexMapper getSelectionIndexMapper(
                          List<Content> filteredList,
                          Map<Content, int> listIndexMap,
                        ) {
                          return (index) => listIndexMap[filteredList[index]]!;
                        }

                        ContentItemTest getSelectedTest(List<Content> filteredList, Map<Content, int> listIndexMap) {
                          return (index) => delegate.selectionController.data.contains(SelectionEntry.fromContent(
                                content: filteredList[index],
                                index: listIndexMap[filteredList[index]]!,
                                context: context,
                              ));
                        }

                        final Widget child;

                        if (showSingleCategoryContentList) {
                          final list = single ? contentTypeEntries.single.value : results.map.getValue(contentType)!;
                          final listIndexMap = {
                            for (int i = 0; i < list.length; i++) list[i]: i,
                          };
                          final filteredList = showOnlyFavorites ? ContentUtils.filterFavorite(list).toList() : list;
                          if (filteredList.isEmpty) {
                            child = const _NothingFound();
                          } else {
                            child = ContentListView<Content>(
                              contentType: contentListContentType,
                              controller: delegate.singleListScrollController,
                              selectionController: delegate.selectionController,
                              onItemTap: (index) => delegate.handleContentTap(contentListContentType),
                              list: filteredList,
                              selectedTest: getSelectedTest(filteredList, listIndexMap),
                              selectionIndexMapper: getSelectionIndexMapper(filteredList, listIndexMap),
                            );
                          }
                        } else {
                          // AppScrollbar( // TODO: enable this when i have more content on search screen
                          //     controller: delegate.scrollController,
                          //     child:
                          final List<Widget> children = [];
                          int emptyCount = 0;
                          for (final entry in contentTypeEntries) {
                            final list = results.map.getValue(entry.key)!;
                            final listIndexMap = {
                              for (int i = 0; i < list.length; i++) list[i]: i,
                            };
                            final filteredList = showOnlyFavorites ? ContentUtils.filterFavorite(list).toList() : list;
                            if (filteredList.isEmpty) {
                              emptyCount += 1;
                              children.add(ContentSection.custom(
                                contentType: entry.key,
                                list: filteredList,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(l10n.searchNothingFound),
                                  ),
                                ),
                                onHeaderTap: () => delegate.contentType = entry.key,
                              ));
                            } else {
                              children.add(ContentSection(
                                contentType: entry.key,
                                list: filteredList,
                                onHeaderTap: () => delegate.contentType = entry.key,
                                selectionController: delegate.selectionController,
                                contentTileTapHandler: () => delegate.handleContentTap(entry.key),
                                selectedTest: getSelectedTest(filteredList, listIndexMap),
                                selectionIndexMapper: getSelectionIndexMapper(filteredList, listIndexMap),
                              ));
                            }
                          }
                          if (emptyCount == contentTypeEntries.length) {
                            child = const _NothingFound();
                          } else {
                            child = ListView(
                              controller: delegate.scrollController,
                              children: children,
                            );
                          }
                        }
                        return PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 300),
                          reverse: !single && (contentType == null || index < _prevIndex),
                          transitionBuilder: (child, animation, secondaryAnimation) => SharedAxisTransition(
                            transitionType: SharedAxisTransitionType.horizontal,
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            fillColor: Colors.transparent,
                            child: child,
                          ),
                          child: Container(
                            key: ValueKey(contentType),
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final delegate = _SearchStateDelegate._of(context)!;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: NFIconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          delegate.searchDelegate.query = '';
        },
      ),
    );
  }
}

class _ContentChip extends StatefulWidget {
  const _ContentChip({
    Key? key,
    required this.delegate,
    required this.contentType,
  })  : favoritesChip = false,
        super(key: key);

  const _ContentChip.favorites({
    Key? key,
    required this.delegate,
  })  : favoritesChip = true,
        contentType = null,
        super(key: key);

  final _SearchStateDelegate delegate;
  final Type? contentType;
  final bool favoritesChip;

  static const double height = 34.0;

  @override
  _ContentChipState createState() => _ContentChipState();
}

class _ContentChipState extends State<_ContentChip> with SingleTickerProviderStateMixin {
  static const borderRadius = BorderRadius.all(Radius.circular(50.0));

  late AnimationController controller;

  bool get favoritesChip => widget.favoritesChip;
  _SearchStateDelegate get delegate => widget.delegate;

  bool get active {
    if (favoritesChip) {
      return delegate.showOnlyFavoritesNotifier.value;
    }
    return delegate.contentType == widget.contentType;
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (favoritesChip) {
      delegate.showOnlyFavoritesNotifier.addListener(_favoriteListener);
    } else {
      delegate.registerChipContext(context, widget.contentType!);
    }
    if (active) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    if (favoritesChip) {
      delegate.showOnlyFavoritesNotifier.removeListener(_favoriteListener);
    }
    controller.dispose();
    super.dispose();
  }

  void _favoriteListener() {
    setState(() {
      // update since [active] has changed
    });
  }

  void _handleTap() {
    if (favoritesChip) {
      delegate.toggleShowOnlyFavorites();
      return;
    }
    if (active) {
      delegate.contentType = null;
    } else {
      if (delegate.singleListScrollController.hasClients) {
        delegate.singleListScrollController.jumpTo(0);
      }
      delegate.contentType = widget.contentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (active) {
      controller.forward();
    } else {
      controller.reverse();
    }
    final l10n = getl10n(context);
    final count = favoritesChip ? null : delegate.results.map.getValue(widget.contentType)!.length;
    final colorScheme = ThemeControl.instance.theme.colorScheme;
    final colorTween = ColorTween(
      begin: colorScheme.secondary,
      end: constants.Theme.contrast.auto,
    );
    final baseAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final colorAnimation = colorTween.animate(baseAnimation);
    final textColorAnimation = ColorTween(
      begin: colorScheme.onBackground,
      end: favoritesChip ? Colors.redAccent : constants.Theme.contrast.autoReverse,
    ).animate(baseAnimation);
    final splashColorAnimation = ColorTween(
      begin: constants.Theme.glowSplashColor.auto,
      end: constants.Theme.glowSplashColorOnContrast.auto,
    ).animate(baseAnimation);
    return SizedBox(
      height: _ContentChip.height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Material(
          color: colorAnimation.value,
          borderRadius: favoritesChip ? null : borderRadius,
          shape: !favoritesChip
              ? null
              : StadiumBorder(
                  side: BorderSide(
                    color: constants.Theme.contrast.auto.withOpacity(0.05),
                    width: 1.0,
                  ),
                ),
          child: NFInkWell(
            borderRadius: borderRadius,
            splashColor: splashColorAnimation.value,
            onTap: _handleTap,
            child: favoritesChip
                ? SizedBox(
                    width: _ContentChip.height,
                    child: Icon(
                      active ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 20.0,
                      color: textColorAnimation.value,
                    ),
                  )
                : IgnorePointer(
                    child: Theme(
                      data: ThemeControl.instance.theme.copyWith(canvasColor: Colors.transparent),
                      child: RawChip(
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: constants.Theme.contrast.auto.withOpacity(0.05),
                            width: 1.0,
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        label: Text(
                          l10n.contentsPlural(count!, widget.contentType),
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
      ),
    );
  }
}

/// Displays a message that there's nothing found.
class _NothingFound extends StatelessWidget {
  const _NothingFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
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
  }
}

class _Suggestions extends StatefulWidget {
  const _Suggestions({Key? key}) : super(key: key);

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<_Suggestions> {
  Future<void>? _loadFuture;

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
          child: SearchHistory.instance.history!.isEmpty
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
                        fontWeight: FontWeight.w700,
                        color: ThemeControl.instance.theme.hintColor,
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
                    itemCount: SearchHistory.instance.history!.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _SuggestionsHeader();
                      }
                      index--;
                      return _SuggestionTile(index: index);
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _SuggestionsHeader extends StatelessWidget {
  const _SuggestionsHeader({Key? key}) : super(key: key);

  void clearHistory(BuildContext context) {
    SearchHistory.instance.clear();
    _SearchStateDelegate._of(context)!.searchDelegate.setState();
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
          color: ThemeControl.instance.theme.hintColor,
          onPressed: () {
            ShowFunctions.instance.showDialog(
              context,
              ui: constants.UiTheme.modalOverGrey.auto,
              title: Text(l10n.searchClearHistory),
              buttonSplashColor: constants.Theme.glowSplashColor.auto,
              acceptButton: AppButton.pop(
                text: l10n.delete,
                popResult: true,
                splashColor: constants.Theme.glowSplashColor.auto,
                textColor: constants.AppColors.red,
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
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  /// Deletes item from search history by its index.
  void _removeEntry(BuildContext context, int index) {
    SearchHistory.instance.removeAt(index);
    _SearchStateDelegate._of(context)!.searchDelegate.setState();
  }

  void _handleTap(context) {
    final delegate = _SearchStateDelegate._of(context)!;
    delegate.searchDelegate.query = SearchHistory.instance.history![index];
    delegate.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return NFListTile(
      onTap: () => _handleTap(context),
      title: Text(
        SearchHistory.instance.history![index],
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
          color: ThemeControl.instance.theme.iconTheme.color,
        ),
      ),
      onLongPress: () {
        ShowFunctions.instance.showDialog(
          context,
          ui: constants.UiTheme.modalOverGrey.auto,
          title: Text(l10n.searchHistory),
          titlePadding: defaultAlertTitlePadding.copyWith(bottom: 4.0),
          contentPadding: defaultAlertContentPadding.copyWith(bottom: 6.0),
          content: StyledText(
            style: const TextStyle(fontSize: 15.0),
            text: l10n.searchHistoryRemoveEntryDescription(
              '<bold>${l10n.escapeStyled('"${SearchHistory.instance.history![index]}"')}</bold>',
            ),
            tags: {
              'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.w700)),
            },
          ),
          buttonSplashColor: constants.Theme.glowSplashColor.auto,
          acceptButton: AppButton.pop(
            text: l10n.remove,
            popResult: true,
            splashColor: constants.Theme.glowSplashColor.auto,
            textColor: constants.AppColors.red,
            onPressed: () => _removeEntry(context, index),
          ),
        );
      },
    );
  }
}
