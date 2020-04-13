/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.

*  Copyright (c) Draggable Scrollbar Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

const _kSMMScrollBarHeight = 40.0;

/// SMM default styled draggable scrollbar
///
/// If current sort feature is [SortFeature.title], will have a scroll label and will be always visible
///
/// NOTE Can't be applied from [ScrollablePositionedList], because this list doesn't have a consistent scroll controller
///
/// TODO: add scrollbar pad with letters
class SMMDefaultDraggableScrollbar extends StatelessWidget {
  SMMDefaultDraggableScrollbar({
    Key key,
    this.scrollThumbKey,
    @required this.child,
    @required this.controller,
    this.labelContentBuilder,
    this.alwaysVisibleScrollThumb = false,
  })  : assert(child != null),
        assert(controller != null),
        super(key: key);

  final Widget child;
  final Key scrollThumbKey;
  final Widget Function(double) labelContentBuilder;
  final ScrollController controller;
  final bool alwaysVisibleScrollThumb;

  @override
  Widget build(BuildContext context) {
    return SMMDraggableScrollbar.rrect(
      alwaysVisibleScrollThumb:
         alwaysVisibleScrollThumb,
      scrollThumbKey: scrollThumbKey,
      padding: const EdgeInsets.only(right: 3.0),
      // labelConstraints: const BoxConstraints(maxWidth: 56.0, maxHeight: 24.0),
      labelConstraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 28.0, maxHeight: 36.0),
      labelContentBuilder:
         labelContentBuilder,
      marginTop: 7.0,
      marginBottom: 40.0,
      widthScrollThumb: 12.0,
      backgroundColor:  Constants.AppTheme.menuItem.auto(context),
      controller: controller,
      child: child,
    );
  }
}

//****************** Scrollbar copied from the flutter *****************************************************

const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [Scrollbar] widget.
///
class SMMScrollbar extends StatefulWidget {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const SMMScrollbar({
    Key key,
    @required this.child,
    this.color,
    this.thickness = _kScrollbarThickness,
    this.padding = EdgeInsets.zero,
    this.mainAxisMargin = 8.0,
    this.crossAxisMargin = 2.0,
    this.radius = const Radius.circular(8.0),
    this.minLength = _kSMMScrollBarHeight,
    this.minOverscrollLength,
    this.controller,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// The scrollbar will be stacked on top of this child. This child (and its
  /// subtree) should include a source of [ScrollNotification] notifications.
  ///
  /// Typically a [ListView] or [CustomScrollView].
  final Widget child;

  /// These are just properties from the [ScrollbarPainter]
  final Color color;
  final double thickness;
  final EdgeInsets padding;
  final double mainAxisMargin;
  final double crossAxisMargin;
  final Radius radius;
  final double minLength;
  final double minOverscrollLength;

  final ScrollController controller;

  @override
  _SMMScrollbarState createState() => _SMMScrollbarState();
}

class _SMMScrollbarState extends State<SMMScrollbar>
    with TickerProviderStateMixin {
  ScrollbarPainter _scrollbarPainter;
  TextDirection _textDirection;
  Color _themeColor;
  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  Timer _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _themeColor = theme.colorScheme.primary;
        _textDirection = Directionality.of(context);
        _scrollbarPainter = _buildScrollbarPainter();
        break;
    }
  }

