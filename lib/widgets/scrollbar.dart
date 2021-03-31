/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sweyer/sweyer.dart';

/// Indicates what scrollbar to use with [ScrollablePositionedList].
enum ScrollbarType {
  /// Don't use any scorllbar.
  none,

  /// Use [NFScrollbar].
  notDraggable,

  /// Use some sort of [NFDraggableScrollbar].
  draggable,
}

/// Default styled draggable scrollbar.
class AppDraggableScrollbar extends StatelessWidget {
  AppDraggableScrollbar({
    Key key,
    this.barKey,
    @required this.child,
    this.barPad,
    this.barHeight = 48.0,
    this.barWidth = 10.0,
    this.barTopMargin = 1.0,
    this.barBottomMargin = 1.0,
    this.barColor,
    this.barPadding,
    this.barAnimationDuration = kScrollbarFadeDuration,
    this.barDuration = kScrollbarTimeToFade,
    this.labelBuilder,
    this.labelTransitionBuilder = NFDraggableScrollbar.defaultLabelTransitionBuilder,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onScrollNotification,
    this.appearOnlyOnScroll = false,
    this.shouldAppear = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
  })  : assert(child != null),
        super(key: key);

  final Key barKey;
  final Widget child;
  final Widget barPad;
  final double barHeight;
  final double barWidth;
  final double barTopMargin;
  final double barBottomMargin;
  final Color barColor;
  final EdgeInsetsGeometry barPadding;
  final Duration barAnimationDuration;
  final Duration barDuration;
  final LabelBuilder labelBuilder;
  final LabelTransitionBuilder labelTransitionBuilder;
  final DraggableScrollBarCallback onDragStart;
  final DraggableScrollBarCallback onDragUpdate;
  final DraggableScrollBarCallback onDragEnd;
  final DraggableScrollBarCallback onScrollNotification;
  final bool appearOnlyOnScroll;
  final bool shouldAppear;
  final BorderRadius borderRadius;

  Widget build(BuildContext context) {
    return NFDraggableScrollbar.rrect(
      barKey: barKey,
      child: child,
      barPad: barPad,
      barHeight: barHeight,
      barWidth: barWidth,
      barTopMargin: barTopMargin,
      barBottomMargin: barBottomMargin,
      barColor: barColor ?? ThemeControl.theme.colorScheme.onBackground,
      barPadding: barPadding,
      barAnimationDuration: barAnimationDuration,
      barDuration: barDuration,
      labelBuilder: labelBuilder,
      labelTransitionBuilder: labelTransitionBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onScrollNotification: onScrollNotification,
      appearOnlyOnScroll: appearOnlyOnScroll,
      shouldAppear: shouldAppear,
      borderRadius: borderRadius,
    );
  }
}

typedef Widget _JumpingLabelBuilder(
    BuildContext context, double progress, double barPadHeight, int jumpIndex);

/// Implements the jump logic for [Song], [Album], etc. lists.
///
/// If current sort feature is `title`, will have a scroll label.
class JumpingDraggableScrollbar extends StatefulWidget {
  JumpingDraggableScrollbar.songs({
    Key key,
    this.barKey,
    @required this.child,
    @required this.itemCount,
    @required this.itemScrollController,
    this.barPad,
    this.barHeight = 48.0,
    this.barWidth = 10.0,
    this.barTopMargin = 1.0,
    this.barBottomMargin = 1.0,
    this.barColor,
    this.barPadding,
    this.barAnimationDuration = kScrollbarFadeDuration,
    this.barDuration = kScrollbarTimeToFade,
    this.labelBuilder,
    this.labelTransitionBuilder = NFDraggableScrollbar.defaultLabelTransitionBuilder,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onScrollNotification,
    this.appearOnlyOnScroll = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
  })  : assert(child != null),
        assert(itemCount != null),
        assert(itemScrollController != null),
        itemHeight = kSongTileArtSize,
        alignment = 0.0,
        endAlignment = 0.885,
        contentType = Song,
        super(key: key);

  JumpingDraggableScrollbar.albums({
    Key key,
    this.barKey,
    @required this.child,
    @required this.itemCount,
    @required this.itemScrollController,
    this.barPad,
    this.barHeight = 48.0,
    this.barWidth = 10.0,
    this.barTopMargin = 1.0,
    this.barBottomMargin = 1.0,
    this.barColor,
    this.barPadding,
    this.barAnimationDuration = kScrollbarFadeDuration,
    this.barDuration = kScrollbarTimeToFade,
    this.labelBuilder,
    this.labelTransitionBuilder = NFDraggableScrollbar.defaultLabelTransitionBuilder,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onScrollNotification,
    this.appearOnlyOnScroll = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
  })  : assert(child != null),
        assert(itemCount != null),
        assert(itemScrollController != null),
        itemHeight = kAlbumTileArtSize,
        alignment = 0.0,
        endAlignment = 0.845,
        contentType = Album,
        super(key: key);

