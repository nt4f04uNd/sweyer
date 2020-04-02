/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract class FirebaseControl {
  static void init() {
    Crashlytics.instance.enableInDevMode = true;
    Crashlytics.instance.setUserEmail("test@test.com");
    Crashlytics.instance.setUserIdentifier("test_id");
    Crashlytics.instance.setUserName("test name");
  }
}
