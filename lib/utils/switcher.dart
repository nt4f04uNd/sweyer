/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// Dumb switcher, that changes its value from true to false
abstract class Switcher<T> {
  Switcher(T value) : _value = value;
  T _value;
  T get value => _value;
  void change();
}

/// Switches between [false] and [true]
class BoolSwitcher extends Switcher<bool> {
  BoolSwitcher([bool value = false]) : super(value);

  /// Changes [value] to opposite
  void change() {
    _value = !_value;
  }
}

// Switches sequentially until 999, then goes back to 0
class IntSwitcher extends Switcher<int> {
  IntSwitcher([int value = 0]) : super(value);

  /// Changes [value] to opposite
  void change() {
    if (_value < 1000)
      _value++;
    else
      _value = 0;
  }
}
