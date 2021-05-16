/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:math';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:collection/collection.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

// See selection actions logic overview here
// https://docs.google.com/spreadsheets/d/1LYJ5Abb1zWhYMAUs0zRjx-aiMwJn-3XLS2NjoqV5le8

/// Selection animation duration.
const Duration kSelectionDuration = Duration(milliseconds: 350);

/// The [SelectionWidget] need its parent updates him.
///
/// Mixin this to a parent of [SelectableWidget] and add [handleSelection],
/// (or optionally [handleSelectionStatus]) as handler to listener to the controller(s).
mixin SelectionHandler<T extends StatefulWidget> on State<T> {
  /// Listens to [SelectionController.addListener].
  /// By default just calls [setState].
  @protected
  void handleSelection() {
    /// [ContentSelectionController.dispose] delays the controller disposal
    /// to animate keep closing animation, so it is valid (unless it was
    /// triggered in unmounted state in some other way).
    if (mounted) {
      setState(() {/* tiles on selection */});
    }
  }

  /// Listens to [SelectionController.addStatusListener].
  /// By default just calls [setState].
  @protected
  void handleSelectionStatus(AnimationStatus status) {
    /// [ContentSelectionController.dispose] delays the controller disposal
    /// to animate keep closing animation, so it is valid (unless it was
    /// triggered in unmounted state in some other way).
    if (mounted) {
      setState(() {/* update appbar and tiles on selection status */});
    }
  }
}

/// Mixin this to a widget state to make it support selection.
///
/// You also must mixin [SelectableWidget] to the parent of this widget,
/// to properly update the selection state of this widget.
abstract class SelectableWidget<T> extends StatefulWidget {
  /// Creates a widget, not selectable.
  const SelectableWidget({
    Key? key,
  }) : selected = null,
       selectionController = null,
       super(key: key);

  /// Creates a selectable widget.
  const SelectableWidget.selectable({
    Key? key,
    required this.selectionController,
    this.selected = false,
  }) : super(key: key);

  /// Makes tiles aware whether they are selected in some global set.
  /// This will be used on first build, after this tile will have internal selection state.
  final bool? selected;

  /// A controller that drive the selection.
  /// 
  /// If `null`, widget will be considered as not selectable
  final SelectionController<T>? selectionController;

  /// Converts this widget to the entry [selectionController] is holding.
  T toSelectionEntry();

  @override
  // TODO: remove this ignore when https://github.com/dart-lang/linter/issues/2345 is resolved
  // ignore: no_logic_in_create_state
  State<SelectableWidget<T>> createState();
}

/// A state to be used with [SelectableWidget].
abstract class SelectableState<T extends SelectableWidget> extends State<T> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Returns animation that can be used for animating the selection.
  /// 
  /// The [SelectableWidget] may likely be used in large lists, hence initializing
  /// an animation in build method would be quite expensive.
  /// 
  /// To avoid this, animation is instantiated in [initState].
  /// 
  /// See also:
  /// * [buildAnimation] that build the animation object
  Animation<double> get animation => _animation;
  late Animation<double> _animation;

  /// Whether the widget is currently being selected.
  bool get selected => _selected;
  late bool _selected;

  /// Whether the widget can be selected.
  bool get selectable => widget.selectionController != null;

  @override
  void initState() { 
    super.initState();
    if (!selectable)
      return;
    _selected = widget.selected ?? false;
    _controller = AnimationController(vsync: this, duration: kSelectionDuration);
    _animation = buildAnimation(_controller);
    if (_selected) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectable) {
      if (widget.selectionController!.notInSelection && _selected) {
        /// We have to check if controller is closing, i.e. user pressed global close button to quit the selection.
        ///
        /// We are assuming that parent updates us, as we can't add owr own status listener to the selection controller,
        /// because it is quite expensive for the list.
        _selected = false;
        _controller.value = widget.selectionController!.animationController.value;
        _controller.reverse();
      } else if (oldWidget.selected != widget.selected) {
        _selected = widget.selected ?? false;
        if (_selected) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    if (selectable)
      _controller.dispose();
    super.dispose();
  }

  /// Builds an [animation].
  /// 
  /// The `animation` is the bare, without any applied curves.
  /// 
  /// Override this method to build your own custom animation.
  Animation<double> buildAnimation(Animation<double> animation) {
    return Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    ));
  }

  /// Returns a aethod that either joins the selection, or closes it, dependent
  /// on current state of [selected].
  /// 
  /// Will return null if not [selectable], because it is common to pass it to [ListTile.onLongPress],
  /// and passing null will disable the long press gesture.
  VoidCallback? get toggleSelection => !selectable ? null : () {
    if (!selectable)
      return;
    setState(() {
      _selected = !_selected;
    });
    if (_selected)
      _select();
    else
      _unselect();
  };

  /// Checks whether widget is selectable and the selection controller
  /// is currently in selection.
  /// 
  /// If yes, on taps will be handled by calling [toggleSelection],
  /// otherwise calls the [onTap] callback.
  void handleTap(VoidCallback onTap) {
    if (selectable && widget.selectionController!.inSelection) {
      toggleSelection!();
    } else {
      onTap();
    }
  }

  void _select() {
    widget.selectionController!.selectItem(widget.toSelectionEntry());
    _controller.forward();
  }

  void _unselect() {
    widget.selectionController!.unselectItem(widget.toSelectionEntry());
    _controller.reverse();
  }
}

