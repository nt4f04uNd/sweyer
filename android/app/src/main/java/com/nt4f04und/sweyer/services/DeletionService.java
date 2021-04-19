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
import android.content.IntentSender;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.IBinder;
import android.provider.MediaStore;
import android.util.Log;

import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.channels.GeneralChannel;
import com.nt4f04und.sweyer.handlers.GeneralHandler;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.Nullable;

public class DeletionService extends Service {

   /// Produces the `where` parameter for deleting songs from the `MediaStore`
   /// Creates the string like "_data IN (?, ?, ?, ...)"
   private static String buildWhereClauseForDeletion(int count) {
      StringBuilder builder = new StringBuilder(MediaStore.Audio.Media.DATA);
      builder.append(" IN (");
      for (int i = 0; i < count - 1; i++) {
         builder.append("?, ");
      }
      builder.append("?)");
      return builder.toString();
   }

   @Override
   public int onStartCommand(Intent intent, int flags, int startId) {
      AsyncTask.execute(() -> {
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
               Object rawId = song.get("id");
               Long id;
               if (rawId instanceof Long) {
                  id = (Long) rawId;
               } else if (rawId instanceof Integer) {
                  id = Long.valueOf((Integer) rawId);
               } else {
                  throw new IllegalArgumentException();
               }
               uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id));
            }
            PendingIntent pendingIntent = MediaStore.createDeleteRequest(
                    GeneralChannel.instance.activity.getContentResolver(),
                    uris
            );
            try {
               // On R we are now to request an OS permission for file deletions
               GeneralChannel.instance.activity.startIntentSenderForResult(
                       pendingIntent.getIntentSender(),
                       Constants.intents.PERMANENT_DELETION_REQUEST,
                       null,
                       0,
                       0,
                       0);
            } catch (IntentSender.SendIntentException e) {
               Log.e(Constants.LogTag, "DELETION_INTENT_ERROR: " + e.getMessage());
            }
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
            String where = buildWhereClauseForDeletion(songs.size());
            String[] selectionArgs = songListSuccessful.toArray(new String[0]);
            // Delete file from `MediaStore`
            resolver.delete(uri, where, selectionArgs);
         }
      });
      return super.onStartCommand(intent, flags, startId);
   }

   @Nullable
   @Override
   public IBinder onBind(Intent intent) {
      return null;
   }
}
