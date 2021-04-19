/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.channels;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.CancellationSignal;
import android.os.Handler;
import android.os.Looper;
import android.os.OperationCanceledException;
import android.util.Log;
import android.util.Size;

import com.nt4f04und.sweyer.BuildConfig;
import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.handlers.FetchHandler;
import com.nt4f04und.sweyer.handlers.GeneralHandler;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public enum ContentChannel {
   instance;

   public void init(BinaryMessenger messenger) {
      if (channel == null) {
         channel = new MethodChannel(messenger, "content_channel");
         channel.setMethodCallHandler(this::onMethodCall);
      }
   }

   public void destroy() {
      channel = null;
   }

   @Nullable
   MethodChannel channel;
   @Nullable
   private MethodChannel.Result result;
   private final HashMap<String, CancellationSignal> loadingSignals = new HashMap<>();

   public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
      try {
         switch (call.method) {
            case "loadAlbumArt": {
               if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                  ExecutorService executor = Executors.newSingleThreadExecutor();
                  Handler handler = new Handler(Looper.getMainLooper());
                  ContentResolver contentResolver = GeneralHandler.getAppContext().getContentResolver();
                  CancellationSignal signal = new CancellationSignal();
                  String id = call.argument("id");
                  loadingSignals.put(id, signal);
                  executor.execute(() -> {
                     byte[] bytes = null;
                     try {
                        Bitmap bitmap = contentResolver.loadThumbnail(
                                Uri.parse(call.argument("uri")),
                                new Size((int) call.argument("width"), (int) call.argument("height")),
                                signal);
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                        bytes = stream.toByteArray();
                        stream.close();
                     } catch (OperationCanceledException ex) {
                        // do nothing
                     } catch (IOException e) {
                        Log.e(Constants.LogTag,"loadThumbnail failed");
                        e.printStackTrace();
                     }  finally {
                        byte[] finalBytes = bytes;
                        handler.post(() -> {
                           loadingSignals.remove(id);
                           result.success(finalBytes);
                        });
                     }
                  });
               } else {
                  result.error("0", "This method requires Android Q and above", "");
               }
               break;
            }
            case "cancelAlbumArtLoading": {
               String id = call.argument("id");
               CancellationSignal signal = loadingSignals.remove(id);
               if (signal != null) {
                  signal.cancel();
               }
               result.success(null);
               break;
            }
            case "fixAlbumArt": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  Object rawId = call.argument("id");
                  Long id;
                  if (rawId instanceof Long) {
                     id = (Long) rawId;
                  } else if (rawId instanceof Integer) {
                     id = Long.valueOf((Integer) rawId);
                  } else {
                     throw new IllegalArgumentException();
                  }
                  Uri songCover = Uri.parse("content://media/external/audio/albumart");
                  Uri uriSongCover = ContentUris.withAppendedId(songCover, id);
                  ContentResolver res = GeneralChannel.instance.activity.getContentResolver();
                  try {
                     InputStream is = res.openInputStream(uriSongCover);
                     is.close();
                  } catch (Exception ex) {
                     // do nothing
                     ex.printStackTrace();
                  }
                  handler.post(() -> {
                     result.success(null);
                  });
               });
               break;
            }
            case "retrieveSongs": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveSongs();
                  handler.post(() -> {
                     result.success(res);
                  });
               });
               break;
            }
            case "retrieveAlbums": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveAlbums();
                  handler.post(() -> {
                     result.success(res);
                  });
               });
               break;
            }
            case "deleteSongs": {
               FetchHandler.deleteSongs(call.argument("songs"));
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
