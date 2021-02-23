/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.content.Context;
import android.content.pm.PackageManager;

import com.nt4f04und.sweyer.Constants;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import android.util.Log;

public class SerializationHandler {

   public static String getFlutterAppPath() {
      try {
         String directory = GeneralHandler.getAppContext().getPackageManager().getPackageInfo(GeneralHandler.getAppContext().getPackageName(), 0).applicationInfo.dataDir;
         return directory + "/app_flutter/";
      } catch (PackageManager.NameNotFoundException e) {
         Log.w(Constants.LogTag, "Error Package name not found", e);
         return "<error>";
      }
   }


   public static void saveJson(String uri, String json) {
      try {
         FileOutputStream fileOutputStream = new FileOutputStream(uri);
         fileOutputStream.write(json.getBytes());
         fileOutputStream.close();
      } catch (IOException e) {
         e.printStackTrace();
      }
   }

   public static String loadJson(String uri) {
      try {
         FileInputStream fileInputStream = new FileInputStream(uri);
         int size = fileInputStream.available();
         byte[] buffer = new byte[size];
         fileInputStream.read(buffer);
         fileInputStream.close();
         return new String(buffer, StandardCharsets.UTF_8);
      } catch (IOException e) {
         e.printStackTrace();
         return null;
      }

   }

}
