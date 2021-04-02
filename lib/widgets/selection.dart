/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;


/// Selection animation duration.
const Duration kSelectionDuration = Duration(milliseconds: 350);

/// Mixin this to a widget state to make it support selection.
abstract class SelectableWidget<T> extends StatefulWidget {
  /// Creates a widget, not selectable.
  const SelectableWidget({
    Key key,
  }) : selected = null,
       selectionController = null,
       super(key: key);

  /// Creates a selectable widget.
  const SelectableWidget.selectable({
    Key key,
    @required this.selectionController,
    this.selected = false,
  }) : super(key: key);

  /// Makes tiles aware whether they are selected in some global set.
  /// This will be used on first build, after this tile will have internal selection state.
  final bool selected;

  /// A controller that drive the selection.
  /// 
  /// If `null`, widget will be considered as not selectable
  final SelectionController<T> selectionController;

  /// Converts this widget to the entry [selectionController] is holding.
  T toSelectionEntry();

  @override
  State<SelectableWidget<T>> createState();
}

/// A state to be used with [SelectableWidget].
abstract class SelectableState<T extends SelectableWidget> extends State<T> with SingleTickerProviderStateMixin {
  AnimationController _controller;

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
  Animation<double> _animation;

  /// Whether the widget is currently being selected.
  bool get selected => _selected;
  bool _selected;

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
      if (widget.selectionController.notInSelection && _selected) {
        /// We have to check if controller is closing, i.e. user pressed global close button to quit the selection.
        ///
        /// We are assuming that parent updates us, as we can't add owr own status listener to the selection controller,
        /// because it is quite expensive for the list.
        _selected = false;
        _controller.value = widget.selectionController.animationController.value;
        _controller.reverse();
      } else if (oldWidget.selected != widget.selected) {
        _selected = widget.selected;
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
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Builds an [animation].
  /// 
  /// The `animation` is the bare, without any applied curves.
  /// 
  /// Override this method to build your own custom animation.
  Animation buildAnimation(Animation animation) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    ));
  }

  /// Returns a aethod that either joins the selection, or closes it, dependent
  /// on current state of [selected].
  /// 
  /// Will return null if not [selectable], because it is common to pass it to [ListTile.onLongPress],
  /// and passing null will disable the long press gesture.
  VoidCallback get toggleSelection => !selectable ? null : () {
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
    if (selectable && widget.selectionController.inSelection) {
      toggleSelection();
    } else {
      onTap();
    }
  }

  void _select() {
    widget.selectionController.selectItem(widget.toSelectionEntry());
    _controller.forward();
  }

  void _unselect() {
    widget.selectionController.unselectItem(widget.toSelectionEntry());
    _controller.reverse();
  }
}

/// Signature, used for [ContentSelectionController.actionsBuilder].
typedef _ActionsBuilder = SelectionActionsBar Function(BuildContext);

class ContentSelectionController<T extends SelectionEntry> extends SelectionController<T> {
  ContentSelectionController({
    @required AnimationController animationController,
    @required this.actionsBuilder,
    Set<T> data,
  }) : super(
        animationController: animationController,
        data: data,
      );

  /// Will build selection controls overlay widget.
  final _ActionsBuilder actionsBuilder;

  /// Constucts a controller for particular `T` [Content] type.
  @factory
  static ContentSelectionController forContent<T extends Content>(TickerProvider vsync) {
    final actionsBuilder = contentPick<T, _ActionsBuilder>(
      song: (context) {
        final controller = ContentSelectionController.of(context);
        return SelectionActionsBar(
          controller: controller,
          left: const [ActionsSelectionTitle()],
          right: const [
            GoToAlbumSelectionAction(),
            PlayNextSelectionAction<Song>(),
            AddToQueueSelectionAction<Song>(),
          ],
        );
      },
      album: (context) {
        final controller = ContentSelectionController.of(context);
        return SelectionActionsBar(
          controller: controller,
          left: const [ActionsSelectionTitle()],
          right: const [
            PlayNextSelectionAction<Album>(),
            AddToQueueSelectionAction<Album>(),
          ],
        );
      }
    );
    return ContentSelectionController<SelectionEntry<T>>(
      actionsBuilder: actionsBuilder,
      animationController: AnimationController(
        vsync: vsync,
        duration: kSelectionDuration,
      ),
    );
  }