  final Key barKey;
  final Widget child;
  final Widget barPad;
  final double barHeight;
  final double barWidth;
  final double barTopMargin;
  final double barBottomMargin;
  final Color barColor;
  final EdgeInsetsGeometry barPadding;
  final Duration barAnimationDuration;
  final Duration barDuration;
  final _JumpingLabelBuilder labelBuilder;
  final LabelTransitionBuilder labelTransitionBuilder;
  final DraggableScrollBarCallback onDragStart;
  final DraggableScrollBarCallback onDragUpdate;
  final DraggableScrollBarCallback onDragEnd;
  final DraggableScrollBarCallback onScrollNotification;
  final bool appearOnlyOnScroll;
  final BorderRadius borderRadius;

  final int itemCount;
  final double itemHeight;
  final double alignment;
  final double endAlignment;
  final ItemScrollController itemScrollController;
  final Type contentType;

  @override
  _JumpingDraggableScrollbarState createState() => _JumpingDraggableScrollbarState();
}

class _JumpingDraggableScrollbarState extends State<JumpingDraggableScrollbar> {
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  int _index = -1;
  DateTime _lastJumpTime;
  Timer _timer;

  bool get shouldAppear {
    return widget.itemCount * widget.itemHeight > screenHeight * 1.5;
  }

  LabelBuilder get labelBuilder {
    if (widget.labelBuilder == null)
      return null;
    final SortFeature feature = ContentControl.state.sorts.getValue(widget.contentType).feature;
    final bool showLabel = contentPick<Content, bool>(
      contentType: widget.contentType,
      song: feature == SongSortFeature.title,
      album: feature == AlbumSortFeature.title,
    );
    if (!showLabel)
      return null;
    return (context, progress, barPadHeight) {
      return widget.labelBuilder(
        context,
        progress,
        barPadHeight,
        _index,
      );
    };
  }

  void _handleScrollbarDrag(double progress, double barPadHeight) {
    final now = DateTime.now();
    if (_timer == null ||
        _lastJumpTime == null ||
        now.difference(_lastJumpTime) > _debounceDuration) {
      _jump(progress, barPadHeight);
    } else {
      _timer.cancel();
      _timer = Timer(_debounceDuration, () {
        _jump(progress, barPadHeight);
        _timer = null;
      });
    }
  }

  void _handleDragStart(double progress, double barPadHeight) {
    if (widget.onDragStart != null) {
      widget.onDragStart(progress, barPadHeight);
    }
    _handleScrollbarDrag(progress, barPadHeight);
  }

  void _handleDragUpdate(double progress, double barPadHeight) {
    if (widget.onDragUpdate != null) {
      widget.onDragUpdate(progress, barPadHeight);
    }
    _handleScrollbarDrag(progress, barPadHeight);
  }

  void _jump(double progress, double barPadHeight) {
    final index = (progress * (widget.itemCount - 1)).round();
    if (index != _index) {
      _index = index;
      // Basically `barPadHeight` is equal to viewport height (because I don't add any paddings, margins, etc).
      final edgeOffset = (barPadHeight / widget.itemHeight).ceil();
      widget.itemScrollController.jumpTo(
        index: _index,
        // If jump to the end of the list, prevent bouncing.
        alignment: _index >= widget.itemCount - edgeOffset
            ? widget.endAlignment
            : widget.alignment,
      );
    }
  }

  Widget build(BuildContext context) {
    return AppDraggableScrollbar(
      barKey: widget.barKey,
      child: widget.child,
      barPad: widget.barPad,
      barHeight: widget.barHeight,
      barWidth: widget.barWidth,
      barTopMargin: widget.barTopMargin,
      barBottomMargin: widget.barBottomMargin,
      barColor: widget.barColor,
      barPadding: widget.barPadding,
      barAnimationDuration: widget.barAnimationDuration,
      barDuration: widget.barDuration,
      labelBuilder: labelBuilder,
      labelTransitionBuilder: widget.labelTransitionBuilder,
      onDragStart: _handleDragStart,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: widget.onDragEnd,
      onScrollNotification: widget.onScrollNotification,
      appearOnlyOnScroll: widget.appearOnlyOnScroll,
      shouldAppear: shouldAppear,
      borderRadius: widget.borderRadius,
    );
  }
}
