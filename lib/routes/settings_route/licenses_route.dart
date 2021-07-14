/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// ###########################################################################################
/// copied this from flutter https://github.com/flutter/flutter/commit/183f0e797a3bf8aa1b35b650150f7522d5d10377
/// ###########################################################################################

import 'dart:developer' show Timeline, Flow;
import 'dart:io' show Platform;

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Flow;
import 'package:flutter/scheduler.dart';

import 'package:sweyer/sweyer.dart';

/// A page that shows licenses for software used by the application.
///
/// To show a [LicensePage], use [showLicensePage].
///
/// The [AboutDialog] shown by [showAboutDialog] and [AboutListTile] includes
/// a button that calls [showLicensePage].
///
/// The licenses shown on the [LicensePage] are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
class LicensePage extends StatefulWidget {
  /// Creates a page that shows licenses for software used by the application.
  ///
  /// The arguments are all optional. The application name, if omitted, will be
  /// derived from the nearest [Title] widget. The version and legalese values
  /// default to the empty string.
  ///
  /// The licenses shown on the [LicensePage] are those returned by the
  /// [LicenseRegistry] API, which can be used to add more licenses to the list.
  const LicensePage({
    Key? key,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
  }) : super(key: key);

  /// The name of the application.
  ///
  /// Defaults to the value of [Title.title], if a [Title] widget can be found.
  /// Otherwise, defaults to [Platform.resolvedExecutable].
  final String? applicationName;

  /// The version of this build of the application.
  ///
  /// This string is shown under the application name.
  ///
  /// Defaults to the empty string.
  final String? applicationVersion;

  /// The icon to show below the application name.
  ///
  /// By default no icon is shown.
  ///
  /// Typically this will be an [ImageIcon] widget. It should honor the
  /// [IconTheme]'s [IconThemeData.size].
  final Widget? applicationIcon;

  /// A string to show in small print.
  ///
  /// Typically this is a copyright notice.
  ///
  /// Defaults to the empty string.
  final String? applicationLegalese;

  @override
  _LicensePageState createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final ValueNotifier<int?> selectedId = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    return _MasterDetailFlow(
      detailPageFABlessGutterWidth: _getGutterSize(context),
      title: Text(MaterialLocalizations.of(context).licensesPageTitle),
      leading: NFBackButton(
        onPressed: () => Navigator.of(context).pop(),
      ),
      detailPageBuilder: _packageLicensePage,
      masterViewBuilder: _packagesView,
    );
  }

  Widget _packageLicensePage(
      BuildContext _, Object? args, ScrollController? scrollController) {
    assert(args is _DetailArguments);
    final _DetailArguments detailArguments = args! as _DetailArguments;
    return _PackageLicensePage(
      packageName: detailArguments.packageName,
      licenseEntries: detailArguments.licenseEntries,
      scrollController: scrollController,
    );
  }

  Widget _packagesView(final BuildContext _, final bool isLateral) {
    return _PackagesView(
      isLateral: isLateral,
      selectedId: selectedId,
    );
  }
}

class _PackagesView extends StatefulWidget {
  const _PackagesView({
    Key? key,
    required this.isLateral,
    required this.selectedId,
  }) : super(key: key);

  final bool isLateral;
  final ValueNotifier<int?> selectedId;

  @override
  _PackagesViewState createState() => _PackagesViewState();
}