  static ContentSelectionController of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<_ContentSelectionControllerProvider>()
      .widget as _ContentSelectionControllerProvider;
    return widget.controller;
  }

  /// Notifies when active controller changes.
  static ValueNotifier<ContentSelectionController> get activeControllerNotifier => _notifier;
  static ValueNotifier<ContentSelectionController> _notifier = ValueNotifier(null);

  OverlayEntry _overlayEntry;

  @override
  void notifyStatusListeners(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      assert(
        _notifier.value == null || _notifier.value == this,
        'There can only be one active controller'
      );
      _overlayEntry = OverlayEntry(
        builder: (context) => _ContentSelectionControllerProvider(
          controller: this,
          child: Builder(
            builder: (_context) =>  Builder(
            builder: (_contextt) =>actionsBuilder(_contextt),
          ),
          ),
        ),
      );
      AppRouter.instance.navigatorKey.currentState.overlay.insert(_overlayEntry);
      _notifier.value = this;
    } else if (status == AnimationStatus.dismissed) {
      _removeOverlay();
    }
    super.notifyStatusListeners(status);
  }

  void _removeOverlay() {
    if (_notifier.value != null) {
      _overlayEntry.remove();
      _notifier.value = null;
    }
  }

  @override
  void dispose() { 
    _removeOverlay();
    super.dispose();
  }
} 

class _ContentSelectionControllerProvider extends InheritedWidget {
  _ContentSelectionControllerProvider({
    @required this.child,
    @required this.controller,
    }) : super(child: child);

  final Widget child;
  final ContentSelectionController controller;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}


/// Provides access to a [map] of [ContentSelectionController]s.
class ContentSelectionControllersProvider extends InheritedWidget {
  const ContentSelectionControllersProvider({
    Key key,
    @required this.child,
    @required this.map,
  }) : super(key: key, child: child);

  final Widget child;
  final Map<Type, ContentSelectionController<SelectionEntry>> map;

  ContentSelectionController<SelectionEntry<Song>> get song => map[Song];
  ContentSelectionController<SelectionEntry<Album>> get album => map[Album];

  static ContentSelectionControllersProvider of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<ContentSelectionControllersProvider>().widget;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}


class SelectionCheckmark extends StatefulWidget {
  const SelectionCheckmark({
    @required this.animation,
    this.size = 21.0,
  });

  final Animation animation;
  final double size;

  @override
  _SelectionCheckmarkState createState() => _SelectionCheckmarkState();
}

class _SelectionCheckmarkState extends State<SelectionCheckmark> {
  String _flareAnimation = 'stop';

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleStatusChange);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatusChange);
    super.dispose();
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _flareAnimation = 'play';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) => IgnorePointer(
        child: ScaleTransition(
          scale: widget.animation,
          child: child,
        ),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Constants.AppColors.androidGreen,
          borderRadius: const BorderRadius.all(Radius.circular(200.0)),
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
    );
  }
}

class SelectionActionsBar<T extends SelectionEntry> extends StatelessWidget {
  const SelectionActionsBar({
    Key key,
    @required this.controller,
    this.left = const [],
    this.right = const [],
  }) : super(key: key);

  final SelectionController<T> controller;
  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    final selectionAnimation = controller.animationController;
    final fadeAnimation = CurvedAnimation(
      curve: Interval(
        0.0,
        0.7,
        curve: Curves.easeOutCubic,
      ),
      reverseCurve: Interval(
        0.0,
        0.5,
        curve: Curves.easeIn,
      ),
      parent: selectionAnimation,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: selectionAnimation,
        builder: (context, child) => FadeTransition(
          opacity: fadeAnimation,
          child: IgnorePointer(
            ignoring: const IgnoringStrategy(
              reverse: true,
              dismissed: true,
            ).evaluate(selectionAnimation),
            child: child,
          ),
        ),
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
    );
  }
}

