/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// Wrapper for exception and stacktrace from catch clause
class CaughtError {
  final dynamic exception;
  final StackTrace stackTrace;
  CaughtError(this.exception, this.stackTrace);
}

typedef  void ReportCallback(CaughtError);

/// Abstract class used to create error bridge between app initialization processes
/// to bring error messages to UI to display them in dialog message
abstract class CatcherErrorBridge {
  static List<CaughtError> _queue = [];

  static add(CaughtError e) {
    assert(_queue != null, "`report` has already been called!");
    _queue.add(e);
  }

  /// Applies a callback for each element in queue and clears it
  static report(ReportCallback callback) {
    _queue.forEach(callback);
    _queue = null;
  }
}
