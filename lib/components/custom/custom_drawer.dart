// /*---------------------------------------------------------------------------------------------
// *  Copyright (c) nt4f04und. All rights reserved.
// *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
// *
// *  Copyright (c) The Chromium Authors.
// *  See ThirdPartyNotices.txt in the project root for license information.
// *--------------------------------------------------------------------------------------------*/

// import 'dart:math';

// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:sweyer/sweyer.dart';

// // Constants were coped from flutter's drawer file
// const double _kWidth = 304.0;
// const double _kEdgeDragWidth = 20.0;
// const double _kMinFlingVelocity = 365.0;
// const Duration _kBaseSettleDuration = Duration(milliseconds: 450);

// /// Creates a custom controller for a [Drawer].
// ///
// /// See flutter's [Drawer] for docs
// class SMMDrawerController extends StatefulWidget {
//   const SMMDrawerController({
//     GlobalKey key,
//     @required this.child,
//     @required this.alignment,
//     this.drawerCallback,
//     this.dragStartBehavior = DragStartBehavior.start,
//     this.scrimColor,
//     this.edgeDragWidth,
//   })  : assert(child != null),
//         assert(dragStartBehavior != null),
//         assert(alignment != null),
//         super(key: key);

//   final Widget child;
//   final DrawerAlignment alignment;
//   final DrawerCallback drawerCallback;
//   final DragStartBehavior dragStartBehavior;
//   final Color scrimColor;
//   final double edgeDragWidth;

//   @override
//   SMMDrawerControllerState createState() => SMMDrawerControllerState();
// }

// /// Custom state for a [DrawerController].
// ///
// /// Distinct from default flutter's it's duration
// ///
// /// Typically used by a [SMMScaffold] to [open] and [close] the drawer.
// class SMMDrawerControllerState extends State<SMMDrawerController>
//     with SingleTickerProviderStateMixin {
//   @override
//   void initState() {
//     super.initState();
//     _scrimColorTween = _buildScrimColorTween();
//     _controller =
//         AnimationController(duration: _kBaseSettleDuration, vsync: this)
//           ..addListener(_animationChanged)
//           ..addStatusListener(_animationStatusChanged);
//     _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.linearToEaseOut,
//       reverseCurve: Curves.easeInToLinear,
//     ));
//   }

//   @override
//   void dispose() {
//     _historyEntry?.remove();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(SMMDrawerController oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.scrimColor != oldWidget.scrimColor)
//       _scrimColorTween = _buildScrimColorTween();
//   }

//   void _animationChanged() {
//     setState(() {
//       // The animation controller's state is our build state, and it changed already.
//     });
//   }

//   LocalHistoryEntry _historyEntry;
//   final FocusScopeNode _focusScopeNode = FocusScopeNode();

//   void _ensureHistoryEntry() {
//     if (_historyEntry == null) {
//       final ModalRoute<dynamic> route = ModalRoute.of(context);
//       if (route != null) {
//         // _historyEntry = LocalHistoryEntry(onRemove: _handleHistoryEntryRemoved);
//         _historyEntry = LocalHistoryEntry(onRemove: _handleHistoryEntryRemoved, );
//         route.addLocalHistoryEntry(_historyEntry);
//         FocusScope.of(context).setFirstFocus(_focusScopeNode);
//       }
//     }
//   }

//   void _animationStatusChanged(AnimationStatus status) {
//     switch (status) {
//       case AnimationStatus.forward:
//         _ensureHistoryEntry();
//         break;
//       case AnimationStatus.reverse:
//         _historyEntry?.remove();
//         _historyEntry = null;
//         break;
//       case AnimationStatus.dismissed:
//         _isMoving = false;
//         break;
//       case AnimationStatus.completed:
//         _isMoving = false;
//         break;
//     }
//   }

// bool _dragClose = false;

//   void _handleHistoryEntryRemoved() {
//     _historyEntry = null;
//     if(!_dragClose)
//     close();
//     else 
//     _dragClose = false;
//   }

//   AnimationController _controller;
//   Animation _animation;
//   bool _isMoving = false;

//   void _handleDragDown(DragDownDetails details) {
//      _controller.stop();
//     _ensureHistoryEntry();
//   }

//   void _handleDragCancel() {
//     if (_controller.isDismissed || _controller.isAnimating) return;
//     if (_controller.value < 0.5) {
//       close();
//     } else {
//       open();
//     }
//   }

//   final GlobalKey _drawerKey = GlobalKey();

//   double get _width {
//     final RenderBox box =
//         _drawerKey.currentContext?.findRenderObject() as RenderBox;
//     if (box != null) return box.size.width;
//     return _kWidth; // drawer not being shown currently
//   }

//   bool _previouslyOpened = false;

//   void _move(DragUpdateDetails details) {
//     _isMoving = true;
//     double delta = details.primaryDelta / _width;
//     switch (widget.alignment) {
//       case DrawerAlignment.start:
//         break;
//       case DrawerAlignment.end:
//         delta = -delta;
//         break;
//     }
//     switch (Directionality.of(context)) {
//       case TextDirection.rtl:
//         _controller.value -= delta;
//         break;
//       case TextDirection.ltr:
//         _controller.value += delta;
//         break;
//     }

//     final bool opened = _controller.value > 0.5;
//     if (opened != _previouslyOpened && widget.drawerCallback != null)
//       widget.drawerCallback(opened);
//     _previouslyOpened = opened;
//   }