class _PackagesViewState extends State<_PackagesView> {
  final Future<_LicenseData> licenses = LicenseRegistry.licenses
      .fold<_LicenseData>(
        _LicenseData(),
        (_LicenseData prev, LicenseEntry license) => prev..addLicense(license),
      )
      .then((_LicenseData licenseData) => licenseData..sortPackages());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LicenseData>(
      future: licenses,
      builder: (BuildContext context, AsyncSnapshot<_LicenseData> snapshot) {
        return LayoutBuilder(
          key: ValueKey<ConnectionState>(snapshot.connectionState),
          builder: (BuildContext context, BoxConstraints constraints) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _initDefaultDetailPage(snapshot.data!, context);
                return ValueListenableBuilder<int?>(
                  valueListenable: widget.selectedId,
                  builder: (BuildContext context, int? selectedId, Widget? _) {
                    return Center(
                      child: Container(
                        constraints:
                            BoxConstraints.loose(const Size.fromWidth(600.0)),
                        child: _packagesList(context, selectedId,
                            snapshot.data!, widget.isLateral),
                      ),
                    );
                  },
                );
              default:
                return const Center(
                  child: Spinner(),
                );
            }
          },
        );
      },
    );
  }

  void _initDefaultDetailPage(_LicenseData data, BuildContext context) {
    if (data.packages.isEmpty) {
      return;
    }
    final String packageName = data.packages[widget.selectedId.value ?? 0];
    final List<int> bindings = data.packageLicenseBindings[packageName]!;
    _MasterDetailFlow.of(context)!.setInitialDetailPage(
      _DetailArguments(
        packageName,
        bindings.map((int i) => data.licenses[i]).toList(growable: false),
      ),
    );
  }

  Widget _packagesList(
    final BuildContext context,
    final int? selectedId,
    final _LicenseData data,
    final bool drawSelection,
  ) {
    return AppScrollbar(
      child: ListView(
        itemExtent: 64,
        children: <Widget>[
          ...data.packages
              .asMap()
              .entries
              .map<Widget>((MapEntry<int, String> entry) {
            final String packageName = entry.value;
            final int index = entry.key;
            final List<int> bindings = data.packageLicenseBindings[packageName]!;
            return _PackageListTile(
              packageName: packageName,
              index: index,
              isSelected: drawSelection && entry.key == (selectedId ?? 0),
              numberLicenses: bindings.length,
              onTap: () {
                widget.selectedId.value = index;
                _MasterDetailFlow.of(context)!.openDetailPage(_DetailArguments(
                  packageName,
                  bindings
                      .map((int i) => data.licenses[i])
                      .toList(growable: false),
                ));
              },
            );
          }),
        ],
      ),
    );
  }
}

class _PackageListTile extends StatelessWidget {
  const _PackageListTile({
    Key? key,
    required this.packageName,
    this.index,
    required this.isSelected,
    required this.numberLicenses,
    this.onTap,
  }) : super(key: key);

  final String packageName;
  final int? index;
  final bool isSelected;
  final int numberLicenses;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Ink(
      child: NFListTile(
        dense: true,
        title: Text(
          packageName,
          overflow: TextOverflow.ellipsis,
          style: ThemeControl.theme.textTheme.headline6,
        ),
        subtitle: Text(
          MaterialLocalizations.of(context)
              .licensesPackageDetailText(numberLicenses),
          style: ThemeControl.theme.textTheme.subtitle2,
        ),
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }
}

/// This is a collection of licenses and the packages to which they apply.
/// [packageLicenseBindings] records the m+:n+ relationship between the license
/// and packages as a map of package names to license indexes.
class _LicenseData {
  final List<LicenseEntry> licenses = <LicenseEntry>[];
  final Map<String, List<int>> packageLicenseBindings = <String, List<int>>{};
  final List<String> packages = <String>[];

  // Special treatment for the first package since it should be the package
  // for delivered application.
  String? firstPackage;

  void addLicense(LicenseEntry entry) {
    // Before the license can be added, we must first record the packages to
    // which it belongs.
    for (final String package in entry.packages) {
      _addPackage(package);
      // Bind this license to the package using the next index value. This
      // creates a contract that this license must be inserted at this same
      // index value.
      packageLicenseBindings[package]!.add(licenses.length);
    }
    licenses.add(entry); // Completion of the contract above.
  }

  /// Add a package and initialize package license binding. This is a no-op if
  /// the package has been seen before.
  void _addPackage(String package) {
    if (!packageLicenseBindings.containsKey(package)) {
      packageLicenseBindings[package] = <int>[];
      firstPackage ??= package;
      packages.add(package);
    }
  }

