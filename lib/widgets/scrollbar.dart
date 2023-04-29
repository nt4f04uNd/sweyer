/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// ###########################################################################################
/// copied this from flutter https://github.com/flutter/flutter/commit/02efffc134
/// ###########################################################################################

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'package:sweyer/sweyer.dart';

const double _kScrollbarThickness = 8.0;
const double _kScrollbarThicknessWithTrack = 12.0;
const double _kScrollbarMargin = 2.0;
const double _kScrollbarMinLength = 48.0;
const Radius _kScrollbarRadius = Radius.circular(8.0);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// Themed app scrollbar.
class AppScrollbar extends StatefulWidget {
  /// Creates a scrollbar, draggable by default.
  const AppScrollbar({
    Key? key,
    this.labelBuilder,
    required this.child,
    this.controller,
    this.thumbVisibility,
    this.showTrackOnHover,
    this.hoverThickness,
    this.thickness,
    this.radius,
    this.notificationPredicate,
    this.interactive = true,
  }) : super(key: key);

  /// Creates a scrollbar, draggable by default.
  /// Automatically passes [labelBuilder] dependent on content type `T` and
  /// uses passed content [list] in it.
  ///
  /// It is also possible to disable the label with [showLabel].
  @factory
  static AppScrollbar forContent<T extends Content>({
    Key? key,
    required ContentType<T> contentType,
    required List<T> list,
    required Widget child,
    required ScrollController controller,
    bool showLabel = true,
    bool? isAlwaysShown,
    bool? showTrackOnHover,
    double? hoverThickness,
    double? thickness,
    Radius? radius,
    ScrollNotificationPredicate? notificationPredicate,
    bool? interactive,
  }) {
    return AppScrollbar(
      key: key,
      labelBuilder: !showLabel
          ? null
          : (context) {
              final l10n = getl10n(context);
              final item =
                  list[(controller.position.pixels / kSongTileHeight(context) - 1).clamp(0.0, list.length - 1).round()];
              return NFScrollLabel(text: () {
                // TODO: Remove ContentType cast, see https://github.com/dart-lang/language/issues/2315
                // ignore: unnecessary_cast
                switch (contentType as ContentType) {
                  case ContentType.song:
                    return (item as Song).title[0].toUpperCase();
                  case ContentType.album:
                    return (item as Album).album[0].toUpperCase();
                  case ContentType.playlist:
                    return (item as Playlist).name[0].toUpperCase();
                  case ContentType.artist:
                    return ContentUtils.localizedArtist((item as Artist).artist, l10n)[0].toUpperCase();
                }
              }());
            },
      controller: controller,
      thumbVisibility: isAlwaysShown,
      showTrackOnHover: showTrackOnHover,
      hoverThickness: hoverThickness,
      thickness: thickness,
      radius: radius,
      notificationPredicate: notificationPredicate,
      interactive: interactive,
      child: child,
    );
  }

  final WidgetBuilder? labelBuilder;
  final Widget child;
  final ScrollController? controller;
  final bool? thumbVisibility;
  final bool? showTrackOnHover;
  final double? hoverThickness;
  final double? thickness;
  final Radius? radius;
  final ScrollNotificationPredicate? notificationPredicate;
  final bool? interactive;

