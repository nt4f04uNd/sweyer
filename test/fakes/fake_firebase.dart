import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

import '../observer/crashlytics.dart';
import '../test.dart';

class FakeFirebaseApp extends MockFirebaseApp {
  static Future<void> install() async {
    TestFirebaseCoreHostApi.setUp(FakeFirebaseApp());
    await Firebase.initializeApp();
    crashlytics = CrashlyticsObserver(throwFatalErrors: true); // Register throwing crashlytics observer.
  }

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    var response = await super.initializeApp(appName, initializeAppRequest);
    response.pluginConstants['isCrashlyticsCollectionEnabled'] = false;
    response.isAutomaticDataCollectionEnabled = false;
    return response;
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    var responseList = await super.initializeCore();
    for (var response in responseList.nonNulls) {
      response.pluginConstants['isCrashlyticsCollectionEnabled'] = false;
      response.isAutomaticDataCollectionEnabled = false;
    }
    return responseList;
  }
}