  /// Sort the packages using some comparison method, or by the default manner,
  /// which is to put the application package first, followed by every other
  /// package in case-insensitive alphabetical order.
  void sortPackages([int Function(String a, String b)? compare]) {
    packages.sort(compare ??
        (String a, String b) {
          // Based on how LicenseRegistry currently behaves, the first package
          // returned is the end user application license. This should be
          // presented first in the list. So here we make sure that first package
          // remains at the front regardless of alphabetical sorting.
          if (a == firstPackage) {
            return -1;
          }
          if (b == firstPackage) {
            return 1;
          }
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
  }
}

@immutable
class _DetailArguments {
  const _DetailArguments(this.packageName, this.licenseEntries);

  final String packageName;
  final List<LicenseEntry> licenseEntries;

  @override
  bool operator ==(final dynamic other) {
    if (other is _DetailArguments) {
      return other.packageName == packageName;
    }
    return other == this;
  }

  @override
  int get hashCode => packageName.hashCode; // Good enough.
}

class _PackageLicensePage extends StatefulWidget {
  const _PackageLicensePage({
    Key? key,
    required this.packageName,
    required this.licenseEntries,
    required this.scrollController,
  }) : super(key: key);

  final String packageName;
  final List<LicenseEntry> licenseEntries;
  final ScrollController? scrollController;

  @override
  _PackageLicensePageState createState() => _PackageLicensePageState();
}

class _PackageLicensePageState extends State<_PackageLicensePage> {
  @override
  void initState() {
    super.initState();
    _initLicenses();
  }

  final List<Widget> _licenses = <Widget>[];
  bool _loaded = false;

  Future<void> _initLicenses() async {
    int debugFlowId = -1;
    assert(() {
      final Flow flow = Flow.begin();
      Timeline.timeSync('_initLicenses()', () {}, flow: flow);
      debugFlowId = flow.id;
      return true;
    }());
    for (final LicenseEntry license in widget.licenseEntries) {
      if (!mounted) {
        return;
      }
      assert(() {
        Timeline.timeSync('_initLicenses()', () {},
            flow: Flow.step(debugFlowId));
        return true;
      }());
      final List<LicenseParagraph> paragraphs =
          await SchedulerBinding.instance!.scheduleTask<List<LicenseParagraph>>(
        license.paragraphs.toList,
        Priority.animation,
        debugLabel: 'License',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _licenses.add(const Padding(
          padding: EdgeInsets.all(18.0),
          child: Divider(),
        ));
        for (final LicenseParagraph paragraph in paragraphs) {
          if (paragraph.indent == LicenseParagraph.centeredIndent) {
            _licenses.add(Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                paragraph.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ));
          } else {
            assert(paragraph.indent >= 0);
            _licenses.add(Padding(
              padding: EdgeInsetsDirectional.only(
                  top: 8.0, start: 16.0 * paragraph.indent),
              child: Text(paragraph.text),
            ));
          }
        }
      });
    }
    setState(() {
      _loaded = true;
    });
    assert(() {
      Timeline.timeSync('Build scheduled', () {}, flow: Flow.end(debugFlowId));
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String title = widget.packageName;
    final String subtitle =
        localizations.licensesPackageDetailText(widget.licenseEntries.length);
    final double pad = _getGutterSize(context);
    final EdgeInsets padding =
        EdgeInsets.only(left: pad, right: pad, bottom: pad);
    final List<Widget> listWidgets = <Widget>[
      ..._licenses,
      if (!_loaded)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Spinner(),
          ),
        ),
    ];

    final Widget page;
    if (widget.scrollController == null) {
      page = Scaffold(
        appBar: AppBar(
          leading: NFBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: _PackageLicensePageTitle(
            title: title,
            subtitle: subtitle,
            titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 20.0),
            subtitleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 15.0),
          ),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(600.0)),
            child: AppScrollbar(
              child: ListView(padding: padding, children: listWidgets),
            ),
          ),
        ),
      );
    } else {
      page = CustomScrollView(
        controller: widget.scrollController,
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 0.0,
            pinned: true,
            backgroundColor: theme.colorScheme.secondary,
            title: _PackageLicensePageTitle(
              title: title,
              subtitle: subtitle,
              titleTextStyle: theme.textTheme.headline6,
              subtitleTextStyle: theme.textTheme.subtitle2,
            ),
          ),
          SliverPadding(
            padding: padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => listWidgets[index],
                childCount: listWidgets.length,
              ),
            ),
          ),
        ],
      );
    }
    return DefaultTextStyle(
      style: theme.textTheme.caption!,
      child: page,
    );
  }
}

