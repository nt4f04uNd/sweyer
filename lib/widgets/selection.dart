import 'dart:math' as math;

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:boxy/boxy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:styled_text/styled_text.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

// See selection actions logic overview here
// https://docs.google.com/spreadsheets/d/1LYJ5Abb1zWhYMAUs0zRjx-aiMwJn-3XLS2NjoqV5le8

/// Selection animation duration.
const Duration kSelectionDuration = Duration(milliseconds: 350);

/// Whether the [SelectionRoute] is currently opened in the given [context].
///
/// See [SelectableState.selectionRoute] for discussion of how selection works
/// when this is `true`.
bool selectionRouteOf(context) {
  return HomeRouter.maybeOf(context)?.selectionArguments != null;
}

/// A mixin for easy creation of [ContentSelectionController] and
/// connection with [SelectionRoute] selection controller.
///
/// Usually this is a creator of [SelectionWidget].
///
/// For example see [TabsRoute].
mixin SelectionHandlerMixin<T extends StatefulWidget> on State<T> {
  /// The selection controller initialized within [initSelectionController].
  late ContentSelectionController selectionController;

  /// Home router of context.
  late HomeRouter? homeRouter = HomeRouter.maybeOf(context);

  /// Whether the [SelectionRoute] is currently opened in this context.
  bool get selectionRoute => homeRouter?.selectionArguments != null;

  ContentType? _savedPrimaryContentType;

  /// Creates a selection controller.
  ///
  /// If [selectionRoute] is currently `true`, will instead listen to the
  /// existing controller the selection route provides.
  ///
  /// If [listen] is `true`, the [handleSelection] is attached to the controller.
  /// If [listenStatus] is `true`, the [handleSelectionStatus] is attached to the controller.
  void initSelectionController<C extends Content>(
    ValueGetter<ContentSelectionController<SelectionEntry<C>>> factory, {
    bool listen = true,
    bool listenStatus = false,
  }) {
    if (selectionRoute) {
      selectionController = homeRouter!.selectionArguments!.selectionController;
      _savedPrimaryContentType = selectionController.primaryContentType;
    } else {
      selectionController = factory();
    }
    if (listen) {
      selectionController.addListener(handleSelection);
    }
    if (listenStatus) {
      selectionController.addStatusListener(handleSelectionStatus);
    }
  }

  /// Disposes the created selection controller, or, when [selectionRoute] is `true`,
  /// stops listening to the one selection route has provided.
  void disposeSelectionController() {
    if (selectionRoute) {
      selectionController.removeListener(handleSelection);
      selectionController.removeStatusListener(handleSelectionStatus);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        selectionController.primaryContentType = _savedPrimaryContentType;
      });
    } else {
      selectionController.dispose();
    }
  }

  /// Listens to [SelectionController.addListener].
  /// By default just calls [setState].
  ///
  /// Can be automatically bound with [initSelectionController].
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
  ///
  /// Can be automatically bound with [initSelectionController].
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
  })  : selectionIndex = null,
        selected = null,
        longPressSelectionGestureEnabled = null,
        handleTapInSelection = null,
        selectionController = null,
        super(key: key);

  /// Creates a selectable widget.
  const SelectableWidget.selectable({
    Key? key,
    required int this.selectionIndex,
    required bool this.selected,
    required bool this.longPressSelectionGestureEnabled,
    required bool this.handleTapInSelection,
    required this.selectionController,
  }) : super(key: key);

  /// The index to pass to [SelectionEntry] in [SelectableState.toSelectionEntry].
  final int? selectionIndex;

  /// Makes tiles aware whether they are selected in some global set.
  /// This will be used on first build, after this tile will have internal selection state.
  final bool? selected;

  /// Whether the long press selection gesture is enabled.
  ///
  /// Will be force treated as `false` if [selectionRouteOf] is `true`.
  final bool? longPressSelectionGestureEnabled;

  /// Whether in selection the tap handling is enabled.
  ///
  /// Set this to `false` if there's a need to preserve the ability of user to
  /// perform default tile tap actions in selection, and instead have some custom
  /// for selection button for example in the tile trailing.
  ///
  /// Will be force treated as `false` if [selectionRouteOf] is `true`.
  final bool? handleTapInSelection;

  /// A controller that drive the selection.
  ///
  /// If `null`, widget will be considered as not selectable
  final SelectionController<T>? selectionController;

  @override
  State<SelectableWidget<T>> createState();
}

