import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';

/// A basic unit of state management pattern used in this app.
///
/// This pattern enables a high flexibility in what form the state can be represented.
/// It also allows easy mocking and unit-testing.
///
/// `Control` is a singleton service that has:
///
///  * instance field
///  * state
///  * serializer
///  * streams
///  * methods that modify state and call serializer methods
///
/// ## State
///
/// The `state` should be a pure data and optionally some helping getter methods.
/// If the `state` is large, a separate class should be created for it and marked
/// as [visibleForTesting], otherwise the control can declare it directly.
///
/// The `serializer` should marked as [visibleForTesting] and contain methods that
/// save entries from the `state`.
///
/// Controls typically contain some `streams` that notify of the changes on the `state`.
///
/// ## Unit-testing
///
/// To unit-test a `Control`, one would simply need to create `TestControl`, which
/// mocks the `state` and `serializer`, and then set the `Control.instance`
/// to the `TestControl`.
///
/// Known controls:
///
///   * [ContentControl] 
///   * [PlaybackControl] 
///   * [QueueControl] 
abstract class Control {
  /// Initializes the control.
  ///
  /// Must be called when the control needs to be initialized.
  @mustCallSuper
  void init() {
    assert(_disposed.value);
    _disposed.value = false;
  }

  ValueListenable<bool> get disposed => _disposed;
  final _disposed = ValueNotifier<bool>(true);

  /// Invalidates the control.
  ///
  /// Must be called when the control is no longer needed.
  @mustCallSuper
  void dispose() {
    assert(!disposed.value);
    _disposed.value = true;
  }
}