class _PackageLicensePageTitle extends StatelessWidget {
  const _PackageLicensePageTitle({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.titleTextStyle,
    required this.subtitleTextStyle,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: titleTextStyle),
          Text(subtitle, style: subtitleTextStyle),
        ],
      ),
    );
  }
}

const int _materialGutterThreshold = 720;
const double _wideGutterSize = 24.0;
const double _narrowGutterSize = 12.0;

double _getGutterSize(BuildContext context) =>
    MediaQuery.of(context).size.width >= _materialGutterThreshold
        ? _wideGutterSize
        : _narrowGutterSize;

/// Signature for the builder callback used by [_MasterDetailFlow].
typedef _MasterViewBuilder = Widget Function(
    BuildContext context, bool isLateralUI);

/// Signature for the builder callback used by [_MasterDetailFlow.detailPageBuilder].
///
/// scrollController is provided when the page destination is the draggable
/// sheet in the lateral UI. Otherwise, it is null.
typedef _DetailPageBuilder = Widget Function(BuildContext context,
    Object? arguments, ScrollController? scrollController);

/// Signature for the builder callback used by [_MasterDetailFlow.actionBuilder].
///
/// Builds the actions that go in the app bars constructed for the master and
/// lateral UI pages. actionLevel indicates the intended destination of the
/// return actions.
typedef _ActionBuilder = List<Widget> Function(
    BuildContext context, _ActionLevel actionLevel);

/// Describes which type of app bar the actions are intended for.
enum _ActionLevel {
  /// Indicates the top app bar in the lateral UI.
  top,

  /// Indicates the master view app bar in the lateral UI.
  // ignore: unused_field
  view,

  /// Indicates the master page app bar in the nested UI.
  composite,
}

/// Describes which layout will be used by [_MasterDetailFlow].
enum _LayoutMode {
  /// Use a nested or lateral layout depending on available screen width.
  auto,

  /// Always use a lateral layout.
  lateral,

  /// Always use a nested layout.
  nested,
}

const String _navMaster = 'master';
const String _navDetail = 'detail';
enum _Focus { master, detail }

/// A Master Detail Flow widget. Depending on screen width it builds either a
/// lateral or nested navigation flow between a master view and a detail page.
/// bloc pattern.
///
/// If focus is on detail view, then switching to nested navigation will
/// populate the navigation history with the master page and the detail page on
/// top. Otherwise the focus is on the master view and just the master page
/// is shown.
class _MasterDetailFlow extends StatefulWidget {
  /// Creates a master detail navigation flow which is either nested or
  /// lateral depending on screen width.
  const _MasterDetailFlow({
    Key? key,
    required this.detailPageBuilder,
    required this.masterViewBuilder,
    this.actionBuilder,
    this.automaticallyImplyLeading = true,
    this.breakpoint,
    this.centerTitle,
    this.detailPageFABGutterWidth,
    this.detailPageFABlessGutterWidth,
    this.displayMode = _LayoutMode.auto,
    this.flexibleSpace,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonMasterPageLocation,
    this.leading,
    this.masterPageBuilder,
    this.masterViewWidth,
    this.title,
  }) : super(key: key);

  /// Builder for the master view for lateral navigation.
  ///
  /// If [masterPageBuilder] is not supplied the master page required for nested navigation, also
  /// builds the master view inside a [Scaffold] with an [AppBar].
  final _MasterViewBuilder masterViewBuilder;

  /// Builder for the master page for nested navigation.
  ///
  /// This builder is usually a wrapper around the [masterViewBuilder] builder to provide the
  /// extra UI required to make a page. However, this builder is optional, and the master page
  /// can be built using the master view builder and the configuration for the lateral UI's app bar.
  final _MasterViewBuilder? masterPageBuilder;