  @override
  _AppScrollbarState createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  bool _dragIsActive = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? PrimaryScrollController.of(context);
    final theme = Theme.of(context);
    final highlightColor = theme.highlightColor;
    return Theme(
      data: theme.copyWith(
        highlightColor: ThemeControl.instance.isDark ? const Color(0x40CCCCCC) : const Color(0x66BCBCBC),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Stack(
          children: [
            _Scrollbar(
              controller: controller,
              thumbVisibility: widget.thumbVisibility,
              showTrackOnHover: widget.showTrackOnHover,
              hoverThickness: widget.hoverThickness,
              thickness: widget.thickness,
              radius: widget.radius,
              notificationPredicate: widget.notificationPredicate,
              interactive: widget.interactive,
              onThumbPressStart: () => setState(() {
                _dragIsActive = true;
              }),
              onThumbPressEnd: () => setState(() {
                _dragIsActive = false;
              }),
              child: Theme(
                data: theme.copyWith(highlightColor: highlightColor),
                child: widget.child,
              ),
            ),
            if (widget.labelBuilder != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: !_dragIsActive
                    ? const SizedBox.shrink()
                    : Center(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) => widget.labelBuilder!(context),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A Material Design scrollbar.
///
/// To add a scrollbar to a [ScrollView], wrap the scroll view
/// widget in a [Scrollbar] widget.
///
/// {@macro flutter.widgets.Scrollbar}
///
/// Dynamically changes to an iOS style scrollbar that looks like
/// [CupertinoScrollbar] on the iOS platform.
///
/// The color of the Scrollbar will change when dragged. A hover animation is
/// also triggered when used on web and desktop platforms. A scrollbar track
/// can also been drawn when triggered by a hover event, which is controlled by
/// [showTrackOnHover]. The thickness of the track and scrollbar thumb will
/// become larger when hovering, unless overridden by [hoverThickness].
///
/// {@tool dartpad --template=stateless_widget_scaffold}
/// This sample shows a [Scrollbar] that executes a fade animation as scrolling occurs.
/// The Scrollbar will fade into view as the user scrolls, and fade out when scrolling stops.
/// ```dart
/// Widget build(BuildContext context) {
///   return Scrollbar(
///     child: GridView.builder(
///       itemCount: 120,
///       gridDelegate:
///         const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
///       itemBuilder: (BuildContext context, int index) {
///         return Center(
///           child: Text('item $index'),
///         );
///       },
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_scaffold}
/// When isAlwaysShown is true, the scrollbar thumb will remain visible without the
/// fade animation. This requires that a ScrollController is provided to controller,
/// or that the PrimaryScrollController is available.
/// ```dart
/// final ScrollController _controllerOne = ScrollController();
///
/// @override
/// Widget build(BuildContext context) {
///   return Scrollbar(
///     controller: _controllerOne,
///     isAlwaysShown: true,
///     child: GridView.builder(
///       controller: _controllerOne,
///       itemCount: 120,
///       gridDelegate:
///         const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
///       itemBuilder: (BuildContext context, int index) {
///         return Center(
///           child: Text('item $index'),
///         );
///       },
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RawScrollbar], a basic scrollbar that fades in and out, extended
///    by this class to add more animations and behaviors.
///  * [ScrollbarTheme], which configures the Scrollbar's appearance.
///  * [CupertinoScrollbar], an iOS style scrollbar.
///  * [ListView], which displays a linear, scrollable list of children.
///  * [GridView], which displays a 2 dimensional, scrollable array of children.
class _Scrollbar extends StatefulWidget {
  /// Creates a material design scrollbar that by default will connect to the
  /// closest Scrollable descendant of [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  ///
  /// If the [controller] is null, the default behavior is to
  /// enable scrollbar dragging using the [PrimaryScrollController].
  ///
  /// When null, [thickness] defaults to 8.0 pixels on desktop and web, and 4.0
  /// pixels when on mobile platforms. A null [radius] will result in a default
  /// of an 8.0 pixel circular radius about the corners of the scrollbar thumb,
  /// except for when executing on [TargetPlatform.android], which will render the
  /// thumb without a radius.
  const _Scrollbar({
    Key? key,
    required this.child,
    this.controller,
    this.thumbVisibility,
    this.showTrackOnHover,
    this.hoverThickness,
    this.thickness,
    this.radius,
    this.notificationPredicate,
    this.interactive,
    this.onThumbPressStart,
    this.onThumbPressEnd,
  }) : super(key: key);

  /// {@macro flutter.widgets.Scrollbar.child}
  final Widget child;

  /// {@macro flutter.widgets.Scrollbar.controller}
  final ScrollController? controller;

  /// {@macro flutter.widgets.Scrollbar.thumbVisibility}
  final bool? thumbVisibility;

  /// Controls if the track will show on hover and remain, including during drag.
  ///
  /// If this property is null, then [ScrollbarThemeData.trackVisibility] of
  /// [ThemeData.scrollbarTheme] is used. If that is also null, the default value
  /// is false.
  final bool? showTrackOnHover;

  /// The thickness of the scrollbar when a hover state is active and
  /// [showTrackOnHover] is true.
  ///
  /// If this property is null, then [ScrollbarThemeData.thickness] of
  /// [ThemeData.scrollbarTheme] is used to resolve a thickness. If that is also
  /// null, the default value is 12.0 pixels.
  final double? hoverThickness;

  /// The thickness of the scrollbar in the cross axis of the scrollable.
  ///
  /// If null, the default value is platform dependent. On [TargetPlatform.android],
  /// the default thickness is 4.0 pixels. On [TargetPlatform.iOS],
  /// [CupertinoScrollbar.defaultThickness] is used. The remaining platforms have a
  /// default thickness of 8.0 pixels.
  final double? thickness;

  /// The [Radius] of the scrollbar thumb's rounded rectangle corners.
  ///
  /// If null, the default value is platform dependent. On [TargetPlatform.android],
  /// no radius is applied to the scrollbar thumb. On [TargetPlatform.iOS],
  /// [CupertinoScrollbar.defaultRadius] is used. The remaining platforms have a
  /// default [Radius.circular] of 8.0 pixels.
  final Radius? radius;

  /// {@macro flutter.widgets.Scrollbar.interactive}
  final bool? interactive;

  /// {@macro flutter.widgets.Scrollbar.notificationPredicate}
  final ScrollNotificationPredicate? notificationPredicate;

  final VoidCallback? onThumbPressStart;
  final VoidCallback? onThumbPressEnd;

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends State<_Scrollbar> {
  bool get _useCupertinoScrollbar => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (_useCupertinoScrollbar) {
      return CupertinoScrollbar(
        child: widget.child,
        thumbVisibility: widget.thumbVisibility ?? false,
        thickness: widget.thickness ?? CupertinoScrollbar.defaultThickness,
        thicknessWhileDragging: widget.thickness ?? CupertinoScrollbar.defaultThicknessWhileDragging,
        radius: widget.radius ?? CupertinoScrollbar.defaultRadius,
        radiusWhileDragging: widget.radius ?? CupertinoScrollbar.defaultRadiusWhileDragging,
        controller: widget.controller,
        notificationPredicate: widget.notificationPredicate,
      );
    }
    return _MaterialScrollbar(
      child: widget.child,
      controller: widget.controller,
      thumbVisibility: widget.thumbVisibility,
      showTrackOnHover: widget.showTrackOnHover,
      hoverThickness: widget.hoverThickness,
      thickness: widget.thickness,
      radius: widget.radius,
      notificationPredicate: widget.notificationPredicate,
      interactive: widget.interactive,
      onThumbPressStart: widget.onThumbPressStart,
      onThumbPressEnd: widget.onThumbPressEnd,
    );
  }
}

class _MaterialScrollbar extends RawScrollbar {
  const _MaterialScrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool? thumbVisibility,
    this.showTrackOnHover,
    this.hoverThickness,
    double? thickness,
    Radius? radius,
    ScrollNotificationPredicate? notificationPredicate,
    bool? interactive,
    this.onThumbPressStart,
    this.onThumbPressEnd,
  }) : super(
          key: key,
          child: child,
          controller: controller,
          thumbVisibility: thumbVisibility,
          thickness: thickness,
          radius: radius,
          fadeDuration: _kScrollbarFadeDuration,
          timeToFade: _kScrollbarTimeToFade,
          pressDuration: Duration.zero,
          notificationPredicate: notificationPredicate ?? defaultScrollNotificationPredicate,
          interactive: interactive,
        );

  final bool? showTrackOnHover;
  final double? hoverThickness;
  final VoidCallback? onThumbPressStart;
  final VoidCallback? onThumbPressEnd;

  @override
  _MaterialScrollbarState createState() => _MaterialScrollbarState();
}

class _MaterialScrollbarState extends RawScrollbarState<_MaterialScrollbar> {
  late AnimationController _hoverAnimationController;
  bool _dragIsActive = false;
  bool _hoverIsActive = false;
  late ColorScheme _colorScheme;
  late ScrollbarThemeData _scrollbarTheme;
  // On Android, scrollbars should match native appearance.
  late bool _useAndroidScrollbar;

  @override
  bool get showScrollbar => widget.thumbVisibility ?? _scrollbarTheme.thumbVisibility?.resolve(_states) ?? false;

  @override
  bool get enableGestures => widget.interactive ?? _scrollbarTheme.interactive ?? !_useAndroidScrollbar;

  bool get _showTrackOnHover => widget.showTrackOnHover ?? _scrollbarTheme.trackVisibility?.resolve(_states) ?? false;

  Set<MaterialState> get _states => <MaterialState>{
        if (_dragIsActive) MaterialState.dragged,
        if (_hoverIsActive) MaterialState.hovered,
      };

  MaterialStateProperty<Color> get _thumbColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    late Color dragColor;
    late Color hoverColor;
    late Color idleColor;
    switch (brightness) {
      case Brightness.light:
        dragColor = onSurface.withOpacity(0.6);
        hoverColor = onSurface.withOpacity(0.5);
        idleColor =
            _useAndroidScrollbar ? Theme.of(context).highlightColor.withOpacity(1.0) : onSurface.withOpacity(0.1);
        break;
      case Brightness.dark:
        dragColor = onSurface.withOpacity(0.75);
        hoverColor = onSurface.withOpacity(0.65);
        idleColor =
            _useAndroidScrollbar ? Theme.of(context).highlightColor.withOpacity(1.0) : onSurface.withOpacity(0.3);
        break;
    }

    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.dragged)) {
        return _scrollbarTheme.thumbColor?.resolve(states) ?? dragColor;
      }

