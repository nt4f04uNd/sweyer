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
    this.important = false,
  }) : assert(child != null) {
    if (globalKey == null)
      this.globalKey = GlobalKey<SMMSnackBarWrapperState>();
  }

  /// Main widget to display as a snackbar
  final Widget child;
  GlobalKey<SMMSnackBarWrapperState> globalKey;

  /// How long the snackbar will be shown
  final Duration duration;

  /// Whether the snack bar is important and must interrupt the current displaying one
  final bool important;

  OverlayEntry overlayEntry;

  /// True when snackbar is visible
  bool onScreen = false;

  /// Create [OverlayEntry] for snackbar
  void createSnackbar() {
    onScreen = true;
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
    onScreen = false;
    overlayEntry.remove();
  }
}

abstract class SnackBarControl {
  /// A list to render the snackbars
  static List<SMMSnackbarSettings> snackbarsList = [];

  static void showSnackBar(SMMSnackbarSettings settings) async {
    assert(settings != null);

    if (settings.important && snackbarsList.length > 1) {
      snackbarsList.insert(1, settings);
    } else {
      snackbarsList.add(settings);
    }

    if (snackbarsList.length == 1) {
      _showSnackBar();
    } else if (settings.important) {
      for (int i = 0; i < snackbarsList.length; i++) {
        if (snackbarsList[i].onScreen) {
          _dismissSnackBar(index: i);
        }
      }
      _showSnackBar();
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

  /// Method to be called after the current snack bar has went out of screen
  static void _handleSnackBarDismissed() {
    _dismissSnackBar(index: 0);
    if (snackbarsList.isNotEmpty) {
      _showSnackBar();
    }
  }

  /// Creates next snackbar and shows it to screen
  /// [index] can be used to justify what snackbar to show
  static void _showSnackBar({int index = 0}) {
    assert(!snackbarsList[index].onScreen);
    snackbarsList[index].createSnackbar();
    App.navigatorKey.currentState.overlay
        .insert(snackbarsList[index].overlayEntry);
  }

  /// Removes next snackbar from screen without animation
  /// [index] can be used to justify what snackbar to hide
  static void _dismissSnackBar({int index = 0}) {
    snackbarsList[index].removeSnackbar();
    snackbarsList.removeAt(index);
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
  Key dismissibleKey;

  @override
  void initState() {
    super.initState();
    dismissibleKey = UniqueKey();
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

  /// Will close snackbar with Animation
  ///
  /// If [notifyControl] is true, the [SnackBarControl._handleSnackBarDismissed] will be called internally after the closure
  Future<void> close({bool notifyControl = true}) async {
    asyncOperation = AsyncOperation()..start();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        asyncOperation.finish(true);
      }
    });
    controller.reverse();
    var res = await asyncOperation.wait();
    if (res && notifyControl) {
      SnackBarControl._handleSnackBarDismissed();
    }
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
              key: dismissibleKey,
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
    this.color,
    this.messagePadding = const EdgeInsets.all(0.0),
  }) : super(key: key);
  final Widget leading;
  final String message;
  final Widget action;
  final Color color;
  final EdgeInsets messagePadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.primary,
      child: ListTileTheme(
        textColor: Theme.of(context).colorScheme.onPrimary,
        child: Container(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
          constraints: const BoxConstraints(minHeight: 48.0, maxHeight: 128.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: leading,
                ),
              Expanded(
                child: Padding(
                  padding: messagePadding,
                  child: Text(
                    message,
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: action,
                )
            ],
          ),
        ),
        // ListTile(
        //   title: Text(
        //     message,
        //     style: const TextStyle(fontSize: 15.0),
        //   ),
        //   leading: leading,
        //   trailing: action,
        //   dense: true,
        // ),
      ),
    );
  }
}