  /// Builder for the detail page.
  ///
  /// If scrollController == null, the page is intended for nested navigation. The lateral detail
  /// page is inside a [DraggableScrollableSheet] and should have a scrollable element that uses
  /// the [ScrollController] provided. In fact, it is strongly recommended the entire lateral
  /// page is scrollable.
  final _DetailPageBuilder detailPageBuilder;

  /// Override the width of the master view in the lateral UI.
  final double? masterViewWidth;

  /// Override the width of the floating action button gutter in the lateral UI.
  final double? detailPageFABGutterWidth;

  /// Override the width of the gutter when there is no floating action button.
  final double? detailPageFABlessGutterWidth;

  /// Add a floating action button to the lateral UI. If no [masterPageBuilder] is supplied, this
  /// floating action button is also used on the nested master page.
  ///
  /// See [Scaffold.floatingActionButton].
  final FloatingActionButton? floatingActionButton;

  /// The title for the lateral UI [AppBar].
  ///
  /// See [AppBar.title].
  final Widget? title;

  /// A widget to display before the title for the lateral UI [AppBar].
  ///
  /// See [AppBar.leading].
  final Widget? leading;

  /// Override the framework from determining whether to show a leading widget or not.
  ///
  /// See [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Override the framework from determining whether to display the title in the center of the
  /// app bar or not.
  ///
  /// See [AppBar.centerTitle].
  final bool? centerTitle;

  /// See [AppBar.flexibleSpace].
  final Widget? flexibleSpace;

  /// Build actions for the lateral UI, and potentially the master page in the nested UI.
  ///
  /// If level is [_ActionLevel.top] then the actions are for
  /// the entire lateral UI page. If level is [_ActionLevel.view] the actions
  /// are for the master
  /// view toolbar. Finally, if the [AppBar] for the master page for the nested UI is being built
  /// by [_MasterDetailFlow], then [_ActionLevel.composite] indicates the
  /// actions are for the
  /// nested master page.
  final _ActionBuilder? actionBuilder;

  /// Determine where the floating action button will go.
  ///
  /// If null, [FloatingActionButtonLocation.endTop] is used.
  ///
  /// Also see [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Determine where the floating action button will go on the master page.
  ///
  /// See [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonMasterPageLocation;

  /// Forces display mode and style.
  final _LayoutMode displayMode;

  /// Width at which layout changes from nested to lateral.
  final double? breakpoint;

  @override
  _MasterDetailFlowState createState() => _MasterDetailFlowState();

  /// The master detail flow proxy from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// _MasterDetailFlow.of(context).openDetailPage(arguments);
  /// ```
  static _MasterDetailFlowProxy? of(
    BuildContext context, {
    bool nullOk = false,
  }) {
    _PageOpener? pageOpener =
        context.findAncestorStateOfType<_MasterDetailScaffoldState>();
    pageOpener ??= context.findAncestorStateOfType<_MasterDetailFlowState>();
    assert(() {
      if (pageOpener == null && !nullOk) {
        throw FlutterError(
            'Master Detail operation requested with a context that does not include a Master Detail'
            ' Flow.\nThe context used to open a detail page from the Master Detail Flow must be'
            ' that of a widget that is a descendant of a Master Detail Flow widget.');
      }
      return true;
    }());
    return pageOpener != null ? _MasterDetailFlowProxy._(pageOpener) : null;
  }
}

/// Interface for interacting with the [_MasterDetailFlow].
class _MasterDetailFlowProxy implements _PageOpener {
  _MasterDetailFlowProxy._(this._pageOpener);

  final _PageOpener _pageOpener;

  /// Open detail page with arguments.
  @override
  void openDetailPage(Object arguments) =>
      _pageOpener.openDetailPage(arguments);

  /// Set the initial page to be open for the lateral layout. This can be set at any time, but
  /// will have no effect after any calls to openDetailPage.
  @override
  void setInitialDetailPage(Object arguments) =>
      _pageOpener.setInitialDetailPage(arguments);
}