      // If the track is visible, the thumb color hover animation is ignored and
      // changes immediately.
      if (states.contains(MaterialState.hovered) && _showTrackOnHover) {
        return _scrollbarTheme.thumbColor?.resolve(states) ?? hoverColor;
      }

      return Color.lerp(
        _scrollbarTheme.thumbColor?.resolve(states) ?? idleColor,
        _scrollbarTheme.thumbColor?.resolve(states) ?? hoverColor,
        _hoverAnimationController.value,
      )!;
    });
  }

  MaterialStateProperty<Color> get _trackColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && _showTrackOnHover) {
        return _scrollbarTheme.trackColor?.resolve(states) ??
            (brightness == Brightness.light ? onSurface.withOpacity(0.03) : onSurface.withOpacity(0.05));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackBorderColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && _showTrackOnHover) {
        return _scrollbarTheme.trackBorderColor?.resolve(states) ??
            (brightness == Brightness.light ? onSurface.withOpacity(0.1) : onSurface.withOpacity(0.25));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<double> get _thickness {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && _showTrackOnHover) {
        return widget.hoverThickness ?? _scrollbarTheme.thickness?.resolve(states) ?? _kScrollbarThicknessWithTrack;
      }
      // The default scrollbar thickness is smaller on mobile.
      return widget.thickness ??
          _scrollbarTheme.thickness?.resolve(states) ??
          (_kScrollbarThickness / (_useAndroidScrollbar ? 2 : 1));
    });
  }

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnimationController.addListener(() {
      updateScrollbarPainter();
    });
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _colorScheme = theme.colorScheme;
    _scrollbarTheme = theme.scrollbarTheme;
    switch (theme.platform) {
      case TargetPlatform.android:
        _useAndroidScrollbar = true;
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        _useAndroidScrollbar = false;
        break;
    }
    super.didChangeDependencies();
  }

  @override
  void updateScrollbarPainter() {
    scrollbarPainter
      ..color = _thumbColor.resolve(_states)
      ..trackColor = _trackColor.resolve(_states)
      ..trackBorderColor = _trackBorderColor.resolve(_states)
      ..textDirection = Directionality.of(context)
      ..thickness = _thickness.resolve(_states)
      ..radius = widget.radius ?? _scrollbarTheme.radius ?? (_useAndroidScrollbar ? null : _kScrollbarRadius)
      ..crossAxisMargin = _scrollbarTheme.crossAxisMargin ?? (_useAndroidScrollbar ? 0.0 : _kScrollbarMargin)
      ..mainAxisMargin = _scrollbarTheme.mainAxisMargin ?? 0.0
      ..minLength = _scrollbarTheme.minThumbLength ?? _kScrollbarMinLength
      ..padding = MediaQuery.of(context).padding;
  }

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    setState(() {
      _dragIsActive = true;
    });
    widget.onThumbPressStart?.call();
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    super.handleThumbPressEnd(localPosition, velocity);
    setState(() {
      _dragIsActive = false;
    });
    widget.onThumbPressEnd?.call();
  }

  @override
  void handleHover(PointerHoverEvent event) {
    super.handleHover(event);
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbar(event.position, event.kind)) {
      // Pointer is hovering over the scrollbar
      setState(() {
        _hoverIsActive = true;
      });
      _hoverAnimationController.forward();
    } else if (_hoverIsActive) {
      // Pointer was, but is no longer over painted scrollbar.
      setState(() {
        _hoverIsActive = false;
      });
      _hoverAnimationController.reverse();
    }
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    setState(() {
      _hoverIsActive = false;
    });
    _hoverAnimationController.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }
}