  ScrollbarPainter _buildScrollbarPainter() {
    return ScrollbarPainter(
      color: widget.color ?? _themeColor,
      thickness: widget.thickness ?? _kScrollbarThickness,
      padding: widget.padding,
      mainAxisMargin: widget.mainAxisMargin,
      crossAxisMargin: widget.crossAxisMargin,
      radius: widget.radius,
      minLength: widget.minLength,
      minOverscrollLength: widget.minOverscrollLength,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      textDirection: _textDirection,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }

    // iOS sub-delegates to the CupertinoScrollbar instead and doesn't handle
    // scroll notifications here.
    if ((notification is ScrollUpdateNotification ||
        notification is OverscrollNotification)) {
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }

      _scrollbarPainter.update(
          notification.metrics, notification.metrics.axisDirection);
      _fadeoutTimer?.cancel();
      _fadeoutTimer = Timer(_kScrollbarTimeToFade, () {
        _fadeoutAnimationController.reverse();
        _fadeoutTimer = null;
      });
    }
    return false;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    _scrollbarPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: CustomPaint(
          foregroundPainter: _scrollbarPainter,
          child: RepaintBoundary(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

//***************************************** Draggable  scrollbar ******************************************

/// Build the Scroll Thumb and label using the current configuration
typedef Widget ScrollThumbBuilder(
  Color backgroundColor,
  Animation<double> thumbAnimation,
  Animation<double> labelAnimation,
  double height,
  double width,
  bool shouldAppear, {
  Widget labelContent,
  BoxConstraints labelConstraints,
});

/// Build a Text widget using the current scroll offset
typedef Widget LabelContentBuilder(double offsetY);

/// A widget that will display a BoxScrollView with a ScrollThumb that can be dragged
/// for quick navigation of the BoxScrollView.
///
/// TODO: add initial scroll offset
class SMMDraggableScrollbar extends StatefulWidget {
  /// The view that will be scrolled with the scroll thumb
  final Widget child;

  /// A function that builds a thumb using the current configuration
  final ScrollThumbBuilder scrollThumbBuilder;

  /// The height of the scroll thumb
  final double heightScrollThumb;

  /// The width of the scroll thumb
  final double widthScrollThumb;

  /// Margin for thumb from top
  final double marginBottom;

  /// Margin for thumb from bottom
  final double marginTop;

  /// The background color of the label and thumb
  final Color backgroundColor;

  /// The amount of padding that should surround the thumb
  final EdgeInsetsGeometry padding;

  /// Determines how quickly the scrollbar will animate in and out
  final Duration scrollbarAnimationDuration;

  /// How long should the thumb be visible before fading out
  final Duration scrollbarTimeToFade;

  /// Build a Widget from the current offset in the BoxScrollView
  final LabelContentBuilder labelContentBuilder;

  /// Determines box constraints for Container displaying label
  final BoxConstraints labelConstraints;

  /// The ScrollController for the BoxScrollView
  final ScrollController controller;

  /// Determines scrollThumb displaying. If you draw own ScrollThumb and it is true you just don't need to use animation parameters in [scrollThumbBuilder]
  final bool alwaysVisibleScrollThumb;

  SMMDraggableScrollbar({
    Key key,
    this.alwaysVisibleScrollThumb = false,
    @required this.heightScrollThumb,
    @required this.backgroundColor,
    @required this.scrollThumbBuilder,
    @required this.child,
    @required this.controller,
    this.widthScrollThumb,
    this.marginBottom = 0.0,
    this.marginTop = 0.0,
    this.padding,
    this.scrollbarAnimationDuration = _kScrollbarFadeDuration,
    this.scrollbarTimeToFade = _kScrollbarTimeToFade,
    this.labelContentBuilder,
    this.labelConstraints,
  })  : assert(controller != null),
        assert(scrollThumbBuilder != null),
        super(key: key);

  SMMDraggableScrollbar.rrect({
    Key key,
    Key scrollThumbKey,
    this.alwaysVisibleScrollThumb = false,
    @required this.child,
    @required this.controller,
    this.heightScrollThumb = 48.0,
    this.widthScrollThumb = 16.0,
    this.marginBottom = 0.0,
    this.marginTop = 0.0,
    this.backgroundColor = Colors.white,
    this.padding,
    this.scrollbarAnimationDuration = _kScrollbarFadeDuration,
    this.scrollbarTimeToFade = _kScrollbarTimeToFade,
    this.labelContentBuilder,
    this.labelConstraints,
  })  : scrollThumbBuilder =
            _thumbRRectBuilder(scrollThumbKey, alwaysVisibleScrollThumb),
        super(key: key);

  SMMDraggableScrollbar.arrows({
    Key key,
    Key scrollThumbKey,
    this.alwaysVisibleScrollThumb = false,
    @required this.child,
    @required this.controller,
    this.heightScrollThumb = 48.0,
    this.widthScrollThumb = 20.0,
    this.marginBottom = 0.0,
    this.marginTop = 0.0,
    this.backgroundColor = Colors.white,
    this.padding,
    this.scrollbarAnimationDuration = _kScrollbarFadeDuration,
    this.scrollbarTimeToFade = _kScrollbarTimeToFade,
    this.labelContentBuilder,
    this.labelConstraints,
  })  : scrollThumbBuilder =
            _thumbArrowBuilder(scrollThumbKey, alwaysVisibleScrollThumb),
        super(key: key);

  SMMDraggableScrollbar.semicircle({
    Key key,
    Key scrollThumbKey,
    this.alwaysVisibleScrollThumb = false,
    @required this.child,
    @required this.controller,
    this.heightScrollThumb = 48.0,
    this.widthScrollThumb,
    this.marginBottom = 0.0,
    this.marginTop = 0.0,
    this.backgroundColor = Colors.white,
    this.padding,
    this.scrollbarAnimationDuration = _kScrollbarFadeDuration,
    this.scrollbarTimeToFade = _kScrollbarTimeToFade,
    this.labelContentBuilder,
    this.labelConstraints,
  })  : scrollThumbBuilder =
            _thumbSemicircleBuilder(scrollThumbKey, alwaysVisibleScrollThumb),
        super(key: key);

  @override
  _SMMDraggableScrollbarState createState() => _SMMDraggableScrollbarState();

  static buildScrollThumbAndLabel({
    @required Widget scrollThumb,
    @required Color backgroundColor,
    @required Animation<double> thumbAnimation,
    @required Animation<double> labelAnimation,
    @required Widget labelContent,
    @required BoxConstraints labelConstraints,
    @required bool alwaysVisibleScrollThumb,
  }) {
    var scrollThumbAndLabel = labelContent == null
        ? scrollThumb
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ScrollLabel(
                animation: labelAnimation,
                child: labelContent,
                backgroundColor: backgroundColor,
                constraints: labelConstraints,
              ),
              scrollThumb,
            ],
          );

    if (alwaysVisibleScrollThumb) {
      return scrollThumbAndLabel;
    }
    return SlideFadeTransition(
      animation: thumbAnimation,
      child: scrollThumbAndLabel,
    );
  }

  static ScrollThumbBuilder _thumbSemicircleBuilder(
      Key scrollThumbKey, bool alwaysVisibleScrollThumb) {
    return (
      Color backgroundColor,
      Animation<double> thumbAnimation,
      Animation<double> labelAnimation,
      double height,
      double width,
      bool shouldAppear, {
      Widget labelContent,
      BoxConstraints labelConstraints,
    }) {
      final scrollThumb = CustomPaint(
        key: scrollThumbKey,
        foregroundPainter: ArrowCustomPainter(Colors.grey),
        child: Material(
          elevation: 4.0,
          child: Container(
            constraints: BoxConstraints.tight(Size(width, height * 0.6)),
          ),
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(height),
            bottomLeft: Radius.circular(height),
            topRight: Radius.circular(4.0),
            bottomRight: Radius.circular(4.0),
          ),
        ),
      );

      return buildScrollThumbAndLabel(
        scrollThumb: scrollThumb,
        backgroundColor: backgroundColor,
        thumbAnimation: thumbAnimation,
        labelAnimation: labelAnimation,
        labelContent: labelContent,
        labelConstraints: labelConstraints,
        alwaysVisibleScrollThumb: shouldAppear && alwaysVisibleScrollThumb,
      );
    };
  }