/// A state to be used with [SelectableWidget].
abstract class SelectableState<E, W extends SelectableWidget> extends State<W> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Returns animation that can be used for animating the selection.
  ///
  /// The [SelectableWidget] may likely be used in large lists, hence initializing
  /// an animation in build method would be quite expensive.
  ///
  /// To avoid this, animation is instantiated in [initState].
  ///
  /// See also:
  /// * [buildAnimation] that builds the animation
  Animation<double> get animation => _animation;
  late Animation<double> _animation;

  /// Whether the widget is currently being selected.
  bool get selected =>
      selectable && (_controller.status == AnimationStatus.forward || _controller.status == AnimationStatus.completed);

  /// Used to update the [selected] value when the widget updates.
  ///
  /// When returns null, not used.
  bool? get widgetSelected => null;

  /// Whether the widget can be selected.
  bool get selectable => widget.selectionController != null;

  /// Whether the widget is inside the selection route and is [selectable].
  ///
  /// When this is true the default scheme when the [SelectableWidget.index]
  /// is passed to [toSelectionEntry] is ignored and custom rules are defined.
  ///
  /// Specifically:
  ///  * songs from [SongOrigin]s are assigned with the index of them in global state,
  ///    same for other content, so for example when song in album is selected, it is
  ///    also selected in the all songs screen
  ///  * the method above is not suitable for [DuplicatingSongOriginMixin], such as
  ///    playlists, and content inside them should be considered unique.
  ///    To accomplish that by [DuplicatingSongOriginMixin] the entry also receives
  ///    the [SelectionEntry.origin], so the entries selected in it are scoped to this
  ///    particular origin.
  bool get selectionRoute => selectable && selectionRouteOf(context);

  /// Converts this widget to the entry [selectionController] is holding.
  ///
  /// See also a discussion in [SelectionEntry].
  E toSelectionEntry();

  @override
  void initState() {
    super.initState();
    if (!selectable) {
      return;
    }
    _controller = AnimationController(vsync: this, duration: kSelectionDuration);
    _animation = buildAnimation(_controller);
    if (widgetSelected ?? widget.selected!) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    if (selectable) {
      if (widget.selectionController!.notInSelection && selected) {
        /// We have to check if controller is closing, i.e. user pressed global close button to quit the selection.
        ///
        /// We are assuming that parent updates us, as we can't add owr own status listener to the selection controller,
        /// because it is quite expensive for the list.
        _controller.value = widget.selectionController!.animation.value;
        _controller.reverse();
      } else {
        final localWidgetSelected = widgetSelected;
        if (oldWidget.selected != (localWidgetSelected ?? widget.selected)) {
          if (localWidgetSelected ?? widget.selected!) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (selectable) {
      _controller.dispose();
    }
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

  /// Returns a method that either joins the selection, or closes it, dependent
  /// on current state of [selected].
  ///
  /// Will return null if not [selectable], because it is common to pass it to [ListTile.onLongPress],
  /// and passing null will disable the long press gesture.
  VoidCallback? get handleLongPress =>
      !selectable || selectionRouteOf(context) || !widget.longPressSelectionGestureEnabled!
          ? null
          : () {
              if (!selectable) {
                return;
              }
              toggleSelection();
            };

  /// Checks whether widget is selectable and the selection controller
  /// is currently in selection.
  ///
  /// If yes, on taps will be handled by calling [toggleSelection],
  /// otherwise calls the [onTap] callback.
  void handleTap(VoidCallback onTap) {
    if (selectable &&
        !selectionRouteOf(context) &&
        widget.selectionController!.inSelection &&
        widget.handleTapInSelection!) {
      toggleSelection();
    } else {
      onTap();
    }
  }

  void toggleSelection() {
    setState(() {
      if (selected) {
        unselect();
      } else {
        select();
      }
    });
  }

  void select() {
    widget.selectionController!.selectItem(toSelectionEntry());
    _controller.forward();
  }

  void unselect() {
    widget.selectionController!.unselectItem(toSelectionEntry());
    _controller.reverse();
  }
}

/// Signature, used for [ContentSelectionController.actionsBuilder].
typedef _ActionsBuilder = _SelectionActionsBar Function(BuildContext);

class ContentSelectionController<T extends SelectionEntry> extends SelectionController<T> with RouteAware {
  ContentSelectionController._({
    required AnimationController animationController,
    required this.context,
    required this.actionsBuilder,
    this.overlay,
    this.ignoreWhen,
    Set<T>? data,
  }) : super(
          animationController: animationController,
          data: data,
        );

  ContentSelectionController._alwaysInSelection({
    required this.context,
    required this.actionsBuilder,
    this.overlay,
    Set<T>? data,
  })  : ignoreWhen = null,
        super.alwaysInSelection(data: data);

  /// Needed to listen listen to a [DismissibleRoute], and as soon as it's
  /// dismissed, the selection will be closed.
  final BuildContext context;

  /// Will build selection controls overlay widget.
  final _ActionsBuilder? actionsBuilder;

  /// An overlay to use. By default the one provided by [HomeState.overlayKey]
  /// is used.
  OverlayState? overlay;

  /// Before entering selection, controller will check this getter, and if it
  /// returns `true`, selection will be cancelled out.
  ///
  /// This is needed, because in lists I allow multiple gestures at once, and if user holds one finger
  /// and then taps tile with another finger, this will cause the selection menu to
  /// be displayed over player route, which is not wanted.
  final ValueGetter<bool>? ignoreWhen;

  /// Notifies about changes of [primaryContentType].
  ValueListenable<ContentType?> get onContentTypeChange => _primaryContentTypeNotifier;
  final ValueNotifier<ContentType?> _primaryContentTypeNotifier = ValueNotifier(null);

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
  ContentType? get primaryContentType => _primaryContentTypeNotifier.value;
  set primaryContentType(ContentType? value) {
    _primaryContentTypeNotifier.value = value;
  }

  /// Constructs a controller for particular `T` [Content] type.
  ///
  /// Generally, it's recommended to pass navigator state to [vsync], so controller can
  /// safely make deferred disposal.
  ///
  /// By default controller automatically creates a selection actions bar overlay.
  /// The [actionsBar] can be set to `false` to disable this behavior.
  ///
  /// By default actions bar is filled with a few default actions,
  /// which should always be visible. The [additionalPlayActionsBuilder] parameter
  /// allows to add additional actions just before the "play next" and "add to queue" actions.
  ///
  /// If [counter] is `true`, will show a counter in the actions bar title.
  ///
  /// If [closeButton] is `true`, will show a selection close button in the actions bar.
  ///
  /// For other parameters, see the class properties.
  @factory
  static ContentSelectionController<SelectionEntry<T>> create<T extends Content>({
    required TickerProvider vsync,
    required BuildContext context,
    ContentType<T>? contentType,
    bool actionsBar = true,
    List<Widget> Function(BuildContext)? additionalPlayActionsBuilder,
    bool counter = false,
    bool closeButton = false,
    ValueGetter<bool>? ignoreWhen,
  }) {
    return ContentSelectionController<SelectionEntry<T>>._(
      context: context,
      ignoreWhen: ignoreWhen,
      animationController: AnimationController(
        vsync: vsync,
        duration: kSelectionDuration,
      ),
      actionsBuilder: !actionsBar
          ? null
          : (context) {
              return _SelectionActionsBar(
                left: [
                  _ActionsSelectionTitle(
                    selectedTitle: false,
                    counter: counter,
                    closeButton: closeButton,
                  )
                ],
                right: _getActions(contentType, additionalPlayActionsBuilder?.call(context) ?? const [])(),
              );
            },
    );
  }

  /// Creates content [SelectionController.alwaysInSelection], with immutable, always in selection state
  /// for particular `T` [Content] type.
  ///
  /// Call [activate] on then to create the selection bar overlay.
  ///
  /// If there's a need in custom [overlay], usually it's it might be not available
  /// at the time of controller creation. In this case you can delay the activation
  /// until the next frame.
  ///
  /// Will show counter in the actions bar.
  ///
  /// The [actions] can be used to display custom actions at the right side
  /// of the actions bar.
  @factory
  static ContentSelectionController<SelectionEntry<T>> createAlwaysInSelection<T extends Content>({
    required BuildContext context,
    OverlayState? overlay,
    List<Widget> Function(BuildContext)? actionsBuilder,
  }) {
    return ContentSelectionController<SelectionEntry<T>>._alwaysInSelection(
      context: context,
      overlay: overlay,
      actionsBuilder: (context) {
        return _SelectionActionsBar(
          left: const [
            _ActionsSelectionTitle(
              counter: true,
            )
          ],
          right: actionsBuilder?.call(context) ?? const [],
        );
      },
    );
  }

  static ValueGetter<List<Widget>> _getActions(ContentType? contentType, List<Widget> additionalPlayActions) {
    const commonActions = <Widget>[
      _FavoriteSelectionAction(),
      _PlayAsQueueSelectionAction(),
      _ShuffleAsQueueSelectionAction(),
      _AddToPlaylistSelectionAction(),
    ];
    switch (contentType) {
      case ContentType.song:
        return () =>
            commonActions +
            [
              const _GoToArtistSelectionAction(),
              const _GoToAlbumSelectionAction(),
              ...additionalPlayActions,
              const _PlayNextSelectionAction(contentType: ContentType.song),
              const _AddToQueueSelectionAction(contentType: ContentType.song),
            ];
      case ContentType.album:
        return () =>
            commonActions +
            [
              ...additionalPlayActions,
              const _PlayNextSelectionAction(contentType: ContentType.album),
              const _AddToQueueSelectionAction(contentType: ContentType.album),
            ];
      case ContentType.playlist:
        return () =>
            commonActions +
            [
              const _EditPlaylistSelectionAction(),
              ...additionalPlayActions,
              const _PlayNextSelectionAction(contentType: ContentType.playlist),
              const _AddToQueueSelectionAction(contentType: ContentType.playlist),
            ];
      case ContentType.artist:
        return () =>
            commonActions +
            [
              ...additionalPlayActions,
              const _PlayNextSelectionAction(contentType: ContentType.artist),
              const _AddToQueueSelectionAction(contentType: ContentType.artist),
            ];
      case null:
        return () =>
            commonActions +
            [
              const _GoToArtistSelectionAction(),
              const _GoToAlbumSelectionAction(),
              const _EditPlaylistSelectionAction(),
              ...additionalPlayActions,
              const _PlayNextSelectionAction(),
              const _AddToQueueSelectionAction(),
            ];
    }
  }

  static ContentSelectionController<T> _of<T extends SelectionEntry>(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<_ContentSelectionControllerProvider>()!.widget
        as _ContentSelectionControllerProvider;
    return widget.controller as ContentSelectionController<T>;
  }

  /// Returns true when data, or song origins inside it, have at least one song,
  /// in other words, if [ContentUtils.flatten] for this controller would return
  /// non-empty array.
  bool get hasAtLeastOneSong => data.any((el) => el is! SelectionEntry<Playlist> || el.data.songIds.isNotEmpty);

  Color? _lastNavColor;
  OverlayEntry? _overlayEntry;
  SlidableController? _dismissibleRouteController;
  ValueNotifier<ContentSelectionController?> get _notifier => ContentControl.instance.selectionNotifier;

  /// Creates the actions bar overlay.
  void activate() {
    if (ignoreWhen?.call() ?? false) {
      close();
      return;
    }
    if (_notifier.value != null && _notifier.value != this) {
      // Close previous selection.
      _notifier.value!.close();
      assert(false, 'There can only be one active controller');
    }
    for (final observer in NFWidgets.routeObservers!) {
      observer.subscribe(this, ModalRoute.of(context)!);
    }
    _dismissibleRouteController = DismissibleRoute.controllerOf(context);
    _dismissibleRouteController?.addDragEventListener(_handleDismissibleRouteDrag);

    if (actionsBuilder != null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => RepaintBoundary(
          child: _ContentSelectionControllerProvider(
            controller: this,
            child: Builder(
              builder: (context) => Builder(
                builder: (context) => actionsBuilder!(context),
              ),
            ),
          ),
        ),
      );

      final localOverlay = overlay ?? HomeState.overlayKey.currentState!;
      localOverlay.insert(_overlayEntry!);

      // Animate system UI
      final lastUi = SystemUiStyleController.instance.lastUi;
      _lastNavColor = lastUi.systemNavigationBarColor;
      SystemUiStyleController.instance.animateSystemUiOverlay(
        to: lastUi.copyWith(systemNavigationBarColor: constants.UiTheme.grey.auto.systemNavigationBarColor),
        duration: kSelectionDuration,
        curve: _SelectionActionsBar.forwardCurve,
      );
    }

    _notifier.value = this;
  }

  @override
  void notifyStatusListeners(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      activate();
    } else if (status == AnimationStatus.reverse) {
      if (!ContentControl.instance.disposed.value) {
        _notifier.value = null;
      }
      _animateNavBack();
    } else if (status == AnimationStatus.dismissed) {
      _removeOverlay();
    }
    super.notifyStatusListeners(status);
  }

  @override
  void didPop() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // This might be called during the build which will cause a crash
      close();
    });
  }

  void _handleDismissibleRouteDrag(SlidableDragEvent event) {
    if (event is SlidableDragEnd && event.closing) {
      close();
    }
  }

  void _animateNavBack() {
    if (_lastNavColor == null) {
      return;
    }
    SystemUiStyleController.instance.animateSystemUiOverlay(
      to: SystemUiStyleController.instance.lastUi.copyWith(
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
    for (final observer in NFWidgets.routeObservers!) {
      observer.unsubscribe(this);
    }

    if (ContentControl.instance.disposed.value) {
      _removeOverlay();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        _primaryContentTypeNotifier.dispose();
      });
      super.dispose();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        _notifier.value = null;
        _primaryContentTypeNotifier.dispose();
        if (inSelection) {
          await close();
        }
        _removeOverlay();
        super.dispose();
      });
    }
  }
}

