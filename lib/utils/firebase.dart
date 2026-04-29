import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

@visibleForTesting
bool printFirebaseErrors = true;

Future<void> reportErrorToFirebase(
  dynamic exception,
  StackTrace? stack, {
  dynamic reason,
  Iterable<Object> information = const [],
}) =>
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: false,
      printDetails: printFirebaseErrors,
    );

Future<void> reportFatalErrorToFirebase(
  dynamic exception,
  StackTrace? stack, {
  dynamic reason,
  Iterable<Object> information = const [],
}) =>
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: true,
      printDetails: printFirebaseErrors,
    );
