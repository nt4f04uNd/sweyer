import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

@visibleForTesting
FirebaseCrashlytics? crashlytics;

FirebaseCrashlytics _getCrashlytics() => crashlytics ??= FirebaseCrashlytics.instance;

Future<void> reportErrorToFirebase(
  dynamic exception,
  StackTrace? stack, {
  dynamic reason,
  Iterable<Object> information = const [],
}) =>
    _getCrashlytics().recordError(
      exception,
      stack,
      reason: reason,
      fatal: false,
      printDetails: true,
    );

Future<void> reportFatalErrorToFirebase(
  dynamic exception,
  StackTrace? stack, {
  dynamic reason,
  Iterable<Object> information = const [],
}) =>
    _getCrashlytics().recordError(
      exception,
      stack,
      reason: reason,
      fatal: true,
      printDetails: true,
    );