/// Signature, used for [ContentSelectionController.actionsBuilder].
typedef _ActionsBuilder = _SelectionActionsBar Function(BuildContext);

class ContentSelectionController<T extends SelectionEntry> extends SelectionController<T> {
  ContentSelectionController._({
    required AnimationController animationController,
    required this.actionsBuilder,
    required this.context,
    this.ignoreWhen,
    Set<T>? data,
  }) : super(
         animationController: animationController,
         data: data,
       );

  /// Will build selection controls overlay widget.
  final _ActionsBuilder actionsBuilder;

  /// Needed to listen listen to a [DismissibleRoute], and as soon as it's
  /// dismissed, the selection will be closed.
  final BuildContext context;

  /// Before entering selection, controller will check this getter, and if it
  /// returns `true`, selection will be cancelled out.
  ///
  /// This is needed, beucase in lists I allow multiple gestures at once, and if user holds one finger
  /// and then taps tile with another finger, this will cause the selection menu to
  /// be displayed over player route, which is not wanted.
  final ValueGetter<bool>? ignoreWhen;

  /// Notifies about changes of [primaryContentType].
  ValueListenable<Type?> get onContentTypeChange => _primaryContentTypeNotifier;
  final ValueNotifier<Type?> _primaryContentTypeNotifier = ValueNotifier(null);

  /// Current primary content type for when `T` is [Content], and not
  /// specific subclass of it, like [Song]. It is an error to set this
  /// value when `T` not [Content].
  ///
  /// When [Content] is being used in this way, that means that multiple
  /// types of content can be selected, and in some cases, there can be
  /// a situation some of the content type is primarily shown to user
  /// (and standalone, without other content types).
  ///
  /// For example in tabs route the that denotes the currently selected tab,
  /// or in search route that denotes currently filtered content type.
  Type? get primaryContentType => _primaryContentTypeNotifier.value;
  set primaryContentType(Type? value) {
    assert(T != Content, 'T must be a subclass of Content');
    _primaryContentTypeNotifier.value = value;
  }

  /// Constucts a controller for particular `T` [Content] type.
  ///
  /// Generally, it's recommended to pass navigator state to [vsync], so controller can
  /// safely make deferred disposal.
  /// 
  /// If [counter] is `true`, will show a couter in the title.
  /// 
  /// If [closeButton] is  `true`, will show a selection close button in the title.
  @factory
  static ContentSelectionController<SelectionEntry<T>> create<T extends Content>({
    required TickerProvider vsync,
    required BuildContext context,
    bool counter = false,
    bool closeButton = false,
    ValueGetter<bool>? ignoreWhen,
  }) {
    final getActions = contentPick<T, ValueGetter<List<Widget>>>(
      song: () => const [
        _GoToAlbumSelectionAction(),
        _PlayNextSelectionAction<Song>(),
        _AddToQueueSelectionAction<Song>(),
      ],
      album: () => const [
        _PlayNextSelectionAction<Album>(),
        _AddToQueueSelectionAction<Album>(),
      ],
      playlist: () => const [
        _PlayNextSelectionAction<Playlist>(),
        _AddToQueueSelectionAction<Playlist>(),
      ],
      artist: () => const [],
      fallback: () =>  const [
        _GoToAlbumSelectionAction(),
        _PlayNextSelectionAction(),
        _AddToQueueSelectionAction(),
      ],
    );
    return ContentSelectionController<SelectionEntry<T>>._(
      ignoreWhen: ignoreWhen,
      context: context,
      animationController: AnimationController(
        vsync: vsync,
        duration: kSelectionDuration,
      ),
      actionsBuilder: (context) {
        return _SelectionActionsBar(
          left: [_ActionsSelectionTitle(
            counter: counter,
            closeButton: closeButton,
          )],
          right: getActions(),
        );
      },
    );
  }

