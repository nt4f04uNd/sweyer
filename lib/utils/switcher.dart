/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// A switcher interface
abstract class Switcher<T> {
  Switcher(T value) : _value = value;
  T _value;
  T get value => _value;
  void change();
}

// Switches sequentially until 999, then goes back to 0
class IntSwitcher extends Switcher<int> {
  IntSwitcher([int value = 0]) : super(value);

  /// Iteratively changes [value].
  void change() {
    if (_value < 1000)
      _value++;
    else
      _value = 0;
  }
}