  static ScrollThumbBuilder _thumbArrowBuilder(
      Key scrollThumbKey, bool alwaysVisibleScrollThumb) {
    return (
      Color backgroundColor,
      Animation<double> thumbAnimation,
      Animation<double> labelAnimation,
      double height,
      double width,
      bool shouldAppear, {
      Widget labelContent,
      BoxConstraints labelConstraints,
    }) {
      final scrollThumb = ClipPath(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(
              Radius.circular(12.0),
            ),
          ),
        ),
        clipper: ArrowClipper(),
      );

      return buildScrollThumbAndLabel(
        scrollThumb: scrollThumb,
        backgroundColor: backgroundColor,
        thumbAnimation: thumbAnimation,
        labelAnimation: labelAnimation,
        labelContent: labelContent,
        labelConstraints: labelConstraints,
        alwaysVisibleScrollThumb: shouldAppear && alwaysVisibleScrollThumb,
      );
    };
  }

  static ScrollThumbBuilder _thumbRRectBuilder(
      Key scrollThumbKey, bool alwaysVisibleScrollThumb) {
    return (
      Color backgroundColor,
      Animation<double> thumbAnimation,
      Animation<double> labelAnimation,
      double height,
      double width,
      bool shouldAppear, {
      Widget labelContent,
      BoxConstraints labelConstraints,
    }) {
      final scrollThumb = Material(
        key: scrollThumbKey,
        elevation: 4.0,
        child: Container(
          constraints: BoxConstraints.tight(
            Size(width, height),
          ),
        ),
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      );

      return buildScrollThumbAndLabel(
        scrollThumb: scrollThumb,
        backgroundColor: backgroundColor,
        thumbAnimation: thumbAnimation,
        labelAnimation: labelAnimation,
        labelContent: labelContent,
        labelConstraints: labelConstraints,
        alwaysVisibleScrollThumb: shouldAppear && alwaysVisibleScrollThumb,
      );
    };
  }
}

