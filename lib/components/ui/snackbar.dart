/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

const Duration kSMMSnackBarAnimationDuration =
    const Duration(milliseconds: 270);
const Duration kSMMSnackBarDismissMovementDuration =
    const Duration(milliseconds: 170);
const int kSMMSnackBarMaxQueueLength = 15;

class SMMSnackbarSettings {
  SMMSnackbarSettings({
    @required this.child,
    this.globalKey,
    this.duration = const Duration(seconds: 4),
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

  static void showSnackBar({@required SMMSnackbarSettings settings}) async {
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
  AnimationController timeoutController;
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
    timeoutController = AnimationController(
      vsync: this,
      debugLabel: "SMMSnackbarProgress",
      duration: widget.settings.duration,
    );
    animation = Tween(begin: const Offset(0.0, 32.0), end: Offset.zero).animate(
      CurvedAnimation(curve: Curves.easeOutCubic, parent: controller),
    );

    controller.forward();
    timeoutController.value = 1;
    timeoutController.reverse();
    timeoutController.addStatusListener((status) {
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
    timeoutController.dispose();
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

  /// Will stop snackbar timeout close timer
  void stopTimer() {
    timeoutController.stop();
  }

  /// Will resume snackbar timeout close timer
  void resumeTimer() {
    timeoutController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(curve: Curves.easeOutCubic, parent: controller),
      ),
      child: AnimatedBuilder(
        animation: animation,
        child: widget.settings.child,
        builder: (BuildContext context, Widget child) => IgnorePointer(
          ignoring: controller.status == AnimationStatus.reverse,
          child: GestureDetector(
            onPanDown: (_) {
              stopTimer();
            },
            onPanEnd: (_) {
              resumeTimer();
            },
            onPanCancel: () {
              resumeTimer();
            },
            onLongPress: () {
              stopTimer();
            },
            onLongPressEnd: (_) {
              resumeTimer();
            },
            child: Dismissible(
              key: Key("SnackBarDismissible"),
              movementDuration: kSMMSnackBarDismissMovementDuration,
              direction: DismissDirection.down,
              onDismissed: (_) => SnackBarControl._handleSnackBarDismissed(),
              child: Transform.translate(
                offset: animation.value,
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        child,
                        // AnimatedBuilder(
                        //   animation: timeoutController,
                        //   // child:,
                        //   builder: (BuildContext context, Widget child) =>
                        //       LinearProgressIndicator(
                        //     value: timeoutController.value,
                        //   ),
                        // ),
                      ],
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

class SMMSnackBar extends StatelessWidget {
  const SMMSnackBar({
    Key key,
    this.message,
    this.leading,
    this.action,
  }) : super(key: key);
  final String message;
  final Widget leading;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      child: ListTileTheme(
        textColor: Theme.of(context).colorScheme.onPrimary,
        style: ListTileStyle.list,
        child: ListTile(
          title: Text(
            message,
            style: const TextStyle(fontSize: 15.0),
          ),
          leading: leading,
          trailing: action,
          dense: true,
        ),
      ),
    );
  }
}
