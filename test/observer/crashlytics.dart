import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../test.dart';

/// An observer for crashlytics messages.
class CrashlyticsObserver implements FirebaseCrashlytics {
  /// Whether to throw fatal errors.
  final bool throwFatalErrors;

  /// The number of reported non-fatal errors.
  int get nonFatalErrorCount => _nonFatalErrorCount;
  int _nonFatalErrorCount = 0;

  /// The number of reported fatal errors.
  int get fatalErrorCount => _fatalErrorCount;
  int _fatalErrorCount = 0;

  /// The number of reported errors.
  int get errorCount => _fatalErrorCount + _nonFatalErrorCount;

  /// Create a new crashlytics observer, which automatically
  /// unregisters any previously created observer.
  CrashlyticsObserver({this.throwFatalErrors = true}) : app = FirebaseCrashlytics.instance.app {
    crashlytics = this;
  }

  @override
  FirebaseApp app;

  @override
  Future<bool> checkForUnsentReports() => FirebaseCrashlytics.instance.checkForUnsentReports();

  @override
  void crash() => FirebaseCrashlytics.instance.crash();

  @override
  Future<void> deleteUnsentReports() => FirebaseCrashlytics.instance.deleteUnsentReports();

  @override
  Future<bool> didCrashOnPreviousExecution() => FirebaseCrashlytics.instance.didCrashOnPreviousExecution();

  @override
  bool get isCrashlyticsCollectionEnabled => FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled;

  @override
  Future<void> log(String message) => FirebaseCrashlytics.instance.log(message);

  @override
  Map<dynamic, dynamic> get pluginConstants => FirebaseCrashlytics.instance.pluginConstants;

  @override
  Future<void> recordError(exception, StackTrace? stack,
      {reason, Iterable<Object> information = const [], bool? printDetails, bool fatal = false}) async {
    if (fatal) {
      _fatalErrorCount++;
      if (throwFatalErrors) {
        throw exception;
      }
    } else {
      _nonFatalErrorCount++;
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails flutterErrorDetails, {bool fatal = false}) =>
      FirebaseCrashlytics.instance.recordFlutterError(flutterErrorDetails, fatal: fatal);

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails flutterErrorDetails) =>
      FirebaseCrashlytics.instance.recordFlutterError(flutterErrorDetails);

  @override
  Future<void> sendUnsentReports() => FirebaseCrashlytics.instance.sendUnsentReports();

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) =>
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> setCustomKey(String key, Object value) => FirebaseCrashlytics.instance.setCustomKey(key, value);

  @override
  Future<void> setUserIdentifier(String identifier) => FirebaseCrashlytics.instance.setUserIdentifier(identifier);
}