class _SelectionAnimation extends AnimatedWidget {
  _SelectionAnimation({
    @required Animation animation,
    @required this.child,
    this.begin = const Offset(-1.0, 0.0),
    this.end = Offset.zero,
  }) : super(listenable: animation);
  final Widget child;
  final Offset begin;
  final Offset end;
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
      child: AnimatedBuilder(
        animation: listenable,
        child: child,
        builder: (context, child) => IgnorePointer(
          ignoring: const IgnoringStrategy(
            dismissed: true,
            reverse: true,
          ).evaluate(listenable),
          child: SlideTransition(
            position: animation,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Creates a selection title.
class ActionsSelectionTitle extends StatelessWidget {
  const ActionsSelectionTitle({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
      child: _SelectionAnimation(
        animation: ContentSelectionController.of(context).animationController,
        child: Text(l10n.actions),
      ),
    );
  }
}

/// Action that leads to the song album.
/// 
/// Can only be used with [Song]s.
class GoToAlbumSelectionAction<T extends Content> extends StatefulWidget {
  const GoToAlbumSelectionAction({ Key key }) : super(key: key);

  @override
  _GoToAlbumSelectionActionState createState() => _GoToAlbumSelectionActionState();
}

class _GoToAlbumSelectionActionState<T extends Content> extends State<GoToAlbumSelectionAction<T>> {
  ContentSelectionController<SelectionEntry<T>> controller;

  @override
  void initState() {
    super.initState();
    controller = ContentSelectionController.of(context);
    controller.addListener(_handleControllerChange);
    controller.addStatusListener(_handleStatusControllerChange);
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChange);
    controller.removeStatusListener(_handleStatusControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    setState(() {
      /* update ui to hide when data lenght is greater than 1 */
    });
  }

  void _handleStatusControllerChange(AnimationStatus status) {
    setState(() {
      /* update ui to hide when data lenght is greater than 1 */
    });
  }

  void _handleTap() {
    final song = controller.data.first.data as Song;
    final album = song.getAlbum();
    HomeRouter.instance.goto(HomeRoutes.factory.album(album));
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final data = controller.data;

    return AnimatedSwitcher(
      duration: kSelectionDuration,
      transitionBuilder: (child, animation) => _SelectionAnimation(
        animation: animation,
        child: child,
      ),
      child:
          data.length > 1 ||
          data.length == 1 && (data.first.data is! Song || (data.first.data as Song).albumId == null)
              ? const SizedBox.shrink()
              : _SelectionAnimation(
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

/// Action that queues a [Song] or [Album] to be played next.
class PlayNextSelectionAction<T extends Content> extends StatelessWidget {
  const PlayNextSelectionAction({ Key key }) : super(key: key);

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty)
      return;
    entries.sort((a, b) => a.index.compareTo(b.index));
    ContentControl.playNext(
      entries
        .map((el) => el.data)
        .toList(),
    );
  }

  void _handleAlbums(List<SelectionEntry<Album>> entries) {
    if (entries.isEmpty)
      return;
    // Reverse order is proper here
    entries.sort((a, b) => b.index.compareTo(a.index));
    for (final entry in entries) {
      ContentControl.playQueueNext(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    contentPick<T, VoidCallback>(
      song: () => _handleSongs(controller.data.toList()),
      album: () => _handleAlbums(controller.data.toList()),
      fallback: () {
        final entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        for (final entry in entries) {
          if (entry is SelectionEntry<Song>) {
            songs.add(entry);
          } else if (entry is SelectionEntry<Album>) {
            albums.add(entry);
          } else {
            throw ArgumentError('This action only supports Song and Album selection simultaniously');
          }
        }
        _handleSongs(songs);
        _handleAlbums(albums);
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController.of(context);
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
class AddToQueueSelectionAction<T extends Content>  extends StatelessWidget {
  const AddToQueueSelectionAction({ Key key })
      : super(key: key);

  void _handleSongs(List<SelectionEntry<Song>> entries) {
    if (entries.isEmpty)
      return;
    entries.sort((a, b) => a.index.compareTo(b.index));
    ContentControl.addToQueue(
      entries
        .map((el) => el.data)
        .toList(),
    );
  }

  void _handleAlbums(List<SelectionEntry<Album>> entries) {
    if (entries.isEmpty)
      return;
    entries.sort((a, b) => a.index.compareTo(b.index));
    for (final entry in entries) {
      ContentControl.addQueueToQueue(entry.data);
    }
  }

  void _handleTap(ContentSelectionController controller) {
    contentPick<T, VoidCallback>(
      song: () => _handleSongs(controller.data.toList()),
      album: () => _handleAlbums(controller.data.toList()),
      fallback: () {
        final entries = controller.data.toList();
        final List<SelectionEntry<Song>> songs = [];
        final List<SelectionEntry<Album>> albums = [];
        for (final entry in entries) {
          if (entry is SelectionEntry<Song>) {
            songs.add(entry);
          } else if (entry is SelectionEntry<Album>) {
            albums.add(entry);
          } else {
            throw ArgumentError('This action only supports Song and Album selection simultaniously');
          }
        }
        _handleSongs(songs);
        _handleAlbums(albums);
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final controller = ContentSelectionController.of(context);
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
