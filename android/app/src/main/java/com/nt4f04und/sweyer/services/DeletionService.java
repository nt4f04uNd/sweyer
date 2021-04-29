/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.services;

import android.app.PendingIntent;
import android.app.Service;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.Nullable;

import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.channels.ContentChannel;
import com.nt4f04und.sweyer.handlers.FetchHandler;
import com.nt4f04und.sweyer.handlers.GeneralHandler;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class DeletionService extends Service {
   @Override
   public int onStartCommand(Intent intent, int flags, int startId) {
      ExecutorService executor = Executors.newSingleThreadExecutor();
      Handler handler = new Handler(Looper.getMainLooper());
      executor.submit(() -> {
         ArrayList<HashMap<String, Object>> songs = (ArrayList<HashMap<String, Object>>) intent.getSerializableExtra("songs");
         ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();

         // I'm setting `android:requestLegacyExternalStorage="true"`, because there's no consistent way
         // to delete a bulk of music files in scoped storage in Android Q, or at least I didn't find it
         //
         // See https://stackoverflow.com/questions/58283850/scoped-storage-how-to-delete-multiple-audio-files-via-mediastore
         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            ArrayList<Uri> uris = new ArrayList<>();
            // Populate `songListSuccessful` with uris for the intent
            for (HashMap<String, Object> song : songs) {
               Long id = GeneralHandler.getLong(song.get("id"));
               uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id));
            }
            PendingIntent pendingIntent = MediaStore.createDeleteRequest(
                    GeneralHandler.getAppContext().getContentResolver(),
                    uris
            );
            handler.post(() -> {
               // On R it's required to request an OS permission for file deletions
               ContentChannel.instance.startDeletion(pendingIntent);
            });
         } else {
            ArrayList<String> songListSuccessful = new ArrayList<>();
            // Delete files and populate `songListSuccessful` with successful uris
            for (HashMap<String, Object> song : songs) {
               String data = (String) song.get("data");
               File file = new File(data);

               if (file.exists()) {
                  // Delete the actual file
                  if (file.delete()) {
                     songListSuccessful.add(data);
                  } else {
                     Log.e(Constants.LogTag, "file not deleted: " + data);
                  }
               }
            }

            Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
            String where = FetchHandler.buildWhereForCount(MediaStore.Audio.Media.DATA, songs.size());
            String[] selectionArgs = songListSuccessful.toArray(new String[0]);
            // Delete file from `MediaStore`
            resolver.delete(uri, where, selectionArgs);
            resolver.notifyChange(uri, null);
         }
         stopSelf();
      });
      return super.onStartCommand(intent, flags, startId);
   }

   @Nullable
   @Override
   public IBinder onBind(Intent intent) {
      return null;
   }
}
