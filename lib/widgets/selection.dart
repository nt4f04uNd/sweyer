/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

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

class SelectionBottomBar extends StatelessWidget {
  const SelectionBottomBar({
    Key key,
    @required this.controller,
    this.left = const [],
    this.right = const [],
  }) : super(key: key);

  final SelectionController<SelectionEntry> controller;
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
          height: 62.0,
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

class ActionsSelectionTitle extends StatelessWidget {
  const ActionsSelectionTitle({Key key, @required this.controller})
      : assert(controller != null),
        super(key: key);
  final SelectionController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
      child: _SelectionAnimation(
        animation: controller.animationController,
        child: Text(l10n.actions),
      ),
    );
  }
}

class GoToAlbumSelectionAction extends StatefulWidget {
  const GoToAlbumSelectionAction({Key key, @required this.controller})
      : assert(controller != null),
        super(key: key);
  final SelectionController<SongSelectionEntry> controller;

  @override
  _GoToAlbumSelectionActionState createState() => _GoToAlbumSelectionActionState();
}

class _GoToAlbumSelectionActionState extends State<GoToAlbumSelectionAction> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
    widget.controller.addStatusListener(_handleStatusControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    widget.controller.removeStatusListener(_handleStatusControllerChange);
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
    final album = widget.controller.data.first.song.getAlbum();
    HomeRouter.instance.goto(HomeRoutes.factory.album(album));
    widget.controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final data = widget.controller.data;
    return AnimatedSwitcher(
      duration: kSelectionDuration,
      transitionBuilder: (child, animation) => _SelectionAnimation(
        animation: animation,
        child: child,
      ),
      child:
          data.length > 1 || data.length == 1 && data.first.song.albumId == null
              ? const SizedBox.shrink()
              : _SelectionAnimation(
                  animation: widget.controller.animationController,
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

class PlayNextSelectionAction<T extends Content> extends StatelessWidget {
  const PlayNextSelectionAction({Key key, @required this.controller})
      : assert(controller != null),
        super(key: key);
  final SelectionController<SelectionEntry<T>> controller;

  void _handleTap() {
    contentPick<T, VoidCallback>(
      song: () {
        final entries = controller.data.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        ContentControl.playNext(
          entries.map((el) => ((el as SongSelectionEntry).song)).toList(),
        );
      },
      album: () {
        final entries = controller.data.toList()
          // reverse order is proper here
          ..sort((a, b) => b.index.compareTo(a.index));
        for (final entry in entries) {
          ContentControl.playQueueNext((entry as AlbumSelectionEntry).album);
        }
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _SelectionAnimation(
      animation: controller.animationController,
      child: NFIconButton(
        tooltip: l10n.playNext,
        icon: const Icon(Icons.playlist_play_rounded),
        iconSize: 30.0,
        onPressed: _handleTap,
      ),
    );
  }
}

class AddToQueueSelectionAction<T extends Content> extends StatelessWidget {
  const AddToQueueSelectionAction({Key key, @required this.controller})
      : assert(controller != null),
        super(key: key);
  final SelectionController<SelectionEntry<T>> controller;

  void _handleTap() {
    contentPick<T, VoidCallback>(
      song: () {
        final entries = controller.data.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        ContentControl.addToQueue(
          entries.map((el) => ((el as SongSelectionEntry).song)).toList(),
        );
      },
      album: () {
        final entries = controller.data.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        for (final entry in entries) {
          ContentControl.addQueueToQueue((entry as AlbumSelectionEntry).album);
        }
      },
    )();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _SelectionAnimation(
      animation: controller.animationController,
      child: NFIconButton(
        tooltip: l10n.addToQueue,
        icon: const Icon(Icons.queue_music_rounded),
        iconSize: 30.0,
        onPressed: _handleTap,
      ),
    );
  }
}