abstract class _PageOpener {
  void openDetailPage(Object arguments);

  void setInitialDetailPage(Object arguments);
}

const int _materialWideDisplayThreshold = 840;

class _MasterDetailFlowState extends State<_MasterDetailFlow>
    implements _PageOpener {
  /// Tracks whether focus is on the detail or master views. Determines behavior when switching
  /// from lateral to nested navigation.
  _Focus focus = _Focus.master;

  /// Cache of arguments passed when opening a detail page. Used when rebuilding.
  Object? _cachedDetailArguments;

  /// Record of the layout that was built.
  _LayoutMode? _builtLayout;

  /// Key to access navigator in the nested layout.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void openDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
    if (_builtLayout == _LayoutMode.nested) {
      _navigatorKey.currentState!.pushNamed(_navDetail, arguments: arguments);
    } else {
      focus = _Focus.detail;
    }
  }

  @override
  void setInitialDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayMode) {
      case _LayoutMode.nested:
        return _nestedUI(context);
      case _LayoutMode.lateral:
        return _lateralUI(context);
      case _LayoutMode.auto:
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          if (availableWidth >=
              (widget.breakpoint ?? _materialWideDisplayThreshold)) {
            return _lateralUI(context);
          } else {
            return _nestedUI(context);
          }
        });
    }
  }

  Widget _nestedUI(BuildContext context) {
    _builtLayout = _LayoutMode.nested;
    final masterPageRoute = _masterPageRoute(context);

    return WillPopScope(
      // Push pop check into nested navigator.
      onWillPop: () async => !(await _navigatorKey.currentState!.maybePop()),
      child: Navigator(
        key: _navigatorKey,
        initialRoute: 'initial',
        onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
          switch (focus) {
            case _Focus.master:
              return <Route<void>>[masterPageRoute];
            case _Focus.detail:
              return <Route<void>>[
                masterPageRoute,
                _detailPageRoute(_cachedDetailArguments)
              ];
          }
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case _navMaster:
              // Matching state to navigation event.
              focus = _Focus.master;
              return masterPageRoute;
            case _navDetail:
              // Matching state to navigation event.
              focus = _Focus.detail;
              // Cache detail page settings.
              _cachedDetailArguments = settings.arguments;
              return _detailPageRoute(_cachedDetailArguments);
            default:
              throw Exception('Unknown route ${settings.name}');
          }
        },
      ),
    );
  }

  PageRouteBuilder _masterPageRoute(BuildContext context) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Builder(
        builder: (BuildContext c) => BlockSemantics(
          child: widget.masterPageBuilder != null
              ? widget.masterPageBuilder!(c, false)
              : _MasterPage(
                  leading: widget.leading ??
                      (widget.automaticallyImplyLeading &&
                              Navigator.of(context).canPop()
                          ? NFBackButton(
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          : null),
                  title: widget.title,
                  centerTitle: widget.centerTitle,
                  flexibleSpace: widget.flexibleSpace,
                  automaticallyImplyLeading: widget.automaticallyImplyLeading,
                  floatingActionButton: widget.floatingActionButton,
                  floatingActionButtonLocation: widget.floatingActionButtonMasterPageLocation,
                  masterViewBuilder: widget.masterViewBuilder,
                  actionBuilder: widget.actionBuilder,
                ),
        ),
      ),
    );
  }

  StackFadeRouteTransition _detailPageRoute(Object? arguments) {
    return StackFadeRouteTransition(
      transitionSettings: AppRouter.instance.transitionSettings.dismissible,
      child: Builder(
        builder: (BuildContext context) {
          return NFBackButtonListener(
            onBackButtonPressed: () async {
              // No need for setState() as rebuild happens on navigation pop.
              focus = _Focus.master;
              return Navigator.of(context).maybePop();
            },
            child: BlockSemantics(
              child: widget.detailPageBuilder(context, arguments, null),
            ),
          );
        },
      ),
    );
  }

  Widget _lateralUI(BuildContext context) {
    _builtLayout = _LayoutMode.lateral;
    return _MasterDetailScaffold(
      actionBuilder: widget.actionBuilder ?? (_, __) => const <Widget>[],
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      centerTitle: widget.centerTitle,
      detailPageBuilder: (BuildContext context, Object? args,
              ScrollController? scrollController) =>
          widget.detailPageBuilder(
              context, args ?? _cachedDetailArguments, scrollController),
      floatingActionButton: widget.floatingActionButton,
      detailPageFABlessGutterWidth: widget.detailPageFABlessGutterWidth,
      detailPageFABGutterWidth: widget.detailPageFABGutterWidth,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      initialArguments: _cachedDetailArguments,
      leading: widget.leading,
      masterViewBuilder: (BuildContext context, bool isLateral) =>
          widget.masterViewBuilder(context, isLateral),
      masterViewWidth: widget.masterViewWidth,
      title: widget.title,
    );
  }
}

