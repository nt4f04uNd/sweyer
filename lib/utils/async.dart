/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/foundation.dart';

/// A class that represents some async operation
///
/// Can add to queue calls if it is still in work
class AsyncOperation<T> {
  final Completer<T> _completer = Completer();

  /// Async callback, represents some action, e.g. start of data feting
  final AsyncValueGetter<T> _callback;
  AsyncOperation([AsyncValueGetter<T> callback]) : this._callback = callback;

  /// Returns status of the operation
  ///
  /// Returns true if operation is in work
  bool get isWorking => !_completer.isCompleted;

  // Returns future to wait before operation completion
  Future<T> wait() {
    return _completer.future;
  }

  /// Calls [_callback]
  void start() {
    if (_callback != null) _callback();
  }

  /// End operation
  void finish([FutureOr<T> value]) {
    _completer.complete(value);
  }

  /// Fill completer future that is returned from [wait] method with error
  void errorFinish(Object error, [StackTrace stackTrace]) {
    _completer.completeError(error, stackTrace);
  }
}

/// A queue of [AsyncOperation]s
///
/// Adds new [AsyncOperation] to the end
///
/// Completes from start of list to end
class AsyncOperationsQueue {
  List<AsyncOperation> _queue = [];

  /// first element of [_queue] is considered to be current
  AsyncOperation get _currentOperation => _queue.first;

  /// Adds a function to queue
  ///
  /// If [_queue] length equals 1 calls [_completeQueue] to start queue completion
  ///
  /// @return [AsyncOperation.wait] future
  Future<T> add<T>(AsyncValueGetter<T> callback) {
    _queue.add(AsyncOperation(callback));
    if (_queue.length == 1) _completeQueue();
    return _queue[_queue.length - 1]
        .wait(); // Return future to wait before operation completion
  }

  /// Finishes _currentOperation
  void finishCurrent() {
    _currentOperation.finish();
  }

  /// Completes all operations in [_queue] from start to end
  Future<void> _completeQueue() async {
    while (_queue.isNotEmpty) {
      _currentOperation.start();
      await _currentOperation.wait();

      /// Wait before [finishCurrent] calls
      _queue.removeAt(0); // Remove completed operation
    }
  }
}