  static ContentSelectionController _of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<_ContentSelectionControllerProvider>()!
      .widget as _ContentSelectionControllerProvider;
    return widget.controller;
  }

  Color? _lastNavColor;
  OverlayEntry? _overlayEntry;
  SlidableController? _dismissibleRouteController;
  ValueNotifier<ContentSelectionController?> get _notifier => ContentControl.state.selectionNotifier;

  @override
  void notifyStatusListeners(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      if (ignoreWhen?.call() ?? false) {
        close();
        return;
      }
      if (_notifier.value != null && _notifier.value != this) {
        // Close previous selection.
        _notifier.value!.close();
        assert(false, 'There can only be one active controller');
      }
      _dismissibleRouteController = DismissibleRoute.controllerOf(context);
      _dismissibleRouteController?.addDragEventListener(_handleDismissibleRouteDrag);
      _overlayEntry = OverlayEntry(
        builder: (context) => _ContentSelectionControllerProvider(
          controller: this,
          child: Builder(
            builder: (_context) => Builder(
            builder: (_context) => actionsBuilder(_context),
          ),
          ),
        ),
      );
      HomeState.overlayKey.currentState!.insert(_overlayEntry!);
      _notifier.value = this;

      // Animate system UI
      final lastUi = SystemUiStyleController.lastUi;
      _lastNavColor = lastUi.systemNavigationBarColor;
      SystemUiStyleController.animateSystemUiOverlay(
        to: lastUi.copyWith(
          systemNavigationBarColor: Constants.UiTheme.grey.auto.systemNavigationBarColor
        ),
        duration: kSelectionDuration,
        curve: _SelectionActionsBar.forwardCurve,
      );
    } else if (status == AnimationStatus.reverse) {
      if (!ContentControl.disposed) {
        _notifier.value = null;
      }
      _animateNavBack();
    } else if (status == AnimationStatus.dismissed) {
      _removeOverlay();
    }
    super.notifyStatusListeners(status);
  }

  void _handleDismissibleRouteDrag(SlidableDragEvent event) {
    if (event is SlidableDragEnd && event.closing) {
      close();
    }
  }

  void _animateNavBack() {
    if (_lastNavColor == null)
      return;
    SystemUiStyleController.animateSystemUiOverlay(
      to: SystemUiStyleController.lastUi.copyWith(
        systemNavigationBarColor: _lastNavColor,
      ),
      duration: kSelectionDuration,
      curve: _SelectionActionsBar.reverseCurve.flipped,
    );
    _lastNavColor = null;
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animateNavBack();
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _dismissibleRouteController?.removeDragEventListener(_handleDismissibleRouteDrag);
    _dismissibleRouteController = null;
    if (ContentControl.disposed) {
      _removeOverlay();
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        _primaryContentTypeNotifier.dispose();
      });
      super.dispose();
    } else {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        _notifier.value = null;
        _primaryContentTypeNotifier.dispose();
        if (inSelection)
          await close();
        _removeOverlay();
        super.dispose();
      });
    }
  }
} 

class _ContentSelectionControllerProvider extends InheritedWidget {
  _ContentSelectionControllerProvider({
    required Widget child,
    required this.controller,
    }) : super(child: child);

  final ContentSelectionController controller;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// Creats a selection controller and automatically rebuilds, when it updates.
class ContentSelectionControllerCreator<T extends Content> extends StatefulWidget {
  ContentSelectionControllerCreator({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget Function(BuildContext context, ContentSelectionController<SelectionEntry<T>> selectionController, Widget? child) builder;
  final Widget? child;

  @override
  _SelectionControllerCreatorState<T> createState() => _SelectionControllerCreatorState();
}

class _SelectionControllerCreatorState<T extends Content> extends State<ContentSelectionControllerCreator<T>>
    with SelectionHandler {
  late final ContentSelectionController<SelectionEntry<T>> controller; 

  @override
  void initState() { 
    super.initState();
    controller = ContentSelectionController.create<T>(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      context: context,
      closeButton: true,
      counter: true,
      ignoreWhen: () => playerRouteController.opened,
    )
      ..addListener(handleSelection);
  }

  @override
  void dispose() { 
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, controller, widget.child);
  }
}

class SelectionCheckmark extends StatefulWidget {
  const SelectionCheckmark({
    Key? key,
    required this.animation,
    this.size = 21.0,
  }) : super(key: key);

