import 'package:flutter/widgets.dart';


/// This behaves like the builtin [BackButtonListener], but it doesn't
/// prioritize the listener when the widget is rebuilt.
class NFBackButtonListener extends StatefulWidget {
  const NFBackButtonListener({
    Key? key,
    required this.child,
    required this.onBackButtonPressed,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The callback function that will be called when the back button is pressed.
  ///
  /// It must return a boolean future with true if this child will handle the request;
  /// otherwise, return a boolean future with false.
  final ValueGetter<Future<bool>> onBackButtonPressed;

  @override
  State<NFBackButtonListener> createState() => _NFBackButtonListenerState();
}

class _NFBackButtonListenerState extends State<NFBackButtonListener> {
  BackButtonDispatcher? dispatcher;

  @override
  void didChangeDependencies() {
    dispatcher?.removeCallback(_onBackButtonPressed);

    final BackButtonDispatcher? rootBackDispatcher = Router.of(context).backButtonDispatcher;
    assert(rootBackDispatcher != null, 'The parent router must have a backButtonDispatcher to use this widget');

    dispatcher = rootBackDispatcher!.createChildBackButtonDispatcher()
      ..addCallback(_onBackButtonPressed)
      ..takePriority();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    dispatcher?.removeCallback(_onBackButtonPressed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<bool> _onBackButtonPressed() => widget.onBackButtonPressed();
}
