import 'package:flutter/foundation.dart';

T measure<T>(Function callback) {
  final s = Stopwatch();
  s.start();
  final result = callback();
  s.stop();
  debugPrint('elapsed ${s.elapsedMicroseconds}');
  return result;
}