class _ContentSelectionControllerProvider extends InheritedWidget {
  const _ContentSelectionControllerProvider({
    required Widget child,
    required this.controller,
  }) : super(child: child);

  final ContentSelectionController controller;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// Creates a selection controller and automatically rebuilds, when it updates.
class ContentSelectionControllerCreator<T extends Content> extends StatefulWidget {
  const ContentSelectionControllerCreator({
    Key? key,
    required this.builder,
    required this.contentType,
    this.child,
  }) : super(key: key);

  final Widget Function(BuildContext context, ContentSelectionController selectionController, Widget? child) builder;
  final ContentType<T> contentType;
  final Widget? child;

  @override
  _SelectionControllerCreatorState<T> createState() => _SelectionControllerCreatorState();
}

class _SelectionControllerCreatorState<T extends Content> extends State<ContentSelectionControllerCreator<T>>
    with SelectionHandlerMixin {
  @override
  void initState() {
    super.initState();
    initSelectionController(() => ContentSelectionController.create(
          vsync: AppRouter.instance.navigatorKey.currentState!,
          context: context,
          contentType: widget.contentType,
          closeButton: true,
          counter: true,
          ignoreWhen: () => playerRouteController.opened,
        ));
  }

  @override
  void dispose() {
    disposeSelectionController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, selectionController, widget.child);
  }
}

class SelectionCheckmark extends StatefulWidget {
  const SelectionCheckmark({
    Key? key,
    required this.animation,
    this.ignorePointer = true,
    this.scaleAnimation = true,
    this.size = 21.0,
  }) : super(key: key);

  final Animation<double> animation;
  final bool ignorePointer;
  final bool scaleAnimation;
  final double size;

  @override
  _SelectionCheckmarkState createState() => _SelectionCheckmarkState();
}

class _SelectionCheckmarkState extends State<SelectionCheckmark> with SingleTickerProviderStateMixin {
  late AnimationController _checkBoxAnimation;