class _MasterPage extends StatelessWidget {
  const _MasterPage({
    Key? key,
    this.leading,
    this.title,
    this.actionBuilder,
    this.centerTitle,
    this.flexibleSpace,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.masterViewBuilder,
    required this.automaticallyImplyLeading,
  }) : super(key: key);

  final _MasterViewBuilder? masterViewBuilder;
  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final Widget? flexibleSpace;
  final _ActionBuilder? actionBuilder;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: leading,
        actions: actionBuilder == null
            ? const <Widget>[]
            : actionBuilder!(context, _ActionLevel.composite),
        centerTitle: centerTitle,
        flexibleSpace: flexibleSpace,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: masterViewBuilder!(context, false),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

const double _kCardElevation = 4.0;
const double _kMasterViewWidth = 320.0;
const double _kDetailPageFABlessGutterWidth = 40.0;
const double _kDetailPageFABGutterWidth = 84.0;

class _MasterDetailScaffold extends StatefulWidget {
  const _MasterDetailScaffold({
    Key? key,
    required this.detailPageBuilder,
    required this.masterViewBuilder,
    this.actionBuilder,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.initialArguments,
    this.leading,
    this.title,
    required this.automaticallyImplyLeading,
    this.centerTitle,
    this.detailPageFABlessGutterWidth,
    this.detailPageFABGutterWidth,
    this.masterViewWidth,
  }) : super(key: key);

  final _MasterViewBuilder masterViewBuilder;

  /// Builder for the detail page.
  ///
  /// The detail page is inside a [DraggableScrollableSheet] and should have a scrollable element
  /// that uses the [ScrollController] provided. In fact, it is strongly recommended the entire
  /// lateral page is scrollable.
  final _DetailPageBuilder detailPageBuilder;
  final _ActionBuilder? actionBuilder;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Object? initialArguments;
  final Widget? leading;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final double? detailPageFABlessGutterWidth;
  final double? detailPageFABGutterWidth;
  final double? masterViewWidth;

