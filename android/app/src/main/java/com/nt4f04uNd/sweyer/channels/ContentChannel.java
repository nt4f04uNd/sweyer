/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import com.google.gson.Gson;
import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.FetchHandler;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public enum ContentChannel {
   instance;

   public void init(BinaryMessenger messenger) {
      if (channel == null) {
         channel = new MethodChannel(messenger, "contentChannel");
         channel.setMethodCallHandler(this::onMethodCall);
      }
   }

   public void kill() {
      channel = null;
   }

   @Nullable
   MethodChannel channel;
   @Nullable
   private MethodChannel.Result result;

   public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
      // Note: this method is invoked on the main thread.
      try {
         switch (call.method) {
            case "retrieveSongs": {
               new FetchHandler.TaskSearchSongs().executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, result);
               break;
            }
            case "retrieveAlbums": {
               new FetchHandler.TaskSearchAlbums().executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, result);
               break;
            }
            case "deleteSongs": {
               FetchHandler.deleteSongs((String) call.argument("songs"));
               if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                  // Save the result to report to the flutter code later in `sendDeletionResult`
                  this.result = result;
               } else {
                  result.success(true);
               }
               break;
            }
            default:
               result.notImplemented();
         }
      } catch (Exception e) {
         result.error("CONTENT_CHANNEL_ERROR", e.getMessage(), Log.getStackTraceString(e));
      }
   }

   public void sendDeletionResult(boolean result) {
      if (this.result != null) {
         this.result.success(result);
      }
   }
}
