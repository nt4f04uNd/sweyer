/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

const Duration kSMMSnackBarAnimationDuration =
    const Duration(milliseconds: 270);
const Duration kSMMSnackBarDismissMovementDuration =
    const Duration(milliseconds: 170);
const int kSMMSnackBarMaxQueueLength = 15;

/// A container class for [globalKey] and [overlayEntry] itself to render
class _SnackbarToRender {
  _SnackbarToRender({@required this.globalKey, @required this.overlayEntry});
  final GlobalKey<SMMSnackBarWrapperState> globalKey;
  final OverlayEntry overlayEntry;
}

class SMMSnackbarSettings {
  SMMSnackbarSettings({
    @required this.child,
    this.globalKey,
    this.duration = const Duration(seconds: 5),
  }) : assert(child != null) {
    if (globalKey == null)
      this.globalKey = GlobalKey<SMMSnackBarWrapperState>();
  }

  /// Main widget to display as a snackbar
  final Widget child;
  GlobalKey<SMMSnackBarWrapperState> globalKey;

  /// How long the snackbar will be shown
  final Duration duration;

  OverlayEntry overlayEntry;

  /// Create [OverlayEntry] for snackbar
  void createSnackbar() {
    overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Container(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _SMMSnackBarWrapper(settings: this, key: globalKey),
        ),
      ),
    );
  }

  /// Removes [OverlayEntry]
  void removeSnackbar() {
    overlayEntry.remove();
  }
}

abstract class SnackBarControl {
  /// A list to render the snackbars
  static List<SMMSnackbarSettings> snackbarsList = List();

  /// Gets the current snackbar global key
  ///
  /// Will return null if snackbars list is empty
  static GlobalKey<SMMSnackBarWrapperState> get globalKey =>
      snackbarsList.isNotEmpty ? snackbarsList[0].globalKey : null;

  static void showSnackBar(BuildContext context,
      {@required SMMSnackbarSettings settings}) async {
    assert(settings != null);

    snackbarsList.add(settings);

    if (snackbarsList.length == 1) {
      snackbarsList[0].createSnackbar();
      App.navigatorKey.currentState.overlay
          .insert(snackbarsList[0].overlayEntry);
    }
    if (snackbarsList.length >= kSMMSnackBarMaxQueueLength) {
      /// Reset when queue runs out of space
      snackbarsList = [
        snackbarsList[0],
        snackbarsList[kSMMSnackBarMaxQueueLength - 2],
        snackbarsList[kSMMSnackBarMaxQueueLength - 1]
      ];
    }
  }

  static void _handleSnackBarDismissed() {
    snackbarsList[0].removeSnackbar();
    snackbarsList.removeAt(0);
    if (snackbarsList.isNotEmpty) {
      _showSnackBar();
    }
  }

  static void _showSnackBar() {
    snackbarsList[0].createSnackbar();
    App.navigatorKey.currentState.overlay.insert(snackbarsList[0].overlayEntry);
  }

  // static void
}

/// Custom snackbar to display it in the [Overlay]
class _SMMSnackBarWrapper extends StatefulWidget {
  _SMMSnackBarWrapper({
    Key key,
    @required this.settings,
  })  : assert(settings != null),
        super(key: key);

  final SMMSnackbarSettings settings;

  @override
  SMMSnackBarWrapperState createState() => SMMSnackBarWrapperState();
}

class SMMSnackBarWrapperState extends State<_SMMSnackBarWrapper>
    with TickerProviderStateMixin {
  /// TODO: use [AsyncOperationsQueue] here
  AsyncOperation<bool> asyncOperation;
  AnimationController controller;
  AnimationController progressController;
  Animation animation;

  @override
  void initState() {
    super.initState();

    asyncOperation = AsyncOperation()..start();

    controller = AnimationController(
      vsync: this,
      debugLabel: "SMMSnackBarWrapper",
      duration: kSMMSnackBarAnimationDuration,
    );
    progressController = AnimationController(
      vsync: this,
      debugLabel: "SMMSnackbarProgress",
      duration: widget.settings.duration,
    );
    animation = Tween(begin: const Offset(0.0, 32.0), end: Offset.zero).animate(
      CurvedAnimation(curve: Curves.easeOutCubic, parent: controller),
    );

    controller.forward();
    progressController.value = 1;
    progressController.reverse();
    progressController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) asyncOperation.finish(true);
    });

    _handleEnd();
  }

  @override
  void dispose() {
    if (asyncOperation.isWorking) {
      asyncOperation.finish(false);
    }
    controller.dispose();
    progressController.dispose();
    super.dispose();
  }

  void _handleEnd() async {
    var res = await asyncOperation.wait();
    if (res) {
      close();
    }
  }

  void close() async {
    asyncOperation = AsyncOperation()..start();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) asyncOperation.finish(true);
    });
    controller.reverse();
    var res = await asyncOperation.wait();
    if (res) SnackBarControl._handleSnackBarDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(curve: Curves.easeOutCubic, parent: controller),
      ),
      child: GestureDetector(
        onPanDown: (_) {
          progressController.stop();
        },
        onPanCancel: () {
          progressController.reverse();
        },
        onPanEnd: (_) {
          progressController.reverse();
        },
        child: Dismissible(
          key: UniqueKey(),
          movementDuration: kSMMSnackBarDismissMovementDuration,
          direction: DismissDirection.down,
          onDismissed: (_) => SnackBarControl._handleSnackBarDismissed(),
          child: AnimatedBuilder(
            animation: animation,
            child: widget.settings.child,
            builder: (BuildContext context, Widget child) =>
                Transform.translate(
              offset: animation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  child,
                  AnimatedBuilder(
                    animation: progressController,
                    // child:,
                    builder: (BuildContext context, Widget child) =>
                        LinearProgressIndicator(
                      value: progressController.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SMMSnackBar extends StatelessWidget {
  const SMMSnackBar({
    Key key,
    this.title,
    this.leading,
    this.action,
  }) : super(key: key);
  final Widget title;
  final Widget leading;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        title: title,
        leading: leading,
        trailing: action,
      ),
    );
  }
}
