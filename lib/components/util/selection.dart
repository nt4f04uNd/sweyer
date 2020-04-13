/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

typedef StatusListener(SelectionStatus status);
enum SelectionStatus {
  inSelection,
  selecting,
  unselecting,
  notInSelection,
}

/// TODO: rewrite comments for this mixin, as it was coped from flutter and then changed
///
/// A mixin that implements the addStatusListener/removeStatusListener protocol
/// and notifies all the registered listeners when notifyStatusListeners is
/// called.
///
/// This mixin requires that the mixing class provide methods [didRegisterListener]
/// and [didUnregisterListener]. Implementations of these methods can be obtained
/// by mixing in another mixin from this library, such as [AnimationLazyListenerMixin].
mixin SelectionStatusListenersMixin {
  final ObserverList<StatusListener> _statusListeners =
      ObserverList<StatusListener>();

  /// Called immediately before a status listener is added via [addStatusListener].
  ///
  /// At the time this method is called the registered listener is not yet
  /// notified by [notifyStatusListeners].
  void didRegisterListener();

  /// Called immediately after a status listener is removed via [removeStatusListener].
  ///
  /// At the time this method is called the removed listener is no longer
  /// notified by [notifyStatusListeners].
  void didUnregisterListener();

  /// Calls listener every time the status of the animation changes.
  ///
  /// Listeners can be removed with [removeStatusListener].
  void addStatusListener(StatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }

  /// Stops calling the listener every time the status of the animation changes.
  ///
  /// Listeners can be added with [addStatusListener].
  void removeStatusListener(StatusListener listener) {
    final bool removed = _statusListeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  /// Calls all the status listeners.
  ///
  /// If listeners are added or removed during this function, the modifications
  /// will not change which listeners are called during this iteration.
  void notifyStatusListeners(SelectionStatus status) {
    final List<StatusListener> localListeners =
        List<StatusListener>.from(_statusListeners);
    for (final StatusListener listener in localListeners) {
      try {
        if (_statusListeners.contains(listener)) listener(status);
      } catch (exception) {
        rethrow;
      }
    }
  }
}

/// Holds:
///
/// * Selection set of generic type T
/// * Parent general animation controller
/// * Int switcher to add it to value key and have more extended list elements update control
///
/// Status listeners will notify about in selection state change.
///
/// Listeners will notify about add/remove selection events.
class SelectionController<T>
    with
        AnimationLocalListenersMixin,
        AnimationEagerListenerMixin,
        SelectionStatusListenersMixin {
  SelectionController({
    @required this.selectionSet,
    @required this.animationController,
    @required this.switcher,
  }) {
    animationController?.addStatusListener((status) {
      SelectionStatus localStatus;

      switch (status) {
        case AnimationStatus.forward:
          _wasEverSelected = true;
          _isClosing = false;
          localStatus = SelectionStatus.selecting;
          break;
        case AnimationStatus.completed:
          _isClosing = false;
          localStatus = SelectionStatus.inSelection;
          break;
        case AnimationStatus.reverse:
          localStatus = SelectionStatus.unselecting;
          break;
        case AnimationStatus.dismissed:
          _isClosing = false;
          selectionSet.clear();
          localStatus = SelectionStatus.notInSelection;
          break;
      }

      _status = localStatus;
      super.notifyStatusListeners(localStatus);
    });
  }
  final AnimationController animationController;
  final IntSwitcher switcher;
  final Set<T> selectionSet;
  SelectionStatus _status = SelectionStatus.notInSelection;
  bool _wasEverSelected = false;
  bool _isClosing = false;
  int _prevSetLength = 0;

  /// Current selection status
  SelectionStatus get status => _status;

  /// Returns true if controller was never in the [inSelection] state
  bool get wasEverSelected => _wasEverSelected;

  /// An indicator to that controller is unselecting from the call of [close] method
  bool get isClosing => _isClosing;

  /// Whether controller is in [SelectionStatus.inSelection] or [SelectionStatus.selecting]
  bool get inSelection =>
      _status == SelectionStatus.inSelection ||
      _status == SelectionStatus.selecting;

  /// Whether controller is in [SelectionStatus.notInSelection] or [SelectionStatus.unselecting]
  bool get notInSelection =>
      _status == SelectionStatus.notInSelection ||
      _status == SelectionStatus.unselecting;

  /// Returns true when current set length is greater or equal than the previous.
  ///
  /// Convenient for tab bar count animation updates, for example.
  bool get lengthIncreased => selectionSet.length >= _prevSetLength;

  /// Returns true when current set length is less than the previous.
  ///
  /// Convenient for tab bar count animation updates, for example.
  bool get lengthReduced => selectionSet.length < _prevSetLength;

  void _handleSetChange() {
    _prevSetLength = selectionSet.length;
  }

  /// Adds an item to selection set and also notifies click listeners, in case if selection status mustn't change
  void selectItem(T item) {
    if (notInSelection && _isClosing) {
      selectionSet.clear();
    }
    _handleSetChange();
    selectionSet.add(item);
    
    if (notInSelection && selectionSet.length > 0) {
      animationController.forward();
    } else if (selectionSet.length > 1) {
      notifyListeners();
    }
  }

  /// Removes an item to selection set and also notifies click listeners, in case if selection status mustn't change
  void unselectItem(T item) {
    _handleSetChange();
    notifyListeners();
    selectionSet.remove(item);

    if (inSelection && selectionSet.length == 0) {
      animationController.reverse();
    } else {
      notifyListeners();
    }
  }

  /// Clears the set and performs the unselect animation
  void close() {
    _isClosing = true;
    _handleSetChange();
    switcher.change();
    animationController.reverse();
  }

  @override
  void dispose() {
    super.dispose();

    if (animationController != null) {
      animationController.dispose();
    }
  }
}
