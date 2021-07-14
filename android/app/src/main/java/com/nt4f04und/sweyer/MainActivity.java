/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.nt4f04und.sweyer.channels.ContentChannel;
import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.ryanheise.audioservice.AudioServicePlugin;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;

public class MainActivity extends FlutterActivity {

   @Override
   protected void onCreate(@Nullable Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      GeneralHandler.init(getApplicationContext());
      BinaryMessenger messenger = getBinaryMessenger();
      ContentChannel.instance.init(messenger, this);
   }

   BinaryMessenger getBinaryMessenger() {
      return provideFlutterEngine(getApplicationContext()).getDartExecutor().getBinaryMessenger();
   }

   @Override
   public FlutterEngine provideFlutterEngine(Context context) {
      return AudioServicePlugin.getFlutterEngine(context);
   }

   @Override
   protected void onActivityResult(int requestCode, int resultCode, Intent data) {
      super.onActivityResult(requestCode, resultCode, data);
      if (requestCode == Constants.intents.PERMANENT_DELETION_REQUEST.value ||
              requestCode == Constants.intents.FAVORITE_REQUEST.value) {
         ContentChannel.instance.sendResultFromIntent(resultCode == RESULT_OK);
      }
   }

   @Override
   protected void onDestroy() {
      ContentChannel.instance.destroy();
      super.onDestroy();
   }
}
