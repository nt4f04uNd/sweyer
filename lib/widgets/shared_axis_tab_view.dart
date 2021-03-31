/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';

/// Coordinates the logic behind the [SharedAxisTabView].
class SharedAxisTabController extends ChangeNotifier {
  SharedAxisTabController({
    @required this.length,
    int initialIndex = 0,
  }) : _index = initialIndex,
      _prevIndex = initialIndex;

  /// The total number of tabs.
  final int length;

  /// The index of the currently selected tab.
  int get index => _index;
  int _index;

  /// The index of the previously selected tab.
  int get prevIndex => _prevIndex;
  int _prevIndex;
  
  void changeTab(int value) {
    assert(value >= 0 && (value < length || length == 0));
    _prevIndex = _index;
    _index = value;
    notifyListeners();
  }
}

/// Create tab view and animates tab changes with [SharedAxisTransition].
/// 
/// See also:
/// * [SharedAxisTabController] that controls this view
class SharedAxisTabView extends StatefulWidget {
  const SharedAxisTabView({
    Key key,
    @required this.children,
    @required this.controller,
    this.tabBuilder = _defaultTabBuilder,
  }) : super(key: key);

  static Widget _defaultTabBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  /// A list of widgets used as tabs.
  final List<Widget> children;

  /// Controls this widget's opened tab state.
  /// 
  /// Must not be null and the length of it must match the [children] length.
  final SharedAxisTabController controller;

  /// Allows to add hook into tab build process.
  /// Specifying this doens't affect the animation this view provides by defaults.
  final RouteTransitionsBuilder tabBuilder;

  @override
  _SharedAxisTabViewState createState() => _SharedAxisTabViewState();
}

class _SharedAxisTabViewState extends State<SharedAxisTabView> {
  double dragDelta = 0.0;
  /// Whether can transition by swipe.
  bool canTransition = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    assert(() {
      if (controller.length != widget.children.length) {
        throw ArgumentError(
          "Controller's length property (${controller.length}) does not match the "
          "number of tabs (${widget.children.length}) present in TabBar's tabs property."
        );
      }
      return true;
    }());
    return GestureDetector(
      onHorizontalDragStart: (_) {
        canTransition = true;
      },
      onHorizontalDragUpdate: (details) {
        if (canTransition) {
          dragDelta += details.delta.dx;
          if (dragDelta.abs() > 15.0) {
            if (dragDelta.sign > 0.0 && controller.index - 1 >= 0) {
              controller.changeTab(controller.index - 1);
              canTransition = false;
            } else if (dragDelta.sign < 0.0 && controller.index + 1 < controller.length) {
              controller.changeTab(controller.index + 1);
              canTransition = false;
            }
          }
        }
      },
      onHorizontalDragEnd: (_) {
        canTransition = false;
        dragDelta = 0.0;
      },
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => IndexedTransitionSwitcher(
          index: controller.index,
          duration: const Duration(milliseconds: 200),
          reverse: controller.prevIndex > controller.index,
          children: widget.children,
          transitionBuilder: (
            Widget child,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return SharedAxisTransition(
              transitionType: SharedAxisTransitionType.horizontal,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              fillColor: Colors.transparent,
              child: AnimatedBuilder(
                animation: animation,
                child: child,
                builder: (context, child) => widget.tabBuilder(context, animation, secondaryAnimation, child),
              ),
            );
          },
        ),
      ),
    );
  }
}