class ScrollLabel extends StatelessWidget {
  final Animation<double> animation;
  final Color backgroundColor;
  final Widget child;

  final BoxConstraints constraints;
  static const BoxConstraints _defaultConstraints =
      BoxConstraints.tightFor(width: 72.0, height: 28.0);

  const ScrollLabel({
    Key key,
    @required this.child,
    @required this.animation,
    @required this.backgroundColor,
    this.constraints = _defaultConstraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0.005, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            parent: animation,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 6.0),
          child: Material(
            elevation: 20.0,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(11.0)),
            child: Container(
              constraints: constraints ?? _defaultConstraints,
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SMMDraggableScrollbarState extends State<SMMDraggableScrollbar>
    with TickerProviderStateMixin {
  double _barOffset;
  double _viewOffset;
  bool _isDragInProcess;

  AnimationController _thumbAnimationController;
  Animation<double> _thumbAnimation;
  AnimationController _labelAnimationController;
  Animation<double> _labelAnimation;
  Timer _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    _barOffset = barMinScrollExtent;
    _viewOffset = 0.0;
    _isDragInProcess = false;

    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarAnimationDuration,
    );

    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _labelAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarAnimationDuration,
    );

    _labelAnimation = CurvedAnimation(
      parent: _labelAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      /// Call setState to make shouldAppear getter available
      setState(() {});
    });
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  double get barMaxScrollExtent =>
      context.size.height - widget.heightScrollThumb - widget.marginBottom;

  double get barMinScrollExtent => 0.0 + widget.marginTop;

  double get viewMaxScrollExtent => widget.controller.position.maxScrollExtent;

  double get viewMinScrollExtent => widget.controller.position.minScrollExtent;

  /// Whether the scrollbar should appear on the screen
  bool get shouldAppear =>
      widget.controller.position.maxScrollExtent != 0.0 &&
      widget.controller.position.maxScrollExtent -
              widget.controller.position.minScrollExtent >
          300.0;

