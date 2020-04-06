/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

// TODO: see what this method is doing
// SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription());

const String kSMMSystemUiOverlayAnimationDebugLabel =
    "SystemUIOverlayAnimationController";

/// Holds animation controller settings.
class AnimationControllerSettings {
  /// The omitted values will be null.
  const AnimationControllerSettings({
    this.value,
    this.duration,
    this.reverseDuration,
    this.lowerBound,
    this.upperBound,
    this.animationBehavior,
  });

  /// Creates default configuration of the animation controller.
  const AnimationControllerSettings.defaultConfig({
    this.value = 0.0,
    this.duration = kSMMRouteTransitionDuration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior,
  });

  final double value;
  final Duration duration;
  final Duration reverseDuration;
  final double lowerBound;
  final double upperBound;
  final AnimationBehavior animationBehavior;

  /// Creates a copy of this animation settings but with the given fields replaced with
  /// the new values.
  AnimationControllerSettings copyWith(AnimationControllerSettings other) {
    assert(other != null);
    return AnimationControllerSettings(
      value: other.value ?? this.value,
      duration: other.duration ?? this.duration,
      reverseDuration: other.reverseDuration ?? this.reverseDuration,
      lowerBound: other.lowerBound ?? this.lowerBound,
      upperBound: other.upperBound ?? this.upperBound,
      animationBehavior: other.animationBehavior ?? this.animationBehavior,
    );
  }
}

abstract class SystemUiOverlayStyleControl {
  static AnimationController _controller = AnimationController(
    duration: kSMMRouteTransitionDuration,
    debugLabel: kSMMSystemUiOverlayAnimationDebugLabel,
    vsync: App.navigatorKey.currentState,
  );
  static bool _controllerDisposed = false;

  /// Operation to wait before the animation completes
  static AsyncOperation _animatingOperation = AsyncOperation();

  static AnimationControllerSettings _controllerSettings =
      const AnimationControllerSettings.defaultConfig();

  static SystemUiOverlayStyle _lastOverlayStyle;

  /// Sets up settings of the controller.
  /// Will override the existing settings with new ones.
  /// Will reset settings to default if no value has been passed.
  static void setControllerSettings(
      [AnimationControllerSettings settings =
          const AnimationControllerSettings.defaultConfig()]) async {
    _controllerSettings = _controllerSettings.copyWith(settings);
  }

  /// Creates the controller from the provided settings.
  /// The passed settings will override current settings respectively.
  static void _setController(AnimationControllerSettings settings) {
    _controllerDisposed = false;
    _controller = AnimationController(
      value: settings?.value ?? _controllerSettings.value,
      duration: settings?.duration ?? _controllerSettings.duration,
      reverseDuration:
          settings?.reverseDuration ?? _controllerSettings.reverseDuration,
      debugLabel: "SystemUIOverlayAnimationController",
      lowerBound: settings?.lowerBound ?? _controllerSettings.lowerBound,
      upperBound: settings?.upperBound ?? _controllerSettings.upperBound,
      animationBehavior:
          settings?.animationBehavior ?? _controllerSettings.animationBehavior,
      vsync: App.navigatorKey.currentState,
    );
  }

  static void _handleEnd(SystemUiOverlayStyle newStyle,
      {bool saveToHistory = true}) {
    if (saveToHistory) {
      _lastOverlayStyle = newStyle;
    }

    if (!_controllerDisposed) {
      _controllerDisposed = true;
      _controller.dispose();
    }
    if (_animatingOperation.isWorking) {
      _animatingOperation.finish();
      _animatingOperation = AsyncOperation();
    }
  }

  /// Sets a new overlay ui style
  ///
  /// [saveToHistory] - whether to save the ui change to history
  static void setSystemUiOverlay(SystemUiOverlayStyle newStyle,
      {bool saveToHistory = true}) {
    _handleEnd(newStyle, saveToHistory: saveToHistory);
    SystemChrome.setSystemUIOverlayStyle(newStyle);
  }

  /// Performs a transition from old overlay to new one.
  ///
  /// The returned future will complete after the animation ends.
  ///
  /// [from] is Ui to animate from. It can be omitted, if so, then the internal [_lastOverlayStyle] will be used instead.
  ///
  /// [to] is the Ui to animate to. It is required.
  ///
  /// [saveToHistory] - whether to save the ui change to history
  ///
  /// [curve] is a custom animation curve
  ///
  /// The passed [settings] will override current settings respectively.
  static Future<void> animateSystemUiOverlay({
    SystemUiOverlayStyle from,
    @required SystemUiOverlayStyle to,
    Curve curve = Curves.easeOutCubic,
    bool saveToHistory = true,
    AnimationControllerSettings settings,
  }) async {
    assert(to != null);

    _lastOverlayStyle ??=
        Constants.AppSystemUIThemes.mainScreen.autoWithoutContext;
    from ??= _lastOverlayStyle;

    if (_controller.isAnimating) {
      _handleEnd(from, saveToHistory: saveToHistory);
    }
    _setController(settings);
    _animatingOperation.start();

    // print(
    //     "from ${from.systemNavigationBarColor} to ${to.systemNavigationBarColor}");

    final listener = () async {
      final animationNavBar = ColorTween(
        begin: from.systemNavigationBarColor,
        end: to.systemNavigationBarColor,
      ).animate(
        CurvedAnimation(curve: curve, parent: _controller),
      );

      final animationNavBarDivider = ColorTween(
        begin: from.systemNavigationBarDividerColor,
        end: to.systemNavigationBarDividerColor,
      ).animate(
        CurvedAnimation(curve: curve, parent: _controller),
      );

      final animationStatusBar = ColorTween(
        begin: from.statusBarColor,
        end: to.statusBarColor,
      ).animate(
        CurvedAnimation(curve: curve, parent: _controller),
      );

      final isLessHalf =
          CurveTween(curve: curve).animate(_controller).value < 0.5;

      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            systemNavigationBarColor: animationNavBar.value,
            systemNavigationBarDividerColor: animationNavBarDivider.value,
            systemNavigationBarIconBrightness: isLessHalf
                ? from.systemNavigationBarIconBrightness
                : to.systemNavigationBarIconBrightness,
            statusBarColor: animationStatusBar.value,
            statusBarBrightness:
                isLessHalf ? from.statusBarBrightness : to.statusBarBrightness,
            statusBarIconBrightness: isLessHalf
                ? from.statusBarIconBrightness
                : to.statusBarIconBrightness),
      );
    };

    _controller.addListener(listener);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.removeListener(listener);
        _handleEnd(to, saveToHistory: saveToHistory);
      }
    });
    _controller.forward();

    return _animatingOperation.wait();
  }
}
