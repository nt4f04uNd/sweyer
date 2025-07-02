import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';

import '../observer/crashlytics.dart';
import '../test.dart';

class FakeFirebaseApp extends MockFirebaseApp {
  static Future<void> install(TestWidgetsFlutterBinding binding) async {
    TestFirebaseCoreHostApi.setUp(FakeFirebaseApp());
    CrashlyticsObserver(binding, throwFatalErrors: true); // Register throwing crashlytics observer.
    await Firebase.initializeApp();
  }

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    var response = await super.initializeApp(appName, initializeAppRequest);
    (response.pluginConstants.putIfAbsent(MethodChannelFirebaseCrashlytics.channel.name, () => {})!
        as Map)['isCrashlyticsCollectionEnabled'] = false;
    response.isAutomaticDataCollectionEnabled = false;
    return response;
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    var responseList = await super.initializeCore();
    for (var response in responseList.nonNulls) {
      (response.pluginConstants.putIfAbsent(MethodChannelFirebaseCrashlytics.channel.name, () => {})!
          as Map)['isCrashlyticsCollectionEnabled'] = false;
      response.isAutomaticDataCollectionEnabled = false;
    }
    return responseList;
  }
}