  @override
  Widget build(BuildContext context) {
    Widget labelContent;
    if (widget.labelContentBuilder != null && _isDragInProcess) {
      labelContent = widget.labelContentBuilder(
        _viewOffset + _barOffset + widget.heightScrollThumb / 2,
      );
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      //print("LayoutBuilder constraints=$constraints");

      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: <Widget>[
            RepaintBoundary(
              child: widget.child,
            ),
            RepaintBoundary(
                child: GestureDetector(
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(
                alignment: Alignment.topRight,
                margin: EdgeInsets.only(top: _barOffset),
                padding: widget.padding,
                child: widget.scrollThumbBuilder(
                  widget.backgroundColor,
                  _thumbAnimation,
                  _labelAnimation,
                  widget.heightScrollThumb,
                  widget.widthScrollThumb,
                  widget.controller.hasClients && shouldAppear,
                  labelContent: labelContent,
                  labelConstraints: widget.labelConstraints,
                ),
              ),
            )),
          ],
        ),
      );
    });
  }

  //scroll bar has received notification that it's view was scrolled
  //so it should also changes his position
  //but only if it isn't dragged
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isDragInProcess ||
        notification.metrics.maxScrollExtent <
            notification.metrics.minScrollExtent) {
      return false;
    }

    setState(() {
      if (notification is ScrollUpdateNotification) {
        _viewOffset += notification.scrollDelta;
        if (_viewOffset < widget.controller.position.minScrollExtent) {
          _viewOffset = widget.controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }

        _barOffset = _viewOffset *
                (barMaxScrollExtent - barMinScrollExtent) /
                viewMaxScrollExtent +
            barMinScrollExtent;
      }

      if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        if (shouldAppear &&
            _thumbAnimationController.status != AnimationStatus.forward) {
          _thumbAnimationController.forward();
        }

        _fadeoutTimer?.cancel();
        _fadeoutTimer = Timer(widget.scrollbarTimeToFade, () {
          _thumbAnimationController.reverse();
          _labelAnimationController.reverse();
          _fadeoutTimer = null;
        });
      }
    });

    return false;
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragInProcess = true;
      _labelAnimationController.forward();
      _fadeoutTimer?.cancel();
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (_thumbAnimationController.status != AnimationStatus.forward) {
        _thumbAnimationController.forward();
      }
      if (_isDragInProcess) {
        _barOffset += details.delta.dy;

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        _viewOffset = (_barOffset - barMinScrollExtent) *
            (viewMaxScrollExtent +
                barMinScrollExtent * viewMaxScrollExtent / barMaxScrollExtent) /
            barMaxScrollExtent;
    
        widget.controller.jumpTo(_viewOffset);
      }
    });
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    _isDragInProcess = false;
    _fadeoutTimer = Timer(applyDilation(widget.scrollbarTimeToFade), () {
      _thumbAnimationController.reverse();
      _labelAnimationController.reverse();
      _fadeoutTimer =
          Timer(applyDilation(widget.scrollbarAnimationDuration), () {
        setState(() {});
        _fadeoutTimer = null;
      });
    });
  }
}

/// Draws 2 triangles like arrow up and arrow down
class ArrowCustomPainter extends CustomPainter {
  Color color;

  ArrowCustomPainter(this.color);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const width = 12.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;

    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY - 2.0), width, height, true),
      paint,
    );
    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY + 2.0), width, height, false),
      paint,
    );
  }

  static Path _trianglePath(Offset o, double width, double height, bool isUp) {
    return Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + width, o.dy)
      ..lineTo(o.dx + (width / 2), isUp ? o.dy - height : o.dy + height)
      ..close();
  }
}

///This cut 2 lines in arrow shape
class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.lineTo(0.0, 0.0);
    path.close();

    double arrowWidth = 8.0;
    double startPointX = (size.width - arrowWidth) / 2;
    double startPointY = size.height / 2 - arrowWidth / 2;
    path.moveTo(startPointX, startPointY);
    path.lineTo(startPointX + arrowWidth / 2, startPointY - arrowWidth / 2);
    path.lineTo(startPointX + arrowWidth, startPointY);
    path.lineTo(startPointX + arrowWidth, startPointY + 1.0);
    path.lineTo(
        startPointX + arrowWidth / 2, startPointY - arrowWidth / 2 + 1.0);
    path.lineTo(startPointX, startPointY + 1.0);
    path.close();

    startPointY = size.height / 2 + arrowWidth / 2;
    path.moveTo(startPointX + arrowWidth, startPointY);
    path.lineTo(startPointX + arrowWidth / 2, startPointY + arrowWidth / 2);
    path.lineTo(startPointX, startPointY);
    path.lineTo(startPointX, startPointY - 1.0);
    path.lineTo(
        startPointX + arrowWidth / 2, startPointY + arrowWidth / 2 - 1.0);
    path.lineTo(startPointX + arrowWidth, startPointY - 1.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SlideFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const SlideFadeTransition({
    Key key,
    @required this.animation,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => animation.value == 0.0 ? Container() : child,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0.3, 0.0),
          end: Offset(0.0, 0.0),
        ).animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