  @override
  _MasterDetailScaffoldState createState() => _MasterDetailScaffoldState();
}

class _MasterDetailScaffoldState extends State<_MasterDetailScaffold>
    implements _PageOpener {
  late FloatingActionButtonLocation floatingActionButtonLocation;
  late double detailPageFABGutterWidth;
  late double detailPageFABlessGutterWidth;
  late double masterViewWidth;

  final ValueNotifier<Object?> _detailArguments = ValueNotifier<Object?>(null);

  @override
  void initState() {
    super.initState();
    detailPageFABlessGutterWidth =
        widget.detailPageFABlessGutterWidth ?? _kDetailPageFABlessGutterWidth;
    detailPageFABGutterWidth =
        widget.detailPageFABGutterWidth ?? _kDetailPageFABGutterWidth;
    masterViewWidth = widget.masterViewWidth ?? _kMasterViewWidth;
    floatingActionButtonLocation = widget.floatingActionButtonLocation ??
        FloatingActionButtonLocation.endTop;
  }

  @override
  void openDetailPage(Object arguments) {
    SchedulerBinding.instance!.addPostFrameCallback((_) => _detailArguments.value = arguments);
    _MasterDetailFlow.of(context)!.openDetailPage(arguments);
  }

  @override
  void setInitialDetailPage(Object arguments) {
    SchedulerBinding.instance!.addPostFrameCallback((_) => _detailArguments.value = arguments);
    _MasterDetailFlow.of(context)!.setInitialDetailPage(arguments);
  }

  String? lastPackageName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          floatingActionButtonLocation: floatingActionButtonLocation,
          body: _masterPanel(context),
          floatingActionButton: widget.floatingActionButton,
          appBar: AppBar(
            titleSpacing: 0.0,
            elevation: 2.0,
            title: widget.title,
            actions: widget.actionBuilder!(context, _ActionLevel.top),
            leading: widget.leading,
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            centerTitle: widget.centerTitle,
            // bottom: PreferredSize(
            //   preferredSize: const Size.fromHeight(kToolbarHeight),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children: <Widget>[
            //       ConstrainedBox(
            //         constraints:
            //             BoxConstraints.tightFor(width: masterViewWidth),
            //         child: IconTheme(
            //           data: Theme.of(context).primaryIconTheme,
            //           child: ButtonBar(
            //             children:
            //                 widget.actionBuilder!(context, _ActionLevel.view),
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            // ),
          ),
        ),
        // Detail view stacked above main scaffold and master view.
        SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: masterViewWidth - _kCardElevation,
              end: widget.floatingActionButton == null
                  ? detailPageFABlessGutterWidth
                  : detailPageFABGutterWidth,
            ),
            child: ValueListenableBuilder<Object?>(
              valueListenable: _detailArguments,
              builder: (BuildContext context, Object? value, Widget? child) {
                bool reverse = false;
                if (lastPackageName != null) {
                  final compare = (value as _DetailArguments?)
                      ?.packageName
                      .compareTo(lastPackageName!);
                  if (compare != null) {
                    reverse = compare < 0;
                  }
                }
                lastPackageName = (value as _DetailArguments?)?.packageName;
                return PageTransitionSwitcher(
                  reverse: reverse,
                  transitionBuilder: (child, animation, secondaryAnimation) =>
                      SharedAxisTransition(
                    transitionType: SharedAxisTransitionType.vertical,
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    fillColor: Colors.transparent,
                    child: child,
                  ),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    key: ValueKey<Object?>(value ?? widget.initialArguments),
                    constraints: const BoxConstraints.expand(),
                    child: _DetailView(
                      builder: widget.detailPageBuilder,
                      arguments: value ?? widget.initialArguments,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  ConstrainedBox _masterPanel(BuildContext context,
      {bool needsScaffold = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: masterViewWidth),
      child: needsScaffold
          ? Scaffold(
              backgroundColor: Colors.red,
              body: widget.masterViewBuilder(context, true),
              appBar: AppBar(
                titleSpacing: 0.0,
                elevation: 2.0,
                title: widget.title,
                actions: widget.actionBuilder!(context, _ActionLevel.top),
                leading: widget.leading,
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                centerTitle: widget.centerTitle,
              ),
            )
          : widget.masterViewBuilder(context, true),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    Key? key,
    required _DetailPageBuilder builder,
    Object? arguments,
  }) : _builder = builder,
       _arguments = arguments,
       super(key: key);

  final _DetailPageBuilder _builder;
  final Object? _arguments;

  @override
  Widget build(BuildContext context) {
    if (_arguments == null) {
      return Container();
    }
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = (screenHeight - kToolbarHeight) / screenHeight;

    return DraggableScrollableSheet(
      initialChildSize: minHeight,
      minChildSize: minHeight,
      maxChildSize: 1,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return MouseRegion(
          child: Card(
            color: ThemeControl.theme.colorScheme.secondary,
            elevation: _kCardElevation,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.fromLTRB(
              _kCardElevation,
              0.0,
              _kCardElevation,
              0.0,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(3.0), bottom: Radius.zero),
            ),
            child: _builder(
              context,
              _arguments,
              controller,
            ),
          ),
        );
      },
    );
  }
}