  @override
  void initState() {
    super.initState();
    _checkBoxAnimation = AnimationController(vsync: this);
    widget.animation.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateWidget(covariant SelectionCheckmark oldWidget) {
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_handleStatusChange);
      widget.animation.addStatusListener(_handleStatusChange);
      _update();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatusChange);
    _checkBoxAnimation.dispose();
    super.dispose();
  }

  void _update() {
    if (widget.animation.status == AnimationStatus.forward) {
      _checkBoxAnimation.forward();
    }
  }

  void _handleStatusChange(AnimationStatus status) {
    _update();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignorePointer,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) => !widget.scaleAnimation
            ? child!
            : ScaleTransition(
                scale: widget.animation,
                child: child,
              ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            color: constants.AppColors.androidGreen,
            borderRadius: BorderRadius.all(Radius.circular(200.0)),
          ),
          child: Lottie.asset(
            constants.Assets.assetAnimationCheckmark,
            controller: _checkBoxAnimation,
            onLoaded: (composition) {
              _checkBoxAnimation.duration = composition.duration;
              _checkBoxAnimation.forward();
            },
            delegates: LottieDelegates(
              values: [
                ValueDelegate.strokeColor(
                  const ['Main Layer', 'Color'],
                  value: ThemeControl.instance.theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
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
      animation: controller.animation,
      child: child,
      builder: (context, value, child) => IgnorePointer(ignoring: value, child: child),
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
    final selectionAnimation = ContentSelectionController._of(context).animation;
    final fadeAnimation = CurvedAnimation(
      curve: forwardCurve,
      reverseCurve: reverseCurve,
      parent: selectionAnimation,
    );
    final rightList = right.reversed.toList();
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
            color: ThemeControl.instance.theme.colorScheme.secondary,
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: left),
                    const SizedBox(width: 10.0, height: double.infinity),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: ScrollConfiguration(
                          behavior: const GlowlessScrollBehavior(),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            itemCount: rightList.length,
                            itemBuilder: (context, index) => Center(child: rightList[index]),
                          ),
                        ),
                      ),
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

/// Animation that emerges the item, by default from right to left.
class EmergeAnimation extends AnimatedWidget {
  const EmergeAnimation({
    Key? key,
    required Animation<double> animation,
    required this.child,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  }) : super(key: key, listenable: animation);

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
          child: RepaintBoundary(
            child: child,
          ),
        ),
        builder: (context, value, child) => IgnorePointer(
          ignoring: value,
          child: child,
        ),
      ),
    );
  }
}

/// Checks whether the action is supported and hides it, if it's not.
///
/// Calls the build again, when selection is updated, excluding the
/// selection closing.
class _ActionBuilder extends StatefulWidget {
  const _ActionBuilder({
    Key? key,
    required this.controller,
    required this.builder,
    required this.shown,
    this.child,
  }) : super(key: key);

  final ContentSelectionController controller;

  final TransitionBuilder builder;

  final Widget? child;

  /// Condition to check whether the action should be shown or not.
  final ValueGetter<bool> shown;

  @override
  _ActionBuilderState createState() => _ActionBuilderState();
}

class _ActionBuilderState extends State<_ActionBuilder> with SelectionHandlerMixin {
  UniqueKey key = UniqueKey();
  bool shown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(handleSelection);
  }

  @override
  void didUpdateWidget(covariant _ActionBuilder oldWidget) {
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
    if (widget.controller.closeSelectionWhenEmpty &&
        widget.controller.data.length == 1 &&
        widget.controller.lengthIncreased) {
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
      shown = widget.shown.call();
    }
    return AnimatedSwitcher(
      key: key,
      duration: kSelectionDuration,
      transitionBuilder: (child, animation) => EmergeAnimation(
        animation: animation,
        child: child,
      ),
      child: !shown ? const SizedBox.shrink() : widget.builder(context, widget.child),
    );
  }
}

/// Creates a selection title.
class _ActionsSelectionTitle extends StatelessWidget {
  const _ActionsSelectionTitle({
    Key? key,
    this.counter = false,
    this.selectedTitle = true,
    this.closeButton = false,
  }) : super(key: key);

  /// If true, will show a selection close button.
  final bool closeButton;

  /// If true, before the counter the "Selected" word will be shown.
  final bool selectedTitle;

  /// If true, in place of "Actions" label, [SelectionCounter] will be shown.
  final bool counter;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    final Widget counterWidget = EmergeAnimation(
      animation: controller.animation,
      child: Padding(
        padding: EdgeInsets.only(
            left: selectedTitle
                ? 0.0
                : closeButton
                    ? 5.0
                    : 10.0),
        child: const SelectionCounter(
            textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 19.0,
        )),
      ),
    );
    return Row(
      children: [
        if (closeButton)
          EmergeAnimation(
            animation: controller.animation,
            child: NFIconButton(
              size: NFConstants.iconButtonSize,
              iconSize: NFConstants.iconSize,
              color: ThemeControl.instance.theme.colorScheme.onSurface,
              onPressed: () => controller.close(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        if (selectedTitle && counter)
          Padding(
            padding: EdgeInsets.only(bottom: 4.0, left: closeButton ? 12.0 : 30.0),
            child: EmergeAnimation(
              animation: controller.animation,
              child: StyledText(
                text: l10n.selected('<counter/>'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17.0),
                tags: {
                  'counter': StyledTextWidgetTag(Padding(
                    padding: const EdgeInsets.only(top: 2, left: 7.0, right: 7.0),
                    child: counterWidget,
                  )),
                },
              ),
            ),
          ),
        if (!selectedTitle && counter)
          Padding(
            padding: EdgeInsets.only(left: counter ? 10.0 : 8.0, bottom: 2.0),
            child: counterWidget,
          )
      ],
    );
  }
}

/// Creates a counter that shows how many items are selected.
class SelectionCounter extends StatefulWidget {
  const SelectionCounter({
    Key? key,
    this.textStyle,
    this.controller,
  }) : super(key: key);

  /// Text style of the counter.
  ///
  /// By default [appBarTitleTextStyle] is used.
  final TextStyle? textStyle;

  /// Selection controller, if none specified, will try to fetch it from context.
  final ContentSelectionController? controller;

  @override
  _SelectionCounterState createState() => _SelectionCounterState();
}

class _SelectionCounterState extends State<SelectionCounter> with SelectionHandlerMixin {
  late ContentSelectionController controller;
  late int selectionCount;
  UniqueKey key = UniqueKey();

  int get minCount => controller.closeSelectionWhenEmpty ? 1 : 0;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? ContentSelectionController._of(context);
    controller.addListener(handleSelection);
    selectionCount = math.max(minCount, controller.data.length);
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
    if (controller.closeSelectionWhenEmpty && controller.data.length == 1 && controller.lengthIncreased) {
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
      selectionCount = math.max(minCount, controller.data.length);
    }
    return CountSwitcher(
      key: key,
      childKey: ValueKey(selectionCount),
      valueIncreased: controller.lengthIncreased,
      child: Text(
        selectionCount.toString(),
        style: widget.textStyle ?? appBarTitleTextStyle,
      ),
    );
  }
}

//************** ACTIONS **************

//*********** Queue actions ***********

/// Action that queues a [Song] or a [SongOrigin] to be played next.
class _PlayNextSelectionAction extends StatelessWidget {
  const _PlayNextSelectionAction({this.contentType, Key? key}) : super(key: key);

