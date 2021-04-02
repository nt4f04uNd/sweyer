/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer;

import android.content.Intent;
import android.os.Bundle;

import com.nt4f04und.sweyer.channels.GeneralChannel;
import com.nt4f04und.sweyer.channels.NativeEventsChannel;
import com.nt4f04und.sweyer.channels.PlayerChannel;
import com.nt4f04und.sweyer.channels.ContentChannel;
import com.nt4f04und.sweyer.handlers.AudioFocusHandler;
import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.nt4f04und.sweyer.handlers.MediaSessionHandler;
import com.nt4f04und.sweyer.handlers.PlayerHandler;
import com.nt4f04und.sweyer.handlers.QueueHandler;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.BinaryMessenger;

public class MainActivity extends FlutterActivity {

   @Override
   protected void onCreate(@Nullable Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);

      // Setup handlers and channels
      // ----------------------------------------------------------------------------------
      // Clear queue kept in memory for background playing
      // All the handling for playback now is delegated to a dart side
      QueueHandler.resetQueue();
      GeneralHandler.init(getApplicationContext()); // The most important, as it contains app context
      PlayerHandler.init(); // Create player
      GeneralChannel.instance.init(getFlutterView(), this); // Inits general channel
      AudioFocusHandler.init();
      NativeEventsChannel.instance.init(getFlutterView()); // Inits event channel
      PlayerChannel.instance.init(getFlutterView()); // Inits player channel
      MediaSessionHandler.init();
      ContentChannel.instance.init(getFlutterView());
   }

   BinaryMessenger getFlutterView() {
      return getFlutterEngine().getDartExecutor().getBinaryMessenger();
   }

   @Override
   protected void onActivityResult(int requestCode, int resultCode, Intent data) {
      super.onActivityResult(requestCode, resultCode, data);
      if (requestCode == Constants.intents.PERMANENT_DELETION_REQUEST) {
         // Report deletion intent result on android R
         ContentChannel.instance.sendDeletionResult(resultCode == RESULT_OK);
      }
   }

   @Override
   protected void onDestroy() {
      super.onDestroy();
      NativeEventsChannel.instance.kill();
      GeneralChannel.instance.kill();
      PlayerChannel.instance.kill();
      ContentChannel.instance.kill();
   }
}
