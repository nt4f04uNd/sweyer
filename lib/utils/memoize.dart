import 'package:memoize/function_defs.dart';

/// Checks 3 arguments for equality with [identical] call and returns the cached
/// result if they were not changed.
///
/// Allows to pass additional payload, that is not accounted in memoization.
Func4<A1, A2, A3, A4, R> imemo3plus1<A1, A2, A3, A4, R>(Func4<A1, A2, A3, A4, R> func) {
  late A1 prevA1;
  late A2 prevA2;
  late A3 prevA3;
  late R prevResult;
  bool isInitial = true;

  return ((A1 a1, A2 a2, A3 a3, A4 a4) {
    if (!isInitial && identical(a1, prevA1) && identical(a2, prevA2) && identical(a3, prevA3)) {
      return prevResult;
    } else {
      prevA1 = a1;
      prevA2 = a2;
      prevA3 = a3;
      prevResult = func(a1, a2, a3, a4);
      isInitial = false;

      return prevResult;
    }
  });
}

/// Checks 4 arguments for equality with [identical] call and returns the cached
/// result if they were not changed.
///
/// Allows to pass additional payload, that is not accounted in memoization.
Func5<A1, A2, A3, A4, A5, R> imemo4plus1<A1, A2, A3, A4, A5, R>(Func5<A1, A2, A3, A4, A5, R> func) {
  late A1 prevA1;
  late A2 prevA2;
  late A3 prevA3;
  late A4 prevA4;
  late R prevResult;
  bool isInitial = true;

  return ((A1 a1, A2 a2, A3 a3, A4 a4, A5 a5) {
    if (!isInitial &&
        identical(a1, prevA1) &&
        identical(a2, prevA2) &&
        identical(a3, prevA3) &&
        identical(a4, prevA4)) {
      return prevResult;
    } else {
      prevA1 = a1;
      prevA2 = a2;
      prevA3 = a3;
      prevA4 = a4;
      prevResult = func(a1, a2, a3, a4, a5);
      isInitial = false;

      return prevResult;
    }
  });
}