//   void _settle(DragEndDetails details) {
//     if (_controller.isDismissed) return;
//     if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
//       double visualVelocity = details.velocity.pixelsPerSecond.dx / _width;
//       switch (widget.alignment) {
//         case DrawerAlignment.start:
//           break;
//         case DrawerAlignment.end:
//           visualVelocity = -visualVelocity;
//           break;
//       }
//       switch (Directionality.of(context)) {
//         case TextDirection.rtl:
//           _controller.fling(velocity: -visualVelocity);
//           break;
//         case TextDirection.ltr:
//         if( visualVelocity < 0){
//           // print(_isMoving);
//           _dragClose = true;
//        _controller.fling(velocity: -1.0);
//       // close();
//         }
//          else {
//            _controller.fling(velocity: visualVelocity);
//          }
//           break;
//       }
//     } else if (_controller.value < 0.5) {
//       close();
//     } else {
//       openFling();
//     }
//   }

//   /// Starts an animation to open the drawer.
//   ///
//   /// Typically called by [SMMScaffoldState.openDrawer].
//   void open() {
//     _controller.forward();
//     if (widget.drawerCallback != null) widget.drawerCallback(true);
//   }
//   void openFling() {
//     _controller.fling(velocity: 1.0);
//     if (widget.drawerCallback != null) widget.drawerCallback(true);
//   }

//   /// Starts an animation to close the drawer.
//   void close() {
//     _controller.reverse();
//     if (widget.drawerCallback != null) widget.drawerCallback(false);
//   }

//   /// Flings instead of playing reverse animation
//   ///
//   /// Used to close on settle
//   void closeFling() {
//     _controller.fling(velocity: -1.0);
//     if (widget.drawerCallback != null) widget.drawerCallback(false);
//   }

//   ColorTween _scrimColorTween;
//   final GlobalKey _gestureDetectorKey = GlobalKey();

//   ColorTween _buildScrimColorTween() {
//     return ColorTween(
//         begin: Colors.transparent, end: widget.scrimColor ?? Colors.black54);
//   }

//   AlignmentDirectional get _drawerOuterAlignment {
//     assert(widget.alignment != null);
//     switch (widget.alignment) {
//       case DrawerAlignment.start:
//         return AlignmentDirectional.centerStart;
//       case DrawerAlignment.end:
//         return AlignmentDirectional.centerEnd;
//     }
//     return null;
//   }

//   AlignmentDirectional get _drawerInnerAlignment {
//     assert(widget.alignment != null);
//     switch (widget.alignment) {
//       case DrawerAlignment.start:
//         return AlignmentDirectional.centerEnd;
//       case DrawerAlignment.end:
//         return AlignmentDirectional.centerStart;
//     }
//     return null;
//   }

//   Widget _buildDrawer(BuildContext context) {
//     final bool drawerIsStart = widget.alignment == DrawerAlignment.start;
//     final EdgeInsets padding = MediaQuery.of(context).padding;
//     final TextDirection textDirection = Directionality.of(context);

//     double dragAreaWidth = widget.edgeDragWidth;
//     if (widget.edgeDragWidth == null) {
//       switch (textDirection) {
//         case TextDirection.ltr:
//           dragAreaWidth =
//               _kEdgeDragWidth + (drawerIsStart ? padding.left : padding.right);
//           break;
//         case TextDirection.rtl:
//           dragAreaWidth =
//               _kEdgeDragWidth + (drawerIsStart ? padding.right : padding.left);
//           break;
//       }
//     }

//     if (_controller.status == AnimationStatus.dismissed) {
//       return Align(
//         alignment: _drawerOuterAlignment,
//         child: GestureDetector(
//           key: _gestureDetectorKey,
//           onHorizontalDragUpdate: _move,
//           onHorizontalDragEnd: _settle,
//           behavior: HitTestBehavior.translucent,
//           excludeFromSemantics: true,
//           dragStartBehavior: widget.dragStartBehavior,
//           child: Container(width: dragAreaWidth),
//         ),
//       );
//     } else {
//       bool platformHasBackButton;
//       switch (Theme.of(context).platform) {
//         case TargetPlatform.android:
//           platformHasBackButton = true;
//           break;
//         case TargetPlatform.iOS:
//         case TargetPlatform.macOS:
//         case TargetPlatform.fuchsia:
//           platformHasBackButton = false;
//           break;
//       }
//       assert(platformHasBackButton != null);
//       return GestureDetector(
//         key: _gestureDetectorKey,
//         onHorizontalDragDown: _handleDragDown,
//         onHorizontalDragUpdate: _move,
//         onHorizontalDragEnd: _settle,
//         onHorizontalDragCancel: _handleDragCancel,
//         excludeFromSemantics: true,
//         dragStartBehavior: widget.dragStartBehavior,
//         child: RepaintBoundary(
//           child: Stack(
//             children: <Widget>[
//               BlockSemantics(
//                 child: GestureDetector(
//                   // On Android, the back button is used to dismiss a modal.
//                   excludeFromSemantics: platformHasBackButton,
//                   onTap: close,
//                   child: Semantics(
//                       label: MaterialLocalizations.of(context)
//                           ?.modalBarrierDismissLabel,
//                       child: MouseRegion(
//                         opaque: true,
//                         child: Container(
//                           // The drawer's "scrim"
//                           color: _scrimColorTween.evaluate(_controller),
//                         ),
//                       )),
//                 ),
//               ),
//               Align(
//                 alignment: _drawerOuterAlignment,
//                 child: Align(
//                   alignment: _drawerInnerAlignment,
//                   widthFactor: _isMoving ? _controller.value : _animation.value,
//                   // widthFactor: _controller.value,
//                   child: RepaintBoundary(
//                     child: FocusScope(
//                       key: _drawerKey,
//                       node: _focusScopeNode,
//                       child: widget.child,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     assert(debugCheckHasMaterialLocalizations(context));
//     return ListTileTheme(
//       style: ListTileStyle.drawer,
//       child: _buildDrawer(context),
//     );
//   }
// }