  /// The type of content to be played next.
  final ContentType? contentType;

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty) {
      return;
    }
    entries.sort((a, b) => a.index.compareTo(b.index));
    QueueControl.instance.playNext(
      entries.map((el) => el.data).toList(),
    );
  }

  void _handleOrigins(List<SelectionEntry<SongOrigin>> entries) {
    if (entries.isEmpty) {
      return;
    }
    // Reverse order is proper here
    entries.sort((a, b) => b.index.compareTo(a.index));
    for (final entry in entries) {
      QueueControl.instance.playOriginNext(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    switch (contentType) {
      case ContentType.song:
        _handleSongs(controller.data.toList() as List<SelectionEntry<Song>>);
        break;
      case ContentType.album:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Album>>);
        break;
      case ContentType.playlist:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Playlist>>);
        break;
      case ContentType.artist:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Artist>>);
        break;
      case null:
        final List<SelectionEntry<Content>> entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        final List<SelectionEntry<Playlist>> playlists = [];
        final List<SelectionEntry<Artist>> artists = [];
        for (final entry in entries) {
          switch (entry.data.type) {
            case ContentType.song:
              songs.add(entry as SelectionEntry<Song>);
              break;
            case ContentType.album:
              albums.add(entry as SelectionEntry<Album>);
              break;
            case ContentType.playlist:
              playlists.add(entry as SelectionEntry<Playlist>);
              break;
            case ContentType.artist:
              artists.add(entry as SelectionEntry<Artist>);
              break;
          }
        }
        _handleSongs(songs);
        _handleOrigins(albums);
        _handleOrigins(playlists);
        _handleOrigins(artists);
        break;
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _ActionBuilder(
      shown: () => true,
      controller: controller,
      builder: (context, child) => EmergeAnimation(
        animation: controller.animation,
        child: AnimatedIconButton(
          tooltip: l10n.playNext,
          duration: const Duration(milliseconds: 240),
          icon: const Icon(SweyerIcons.play_next),
          iconSize: 30.0,
          onPressed: !controller.hasAtLeastOneSong ? null : () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that adds a [Song] or a [SongOrigin] to the end of the queue.
class _AddToQueueSelectionAction extends StatelessWidget {
  const _AddToQueueSelectionAction({this.contentType, Key? key}) : super(key: key);

  /// The type of content to be added to the queue.
  final ContentType? contentType;

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty) {
      return;
    }
    entries.sort((a, b) => a.index.compareTo(b.index));
    QueueControl.instance.addToQueue(
      entries.map((el) => el.data).toList(),
    );
  }

  void _handleOrigins(List<SelectionEntry<SongOrigin>> entries) {
    if (entries.isEmpty) {
      return;
    }
    entries.sort((a, b) => a.index.compareTo(b.index));
    for (final entry in entries) {
      QueueControl.instance.addOriginToQueue(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    switch (contentType) {
      case ContentType.song:
        _handleSongs(controller.data.toList() as List<SelectionEntry<Song>>);
        break;
      case ContentType.album:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Album>>);
        break;
      case ContentType.playlist:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Playlist>>);
        break;
      case ContentType.artist:
        _handleOrigins(controller.data.toList() as List<SelectionEntry<Artist>>);
        break;
      case null:
        final List<SelectionEntry<Content>> entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        final List<SelectionEntry<Playlist>> playlists = [];
        final List<SelectionEntry<Artist>> artists = [];
        for (final entry in entries) {
          switch (entry.data.type) {
            case ContentType.song:
              songs.add(entry as SelectionEntry<Song>);
              break;
            case ContentType.album:
              albums.add(entry as SelectionEntry<Album>);
              break;
            case ContentType.playlist:
              playlists.add(entry as SelectionEntry<Playlist>);
              break;
            case ContentType.artist:
              artists.add(entry as SelectionEntry<Artist>);
              break;
          }
        }
        _handleSongs(songs);
        _handleOrigins(albums);
        _handleOrigins(playlists);
        _handleOrigins(artists);
        break;
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _ActionBuilder(
      shown: () => true,
      controller: controller,
      builder: (context, child) => EmergeAnimation(
        animation: controller.animation,
        child: AnimatedIconButton(
          tooltip: l10n.addToQueue,
          duration: const Duration(milliseconds: 240),
          icon: const Icon(SweyerIcons.add_to_queue),
          iconSize: 30.0,
          onPressed: !controller.hasAtLeastOneSong ? null : () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that plays selected content as queue.
class _PlayAsQueueSelectionAction extends StatelessWidget {
  const _PlayAsQueueSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController controller) {
    final songs = ContentUtils.flatten(ContentUtils.selectionPackAndSort(controller.data).merged);
    QueueControl.instance.setQueue(
      type: QueueType.arbitrary,
      shuffled: false,
      songs: songs,
    );
    MusicPlayer.instance.setSong(songs.first);
    MusicPlayer.instance.play();
    playerRouteController.open();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _ActionBuilder(
      shown: () => true,
      controller: controller,
      builder: (context, child) => EmergeAnimation(
        animation: controller.animation,
        child: AnimatedIconButton(
          tooltip: l10n.playContentList,
          duration: const Duration(milliseconds: 240),
          icon: const Icon(Icons.play_arrow_rounded),
          iconSize: 27.0,
          onPressed: !controller.hasAtLeastOneSong ? null : () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that shuffles and plays selected content as queue.
class _ShuffleAsQueueSelectionAction extends StatelessWidget {
  const _ShuffleAsQueueSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController controller) {
    final songs = ContentUtils.flatten(ContentUtils.selectionPackAndSort(controller.data).merged);
    QueueControl.instance.setQueue(
      type: QueueType.arbitrary,
      shuffled: true,
      shuffleFrom: songs,
    );
    MusicPlayer.instance.setSong(QueueControl.instance.state.current.songs[0]);
    MusicPlayer.instance.play();
    playerRouteController.open();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _ActionBuilder(
      shown: () => true,
      controller: controller,
      builder: (context, child) => EmergeAnimation(
        animation: controller.animation,
        child: AnimatedIconButton(
          tooltip: l10n.shuffleContentList,
          duration: const Duration(milliseconds: 240),
          icon: const Icon(Icons.shuffle_rounded),
          iconSize: 22.0,
          onPressed: !controller.hasAtLeastOneSong ? null : () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that removes a song from the queue.
class RemoveFromQueueSelectionAction extends StatelessWidget {
  const RemoveFromQueueSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController<SelectionEntry<Song>> controller) {
    for (final entry in controller.data) {
      final removed = QueueControl.instance.removeFromQueue(entry.data);
      assert(removed);
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of<SelectionEntry<Song>>(context);
    return _ActionBuilder(
      controller: controller,
      shown: () => true,
      builder: (context, child) => child!,
      child: EmergeAnimation(
        animation: controller.animation,
        child: NFIconButton(
          tooltip: l10n.removeFromQueue,
          icon: const Icon(Icons.remove_rounded),
          onPressed: () => _handleTap(controller),
        ),
      ),
    );
  }
}

//*********** Navigation actions ***********

/// Action that leads to the song album.
class _GoToAlbumSelectionAction extends StatelessWidget {
  const _GoToAlbumSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController controller) {
    final song = controller.data.first.data as Song;
    final album = song.getAlbum();
    if (album != null) {
      HomeRouter.instance.goto(HomeRoutes.factory.content(album));
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    assert(controller.runtimeType == typeOf<ContentSelectionController<SelectionEntry<Content>>>() ||
        controller is ContentSelectionController<SelectionEntry<Song>>);
    final data = controller.data;

    return _ActionBuilder(
      controller: controller,
      shown: () {
        return data.length == 1 &&
            data.first.data is Song &&
            (data.first.data as Song).albumId != null &&
            // disable action in album route
            (HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.album) || playerRouteController.opened);
      },
      builder: (context, child) => child!,
      child: EmergeAnimation(
        animation: controller.animation,
        child: NFIconButton(
          tooltip: l10n.goToAlbum,
          icon: Icon(ContentType.album.icon),
          iconSize: 23.0,
          onPressed: () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that leads to the song or album artist.
class _GoToArtistSelectionAction extends StatelessWidget {
  const _GoToArtistSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController controller) {
    final content = controller.data.first.data;
    if (content is Song) {
      HomeRouter.instance.goto(HomeRoutes.factory.content(content.getArtist()));
    } else if (content is Album) {
      HomeRouter.instance.goto(HomeRoutes.factory.content(content.getArtist()));
    } else {
      throw UnimplementedError();
    }
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    assert(controller.runtimeType == typeOf<ContentSelectionController<SelectionEntry<Content>>>() ||
        controller is ContentSelectionController<SelectionEntry<Song>> ||
        controller is ContentSelectionController<SelectionEntry<Album>>);
    final data = controller.data;

    return _ActionBuilder(
      controller: controller,
      shown: () {
        return data.length == 1 &&
            (data.first.data is Song || data.first.data is Album) &&
            // disable action in artist route
            (HomeRouter.instance.currentRoute.hasDifferentLocation(HomeRoutes.artist) || playerRouteController.opened);
      },
      builder: (context, child) => child!,
      child: EmergeAnimation(
        animation: controller.animation,
        child: NFIconButton(
          tooltip: l10n.goToArtist,
          icon: Icon(ContentType.artist.icon),
          iconSize: 23.0,
          onPressed: () => _handleTap(controller),
        ),
      ),
    );
  }
}

/// Action that opens a playlist edit mode.
class _EditPlaylistSelectionAction extends StatelessWidget {
  const _EditPlaylistSelectionAction({Key? key}) : super(key: key);

  void _handleTap(ContentSelectionController controller) {
    final playlist = controller.data.first.data as Playlist;
    HomeRouter.instance
        .goto(HomeRoutes.playlist.withArguments(PersistentQueueArguments(queue: playlist, editing: true)));
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    assert(controller.runtimeType == typeOf<ContentSelectionController<SelectionEntry<Content>>>() ||
        controller is ContentSelectionController<SelectionEntry<Playlist>>);
    final data = controller.data;

    return _ActionBuilder(
      controller: controller,
      shown: () {
        return data.length == 1 && data.first.data is Playlist;
      },
      builder: (context, child) => child!,
      child: EmergeAnimation(
        animation: controller.animation,
        child: NFIconButton(
          tooltip: l10n.editPlaylist,
          icon: const Icon(Icons.edit_rounded, size: 21.0),
          // iconSize: 23.0,
          onPressed: () => _handleTap(controller),
        ),
      ),
    );
  }
}

//*********** Content related actions ***********

/// Action that adds songs to playlist(s).
/// All types of contents are supported.
class _AddToPlaylistSelectionAction extends StatelessWidget {
  const _AddToPlaylistSelectionAction({Key? key}) : super(key: key);

  void _handleTap(BuildContext context, ContentSelectionController controller) {
    final theme = Theme.of(context);
    ShowFunctions.instance.showDialog(
      context,
      ui: constants.UiTheme.modalOverGrey.auto,
      title: Builder(
        builder: (context) {
          final l10n = getl10n(context);
          return Text(l10n.addToPlaylist);
        },
      ),
      contentPadding: const EdgeInsets.only(top: 14.0, bottom: 0.0),
      content: StreamBuilder(
        stream: ContentControl.instance.onContentChange,
        builder: (context, snapshot) {
          final playlists = ContentControl.instance.state.playlists;
          final screenSize = MediaQuery.of(context).size;
          return SizedBox(
            height: kSongTileHeight + playlists.length * kPersistentQueueTileHeight,
            width: screenSize.width,
            child: ScrollConfiguration(
              behavior: const GlowlessScrollBehavior(),
              child: ContentListView(
                contentType: ContentType.playlist,
                list: playlists,
                leading: const CreatePlaylistInListAction(),
                enableDefaultOnTap: false,
                onItemTap: (index) {
                  final playlist = playlists[index];
                  ContentControl.instance.insertSongsInPlaylist(
                    index: playlist.length + 1,
                    songs: ContentUtils.flatten(ContentUtils.selectionPackAndSort(controller.data).merged),
                    playlist: playlist,
                  );
                  Navigator.pop(context);
                  controller.close();
                },
              ),
            ),
          );
        },
      ),
      buttonSplashColor: theme.appThemeExtension.glowSplashColor,
      acceptButton: const SizedBox(),
      // acceptButton: Builder(
      //   builder: (context) => AppButton.pop(
      //     text: getl10n(context).add,
      //     splashColor: Constants.Theme.glowSplashColor.auto,
      //     onPressed: () {
      //       // onSubmit();
      //       controller.close();
      //     },
      //   ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    return _ActionBuilder(
      controller: controller,
      shown: () => true,
      builder: (context, child) => EmergeAnimation(
        animation: controller.animation,
        child: NFIconButton(
          tooltip: l10n.addToPlaylist,
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: !controller.hasAtLeastOneSong ? null : () => _handleTap(context, controller),
        ),
      ),
    );
  }
}

/// Action that removes a song from playlist.
class _FavoriteSelectionAction extends StatefulWidget {
  const _FavoriteSelectionAction({Key? key}) : super(key: key);

  @override
  State<_FavoriteSelectionAction> createState() => _FavoriteSelectionActionState();
}

class _FavoriteSelectionActionState extends State<_FavoriteSelectionAction> {
  bool active = false;

  void _handleTap(BuildContext context, ContentSelectionController controller) {
    final contentTuple = ContentUtils.selectionPack(controller.data);
    FavoritesControl.instance.setFavorite(
      contentTuple: contentTuple,
      value: contentTuple.any((el) => !el.isFavorite),
    );
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController._of(context);
    final theme = ThemeControl.instance.theme;
    return _ActionBuilder(
      controller: controller,
      shown: () => true,
      builder: (context, child) {
        if (controller.inSelection) {
          active = controller.data.any((el) => !el.data.isFavorite);
        }
        return EmergeAnimation(
          animation: controller.animation,
          child: HeartButton(
            tooltip: l10n.addToFavorites,
            active: active,
            onPressed: () => _handleTap(context, controller),
            color: theme.colorScheme.onSurface,
            inactiveColor: theme.colorScheme.onSurface,
          ),
        );
      },
    );
  }
}

/// Action that removes a song from playlist.
class RemoveFromPlaylistSelectionAction extends StatelessWidget {
  const RemoveFromPlaylistSelectionAction({
    Key? key,
    required this.controller,
    required this.playlist,
  }) : super(key: key);

  final ContentSelectionController controller;
  final Playlist playlist;

  void _handleTap(BuildContext context) {
    final entries = controller.data.cast<SelectionEntry<Song>>().toList()
      ..sort(
        (a, b) => a.index.compareTo(b.index),
      );
    final list = entries.map((el) => el.data).toList();
    _showActionConfirmationDialog<Song>(
      context: context,
      controller: controller,
      list: list,
      localizedAction: (l10n) => l10n.remove,
      localizedTitle: (l10n, count) => l10n.removeTracks(count),
      localizedConfirm: (l10n, count, title) => l10n.removeTracksConfirmation(count, title),
      onSubmit: () {
        ContentControl.instance.removeFromPlaylistAt(
          indexes: controller.data.map((el) => el.index).toList(),
          playlist: playlist,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _ActionBuilder(
      controller: controller,
      shown: () => true,
      builder: (context, child) => child!,
      child: NFIconButton(
        tooltip: l10n.removeFromPlaylist,
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => _handleTap(context),
      ),
    );
  }
}

/// Displays an action to delete songs.
/// Only meant to be displayed in app bar.
///
/// Can receive either [controller] with [Song]s selection, or with generic [Content] type.
/// With the latter, will automatically check if selection contains only songs and hide the button, if not.
class DeleteSongsAppBarAction<T extends Content> extends StatefulWidget {
  const DeleteSongsAppBarAction({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ContentSelectionController<SelectionEntry<T>> controller;

  @override
  _DeleteSongsAppBarActionState<T> createState() => _DeleteSongsAppBarActionState();
}

class _DeleteSongsAppBarActionState<T extends Content> extends State<DeleteSongsAppBarAction<T>>
    with SelectionHandlerMixin {
  late Type type;
  late Type typeToDelete;

  @override
  void initState() {
    super.initState();
    type = typeOf<T>();
    assert(type == Song || type == Playlist || type == Content, 'Only Song, Playlist and Content types are supported');
  }

  Future<void> _handleDelete() async {
    assert(typeToDelete == Song || typeToDelete == Playlist);
    if (typeToDelete == Song) {
      final entries = widget.controller.data.cast<SelectionEntry<Song>>().toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (DeviceInfoControl.instance.useScopedStorageForFileModifications) {
        // On Android R the deletion is performed with OS dialog.
        await ContentControl.instance.deleteSongs(entries.map((e) => e.data).toSet());
        widget.controller.close();
      } else {
        // On all versions below show in app dialog.
        final list = entries.map((el) => el.data).toList();
        _showActionConfirmationDialog<Song>(
          context: context,
          controller: widget.controller,
          list: list,
          localizedAction: (l10n) => l10n.delete,
          localizedTitle: (l10n, count) => l10n.deleteTracks(count),
          localizedConfirm: (l10n, count, title) => l10n.deleteTracksConfirmation(count, title),
          onSubmit: () {
            ContentControl.instance.deleteSongs(entries.map((e) => e.data).toSet());
          },
        );
      }
    } else if (typeToDelete == Playlist) {
      final entries = widget.controller.data.cast<SelectionEntry<Playlist>>().toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      final list = entries.map((el) => el.data).toList();
      _showActionConfirmationDialog<Playlist>(
        context: context,
        controller: widget.controller,
        list: list,
        localizedAction: (l10n) => l10n.delete,
        localizedTitle: (l10n, count) => l10n.deletePlaylists(count),
        localizedConfirm: (l10n, count, title) => l10n.deletePlaylistsConfirmation(count, title),
        onSubmit: () {
          ContentControl.instance.deletePlaylists(list);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionBuilder(
      controller: widget.controller,
      shown: () {
        if (type == Song || type == Playlist) {
          typeToDelete = type;
          return true;
        }
        if (type == Content) {
          SelectionEntry? initEntry;
          for (final entry in widget.controller.data) {
            if (entry is! SelectionEntry<Song> && entry is! SelectionEntry<Playlist>) {
              return false;
            }
            if (initEntry == null) {
              initEntry = entry;
              typeToDelete = entry.data.runtimeType;
            } else {
              // When types are mixed, like selection contains both songs and playlists
              if (typeToDelete != entry.data.runtimeType) {
                return false;
              }
            }
          }
          return true;
        }
        return false;
      },
      builder: (context, child) => child!,
      child: NFIconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: _handleDelete,
      ),
    );
  }
}

void _showActionConfirmationDialog<E extends Content>({
  required BuildContext context,
  required ContentSelectionController controller,
  required List<E> list,
  required VoidCallback onSubmit,
  required String Function(AppLocalizations) localizedAction,
  required String Function(AppLocalizations, int count) localizedTitle,
  required String Function(AppLocalizations, int count, String? element) localizedConfirm,
}) {
  final count = list.length;
  E? entry;
  if (count == 1) {
    entry = list.first;
  }

  final theme = Theme.of(context);

  ShowFunctions.instance.showDialog(
    context,
    ui: constants.UiTheme.modalOverGrey.auto,
    title: Builder(
      builder: (context) {
        final l10n = getl10n(context);
        return Text(localizedTitle(l10n, count));
      },
    ),
    content: SingleChildScrollView(
      child: Builder(
        builder: (context) {
          final l10n = getl10n(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry == null)
                Text(
                  localizedConfirm(l10n, count, null),
                  style: const TextStyle(fontSize: 15.0),
                )
              else
                StyledText(
                  text: localizedConfirm(l10n, count, '<bold>${l10n.escapeStyled(entry.title)}</bold>'),
                  style: const TextStyle(fontSize: 15.0),
                  tags: {
                    'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.w700)),
                  },
                ),
              const SizedBox(height: 8.0),
              _DeletionArtsPreview<E>(
                list: list.toList(),
              ),
            ],
          );
        },
      ),
    ),
    buttonSplashColor: theme.appThemeExtension.glowSplashColor,
    acceptButton: Builder(
      builder: (context) => AppButton.pop(
        text: localizedAction(getl10n(context)),
        popResult: true,
        splashColor: theme.appThemeExtension.glowSplashColor,
        textColor: constants.AppColors.red,
        onPressed: () {
          onSubmit();
          controller.close();
        },
      ),
    ),
  );
}

/// Shows the preview arts from [list] and, if there are more that are not fit,
/// adds a text at the end "and N more".
///
/// Supports only songs and playlists.
class _DeletionArtsPreview<T extends Content> extends StatefulWidget {
  const _DeletionArtsPreview({Key? key, required this.list}) : super(key: key);

  final List<T> list;

  @override
  State<_DeletionArtsPreview<T>> createState() => _DeletionArtsPreviewState<T>();
}

class _DeletionArtsPreviewState<T extends Content> extends State<_DeletionArtsPreview<T>>
    with SingleTickerProviderStateMixin {
  /// Maximum amount of arts per row
  static const maxArts = 5;
  static const itemSize = kPersistentQueueTileArtSize;
  static const moreTextWidth = 110.0;
  static const spacing = 8.0;
  static const animationDuration = Duration(milliseconds: 300);

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    BackButtonInterceptor.add(backButtonInterceptor);
  }

  @override
  void dispose() {
    controller.dispose();
    BackButtonInterceptor.remove(backButtonInterceptor);
    super.dispose();
  }

  /// Using interceptor to gain a priority over the [HomeRouter.handleNecessaryPop].
  bool backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.of(context).maybePop();
    BackButtonInterceptor.remove(backButtonInterceptor);
    return true;
  }

  bool showMore = false;

  void _handleMoreTap() {
    setState(() {
      showMore = !showMore;
      if (showMore) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  Widget _buildArt(T item, double size) {
    assert(item is Song || item is PersistentQueue);

    return ContentArt(
      source: ContentArtSource(item),
      size: size,
      defaultArtIcon: item.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(T == Song || T == Playlist);

    final l10n = getl10n(context);
    final theme = ThemeControl.instance.theme;
    final mediaQuery = MediaQuery.of(context);
    final correctedMoreTextWidth = moreTextWidth * mediaQuery.textScaleFactor;

    return CustomBoxy(
      delegate: _BoxyArtsPreviewDelegate(
        minWidth: itemSize + correctedMoreTextWidth,
        // Width for N arts with spacing between them, excluding
        // the spacing at the end.
        maxWidth: itemSize * maxArts + spacing * (math.max(0, maxArts - 1)),
        minHeight: itemSize,
        maxHeight: double.infinity,
      ),
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) => LayoutBuilder(builder: (context, constraints) {
            final double intermediatePreviewsPerRow =
                math.min(constraints.maxWidth / (itemSize + spacing), maxArts.toDouble());
            final int previewsPerRow = intermediatePreviewsPerRow.toInt();
            // The amount of previews to show in "more" grid, so they fill
            // the entire available space
            final int gridPreviewsPerRow = intermediatePreviewsPerRow.ceil();
            final double gridItemSize =
                (constraints.maxWidth - spacing * (gridPreviewsPerRow - 1)) / gridPreviewsPerRow;
            final exceeded = widget.list.length > previewsPerRow;
            final List<T> previews = exceeded
                ? widget.list.sublist(0, (constraints.maxWidth - correctedMoreTextWidth) ~/ (itemSize + spacing))
                : widget.list;
            final length = previews.length + (exceeded ? 1 : 0);
            final rows = (widget.list.length / gridPreviewsPerRow).ceil();

            final animation = Tween(
              begin: itemSize,
              end: math.min(gridItemSize * rows + (rows - 1) * spacing, mediaQuery.size.height / 2),
            ).animate(CurvedAnimation(
              curve: Curves.easeOut,
              reverseCurve: Curves.easeInCubic,
              parent: controller,
            ));

            return GestureDetector(
              onTap: exceeded ? _handleMoreTap : null,
              child: SizedBox(
                height: animation.value,
                width: constraints.maxWidth,
                child: ScrollConfiguration(
                  behavior: const GlowlessScrollBehavior(),
                  child: AnimatedSwitcher(
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    duration: animationDuration,
                    child: !showMore
                        ? SizedBox(
                            height: itemSize,
                            width: constraints.maxWidth,
                            child: ListView.separated(
                              itemCount: length,
                              itemBuilder: (context, index) {
                                if (!exceeded || index != length - 1) {
                                  return _buildArt(previews[index], itemSize);
                                }
                                return Container(
                                  width: correctedMoreTextWidth,
                                  height: itemSize,
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                      horizontal: 10.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onBackground,
                                      borderRadius: const BorderRadius.all(Radius.circular(100.0)),
                                    ),
                                    child: Text(
                                      l10n.andNMore(widget.list.length - previews.length),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        height: 1,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.background,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) => const SizedBox(width: spacing),
                              scrollDirection: Axis.horizontal,
                            ),
                          )
                        : SizedBox(
                            width: constraints.maxWidth,
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridPreviewsPerRow,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                              ),
                              itemBuilder: (context, index) => _buildArt(widget.list[index], gridItemSize),
                              itemCount: widget.list.length,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BoxyArtsPreviewDelegate extends BoxyDelegate {
  _BoxyArtsPreviewDelegate({
    required this.minWidth,
    required this.maxWidth,
    required this.minHeight,
    required this.maxHeight,
  });

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  @override
  Size layout() {
    return children.first.layout(constraints);
  }

  @override
  double minIntrinsicWidth(double height) {
    return minWidth;
  }

  @override
  double maxIntrinsicWidth(double height) {
    return maxWidth;
  }

  @override
  double minIntrinsicHeight(double width) {
    return minHeight;
  }

  @override
  double maxIntrinsicHeight(double width) {
    return maxHeight;
  }
}

//*********** Selection meta actions ***********

/// Action that selects all content, usually based on the current
/// [ContentSelectionController.primaryContentType].
class SelectAllSelectionAction<T extends Content> extends StatelessWidget {
  const SelectAllSelectionAction({
    Key? key,
    required this.controller,
    required this.entryFactory,
    required this.getAll,
  }) : super(key: key);

  final ContentSelectionController controller;

  final SelectionEntry<T> Function(T, int index) entryFactory;

  /// Should return a list of all content to select, all
  /// values must be of the same type, for example it cannot
  /// contain both [Song]s and [Album]s.
  final ValueGetter<List<T>> getAll;

  void _handleTap(BuildContext context) {
    final all = getAll();
    if (all.isNotEmpty) {
      // TODO: selectAll method for the selection controller maybe? (not this "all", but a list of items)
      final first = all.first;
      assert(all.every((el) => el.runtimeType == first.runtimeType));

      final selectedOfThisType = controller.data.where((el) => el.runtimeType == entryFactory(first, 0).runtimeType);
      bool allSelected = true;
      for (int i = 0; i < all.length; i++) {
        if (!selectedOfThisType.contains(entryFactory(all[i], i))) {
          allSelected = false;
          break;
        }
      }
      if (allSelected) {
        for (int i = 0; i < all.length; i++) {
          controller.data.remove(entryFactory(all[i], i));
        }
        // ignore: invalid_use_of_protected_member
        controller.notifyListeners();
      } else {
        for (int i = 0; i < all.length; i++) {
          controller.data.add(entryFactory(all[i], i));
        }
        // ignore: invalid_use_of_protected_member
        controller.notifyListeners();
      }
      if (controller.data.isEmpty) {
        controller.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _ActionBuilder(
      controller: controller,
      shown: () => true,
      builder: (context, child) => child!,
      child: NFIconButton(
        tooltip: l10n.selectAll,
        icon: const Icon(Icons.select_all_rounded),
        onPressed: () => _handleTap(context),
      ),
    );
  }
}