  final Animation<double> animation;
  final double size;

  @override
  _SelectionCheckmarkState createState() => _SelectionCheckmarkState();
}

class _SelectionCheckmarkState extends State<SelectionCheckmark> {
  String _flareAnimation = 'stop';

  @override
  void initState() {
    super.initState();
    _update();
    widget.animation.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateWidget(covariant SelectionCheckmark oldWidget) {
    if (oldWidget.animation != widget.animation) {
      _update();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatusChange);
    super.dispose();
  }

  void _update() {
    if (widget.animation.status == AnimationStatus.forward) {
      _flareAnimation = 'play';
    }
  }

  void _handleStatusChange(AnimationStatus status) {
    _update();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) => ScaleTransition(
          scale: widget.animation,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            color: Constants.AppColors.androidGreen,
            borderRadius: BorderRadius.all(Radius.circular(200.0)),
          ),
          child: FlareActor(
            Constants.Assets.ASSET_ANIMATION_CHECKMARK,
            animation: _flareAnimation,
            color: ThemeControl.theme.colorScheme.secondaryVariant,
            callback: (name) {
              setState(() {
                _flareAnimation = 'stop';
              });
            },
          ),
        ),
      ),
    );
  }
}

/// Ignores its subtree when selection controller is in selection.
class IgnoreInSelection extends StatelessWidget {
  const IgnoreInSelection({
    Key? key,
    required this.controller,
    this.child,
  }) : super(key: key);

  final Widget? child;
  final SelectionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimationStrategyBuilder<bool>(
      strategy: const IgnoringStrategy(
        forward: true,
        completed: true,
      ),
      animation: controller.animationController,
      child: child,
      builder: (context, value, child) => IgnorePointer(
        ignoring: value,
        child: child
      ),
    );
  }
}

class _SelectionActionsBar extends StatelessWidget {
  const _SelectionActionsBar({
    Key? key,
    this.left = const [],
    this.right = const [],
  }) : super(key: key);

  final List<Widget> left;
  final List<Widget> right;

  static const forwardCurve = Interval(
    0.0,
    0.7,
    curve: Curves.easeOutCubic,
  );
  static const reverseCurve = Interval(
    0.0,
    0.5,
    curve: Curves.easeIn,
  );

