/// Dumb switcher, that changes its value from true to false
abstract class Switcher<T> {
  Switcher(T value) : _value = value;
  T _value;
  T get value => _value;
  void change();
}

// Switches between `false` and `true`
class BoolSwitcher extends Switcher<bool> {
  BoolSwitcher([bool value = false]) : super(value);

  /// Changes `value` to opposite
  void change() {
    _value = !_value;
  }
}

// Switches between `0` and `1`
class IntSwitcher extends Switcher<int> {
  IntSwitcher([int value = 0]) : super(value);

  /// Changes `value` to opposite
  void change() {
    if (_value == 0) {
      _value = 1;
    } else {
      _value = 0;
    }
  }
}