  @override
  Widget build(BuildContext context) {
    final selectionAnimation = ContentSelectionController._of(context).animationController;
    final fadeAnimation = CurvedAnimation(
      curve: forwardCurve,
      reverseCurve: reverseCurve,
      parent: selectionAnimation,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimationStrategyBuilder<bool>(
        strategy: const IgnoringStrategy(
          reverse: true,
          dismissed: true,
        ),
        animation: selectionAnimation,
        builder: (context, value, child) => IgnorePointer(
          ignoring: value,
          child: child,
        ),
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Container(
            height: kSongTileHeight,
            color: ThemeControl.theme.colorScheme.secondary,
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: left),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: right,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionAnimation extends AnimatedWidget {
  _SelectionAnimation({
    required Animation<double> animation,
    required this.child,
    this.begin = const Offset(-1.0, 0.0),
    this.end = Offset.zero,
  }) : super(listenable: animation);

  final Widget child;
  final Offset begin;
  final Offset end;

  @override
  Animation<double> get listenable => super.listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final animation = Tween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: listenable,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    return ClipRect(
      child: AnimationStrategyBuilder<bool>(
        strategy: const IgnoringStrategy(
          dismissed: true,
          reverse: true,
        ),
        animation: listenable,
        child: SlideTransition(
          position: animation,
          child: child,
        ),
        builder: (context, value, child) => IgnorePointer(
          ignoring: value,
          child: child,
        ),
      ),
    );
  }
}

class _ActionSupported extends StatefulWidget {
  _ActionSupported({
    Key? key,
    required this.shown,
    required this.controller,
    required this.child,
  }) : super(key: key);

  /// Condition to check whether the action should be shown or not.
  final ValueGetter<bool> shown;

  final ContentSelectionController controller;

  final Widget child;

  @override
  _ActionSupportedState createState() => _ActionSupportedState();
}

class _ActionSupportedState extends State<_ActionSupported> with SelectionHandler {
  UniqueKey key = UniqueKey();
  bool shown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(handleSelection);
  }

  @override
  void didUpdateWidget(covariant _ActionSupported oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(handleSelection);
      widget.controller.addListener(handleSelection);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(handleSelection);
    super.dispose();
  }

  @override
  void handleSelection() {
    if (widget.controller.data.length == 1 && widget.controller.lengthIncreased) {
      // Prevents animation we enter the selection by updating the key
      key = UniqueKey();
    }
    super.handleSelection();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.inSelection) {
      /// The condition ensures animation will not play on close, because [SelectionAppBar]
      /// has its own animation, and combination of them both doesn't look good.
      shown = widget.shown();
    }
    return AnimatedSwitcher(
      key: key,
      duration: kSelectionDuration,
      transitionBuilder: (child, animation) => _SelectionAnimation(
        animation: animation,
        child: child,
      ),
      child: !shown
        ? const SizedBox.shrink()
        : widget.child,
    );
  }
}

/// Creates a selection title.
class _ActionsSelectionTitle extends StatelessWidget {
  const _ActionsSelectionTitle({
    Key? key,
    this.counter = false,
    this.closeButton = false,
  }) : super(key: key);

  /// If true, in place of "Actions" label, [SelectionCounter] will be shown.
  final bool counter;

  /// If true, will show a selection close button.
  final bool closeButton;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return Row(
      children: [
        if (closeButton)
          _SelectionAnimation(
            animation: controller.animationController,
            child: NFIconButton(
              size: NFConstants.iconButtonSize,
              iconSize: NFConstants.iconSize,
              color: ThemeControl.theme.colorScheme.onSurface,
              onPressed: () => controller.close(),
              icon: const Icon(Icons.close),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(
            left: counter ? 10.0 : 8.0,
            bottom: 2.0
          ),
          child: _SelectionAnimation(
            animation: controller.animationController,
            child: !counter
              ? Text(l10n.actions)
              : const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: SelectionCounter()
                ),
          ),
        ),
      ],
    );
  }
}

/// Creates a counter that shows how many items are selected.
class SelectionCounter extends StatefulWidget {
  const SelectionCounter({Key? key, this.controller}) : super(key: key);

  /// Selection controller, if none specified, will try to fetch it from context.
  final ContentSelectionController? controller;

  @override
  _SelectionCounterState createState() => _SelectionCounterState();
}

class _SelectionCounterState extends State<SelectionCounter> with SelectionHandler {
  late ContentSelectionController controller;
  late int selectionCount;
  UniqueKey key = UniqueKey();

  @override
  void initState() { 
    super.initState();
    controller = widget.controller ?? ContentSelectionController._of(context);
    controller.addListener(handleSelection);
    selectionCount = max(1, controller.data.length);
  }

  @override
  void didUpdateWidget(covariant SelectionCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(handleSelection);
      controller = widget.controller ?? ContentSelectionController._of(context);
      controller.addListener(handleSelection);
    }
  }

  @override
  void dispose() { 
    controller.removeListener(handleSelection);
    super.dispose();
  }

  @override
  void handleSelection() {
    if (controller.data.length == 1 && controller.lengthIncreased) {
      // Prevents animation we enter the selection by updating the key
      key = UniqueKey();
    }
    super.handleSelection();
  }

  @override
  Widget build(BuildContext context) {
    // This will prevent animation when controller is closing
    if (controller.inSelection) {
      // Not letting to go less 1 to not play animation from 1 to 0
      selectionCount = max(1, controller.data.length);
    }
    return CountSwitcher(
      key: key,
      childKey: ValueKey(selectionCount),
      valueIncreased: controller.lengthIncreased,
      child: Container(
        /// Line up width with other actions, so they animate identically with [_SelectionAnimation]
        constraints: const BoxConstraints(minWidth: NFConstants.iconButtonSize),
        padding: const EdgeInsets.only(left: 5.0),
        child: Text(
          selectionCount.toString(),
          style: appBarTitleTextStyle,
        ),
      ),
    );
  }
}

//************** ACTIONS **************

//*********** Queue actions ***********

/// Action that queues a [Song] or [Album] to be played next.
class _PlayNextSelectionAction<T extends Content> extends StatelessWidget {
  const _PlayNextSelectionAction({Key? key}) : super(key: key);

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty)
      return;
    entries.sort((a, b) => a.index!.compareTo(b.index!));
    ContentControl.playNext(
      entries
        .map((el) => el.data)
        .toList(),
    );
  }

  void _handleOrigins(List<SelectionEntry<SongOrigin>> entries) {
    if (entries.isEmpty)
      return;
    // Reverse order is proper here
    entries.sort((a, b) => b.index!.compareTo(a.index!));
    for (final entry in entries) {
      ContentControl.playOriginNext(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    contentPick<T, VoidCallback>(
      song: () => _handleSongs(controller.data.toList() as List<SelectionEntry<Song>>),
      album: () => _handleOrigins(controller.data.toList() as List<SelectionEntry<Album>>),
      playlist: () => _handleOrigins(controller.data.toList() as List<SelectionEntry<Playlist>>),
      artist: () => throw ArgumentError('This actions doesn support artists'),
      fallback: () {
        final List<SelectionEntry<Content>> entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        final List<SelectionEntry<Playlist>> playlists = [];
        final List<SelectionEntry<Artist>> artists = [];
        for (final entry in entries) {
          if (entry is SelectionEntry<Song>) {
            songs.add(entry);
          } else if (entry is SelectionEntry<Album>) {
            albums.add(entry);
          } else if (entry is SelectionEntry<Playlist>) {
            playlists.add(entry);
          } else if (entry is SelectionEntry<Artist>) {
            artists.add(entry);
          } else {
            throw UnimplementedError('Unsupported selection');
          }
        }
        _handleSongs(songs);
        _handleOrigins(albums);
        _handleOrigins(playlists);
        _handleOrigins(artists);
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _SelectionAnimation(
      animation: controller.animationController,
      child: NFIconButton(
        tooltip: l10n.playNext,
        icon: const Icon(Icons.playlist_play_rounded),
        iconSize: 30.0,
        onPressed: () => _handleTap(controller),
      ),
    );
  }
}

/// Action that adds a [Song] or an [Album] to the end of the queue.
class _AddToQueueSelectionAction<T extends Content>  extends StatelessWidget {
  const _AddToQueueSelectionAction({Key? key})
      : super(key: key);

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty)
      return;
    entries.sort((a, b) => a.index!.compareTo(b.index!));
    ContentControl.addToQueue(
      entries
        .map((el) => el.data)
        .toList(),
    );
  }

  void _handleOrigins(List<SelectionEntry<SongOrigin>> entries) {
    if (entries.isEmpty)
      return;
    // Reverse order is proper here
    entries.sort((a, b) => b.index!.compareTo(a.index!));
    for (final entry in entries) {
      ContentControl.playOriginNext(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    contentPick<T, VoidCallback>(
      song: () => _handleSongs(controller.data.toList() as List<SelectionEntry<Song>>),
      album: () => _handleOrigins(controller.data.toList() as List<SelectionEntry<Album>>),
      playlist: () => _handleOrigins(controller.data.toList() as List<SelectionEntry<Playlist>>),
      artist: () => throw ArgumentError('This actions doesn support artists'),
      fallback: () {
        final List<SelectionEntry<Content>> entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        final List<SelectionEntry<Playlist>> playlists = [];
        final List<SelectionEntry<Artist>> artists = [];
        for (final entry in entries) {
          if (entry is SelectionEntry<Song>) {
            songs.add(entry);
          } else if (entry is SelectionEntry<Album>) {
            albums.add(entry);
          } else if (entry is SelectionEntry<Playlist>) {
            playlists.add(entry);
          } else if (entry is SelectionEntry<Artist>) {
            artists.add(entry);
          } else {
            throw UnimplementedError('Unsupported selection');
          }
        }
        _handleSongs(songs);
        _handleOrigins(albums);
        _handleOrigins(playlists);
        _handleOrigins(artists);
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _SelectionAnimation(
      animation: controller.animationController,
      child: NFIconButton(
        tooltip: l10n.addToQueue,
        icon: const Icon(Icons.queue_music_rounded),
        iconSize: 30.0,
        onPressed: () => _handleTap(controller),
      ),
    );
  }
}

//*********** Navigation actions ***********

/// Action that leads to the song album.
class _GoToAlbumSelectionAction extends StatefulWidget {
  const _GoToAlbumSelectionAction({Key? key}) : super(key: key);

  @override
  _GoToAlbumSelectionActionState createState() => _GoToAlbumSelectionActionState();
}

class _GoToAlbumSelectionActionState extends State<_GoToAlbumSelectionAction> {
  late ContentSelectionController controller;

  @override
  void initState() { 
    super.initState();
    controller = ContentSelectionController._of(context);
    assert(controller is ContentSelectionController<SelectionEntry<Content>> ||
           controller is ContentSelectionController<SelectionEntry<Song>>);
  }

  void _handleTap() {
    final song = controller.data.first.data as Song;
    final album = song.getAlbum();
    if (album != null) {
      HomeRouter.instance.goto(HomeRoutes.factory.content<Album>(album));
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final data = controller.data;

    return _ActionSupported(
      controller: controller,
      shown: () {
        return data.length == 1 &&
          data.first.data is Song && (data.first.data as Song).albumId != null &&
          (HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.album) || playerRouteController.opened); // disable action in album route
      },
      child: _SelectionAnimation(
        animation: controller.animationController,
        child: NFIconButton(
          tooltip: l10n.goToAlbum,
          icon: const Icon(Icons.album_rounded),
          iconSize: 23.0,
          onPressed: _handleTap,
        ),
      ),
    );
  }
}

//*********** Content related actions (always in app bar) ***********

/// Displays an action to delete songs.
/// Only meant to be displayed in app bar.
/// 
/// Can receive either [controller] with [Song]s selection, or with gerenric [Content] type.
/// With the lattter, will automatically check if selection contains only songs and hide the button, if not.
class DeleteSongsAppBarAction<T extends Content> extends StatefulWidget {
  const DeleteSongsAppBarAction({
    Key? key,
    required this.controller
  }) : super(key: key);

  final ContentSelectionController<SelectionEntry<T>> controller;

  @override
  _DeleteSongsAppBarActionState<T> createState() => _DeleteSongsAppBarActionState();
}

class _DeleteSongsAppBarActionState<T extends Content> extends State<DeleteSongsAppBarAction<T>> with SelectionHandler {
  late Type type;

  @override
  void initState() { 
    super.initState();
    type = typeOf<T>();
    assert(type == Song || type == Content, 'Only Song and Content types are supported');
  }

  Future<void> _handleDelete() async {
    final songs = widget.controller.data.cast<SelectionEntry<Song>>();
    if (ContentControl.sdkInt >= 30) {
      // On Android R the deletion is performed with OS dialog.
      await ContentControl.deleteSongs(songs.map((e) => e.data.sourceId).toSet());
      widget.controller.close();
    } else {
      // On all versions below show in app dialog.
      final l10n = getl10n(context);
      final count = songs.length;
      Song? song;
      if (count == 1) {
        song = ContentControl.state.allSongs.byId.get(songs.first.data.sourceId);
      }
      ShowFunctions.instance.showDialog(
        context,
        title: Text(
          '${l10n.delete} ${count > 1 ? count.toString() + ' ' : ''}${l10n.tracksPlural(count).toLowerCase()}',
        ),
        content: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 15.0),
            children: [
              TextSpan(text: l10n.deletionPromptDescriptionP1),
              TextSpan(
                text: song != null
                    ? '${song.title}?'
                    : l10n.deletionPromptDescriptionP2,
                style: song != null
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
            ],
          ),
        ),
        buttonSplashColor: Constants.Theme.glowSplashColor.auto,
        acceptButton: NFButton.accept(
          text: l10n.delete,
          splashColor: Constants.Theme.glowSplashColor.auto,
          textStyle: const TextStyle(color: Constants.AppColors.red),
          onPressed: () {
            ContentControl.deleteSongs(songs.map((e) => e.data.sourceId).toSet());
            widget.controller.close();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionSupported(
      controller: widget.controller,
      shown: () {
        return type == Song ||
              (type == Content &&
              widget.controller.data.firstWhereOrNull((el) => el is SelectionEntry<Album>) == null);
      },
      child: NFIconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: _handleDelete,
      ),
    );
  }
}
