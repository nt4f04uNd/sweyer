/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.services;

import android.app.PendingIntent;
import android.app.Service;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.IntentSender;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.IBinder;
import android.provider.MediaStore;
import android.util.Log;

import com.google.gson.Gson;
import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.channels.GeneralChannel;
import com.nt4f04uNd.sweyer.handlers.FetchHandler;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.player.Song;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.Nullable;

import org.json.JSONObject;

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
         Song[] songs = new Gson().fromJson((String) (String) intent.getSerializableExtra("songs"), Song[].class);
         ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
         Gson gson = new Gson();

         // I'm setting `android:requestLegacyExternalStorage="true"`, because there's no consistent way
         // to delete a bulk of music files in scoped storage in Android Q, or at least I didn't find it
         //
         // See https://stackoverflow.com/questions/58283850/scoped-storage-how-to-delete-multiple-audio-files-via-mediastore
         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            ArrayList<Uri> uris = new ArrayList<>();
            // Populate `songListSuccessful` with uris for the intent
            for (Song song : songs) {
               uris.add(FetchHandler.getSongUri(song.id));
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
               Log.e(Constants.LogTag, "deletion intent error: " + e.getMessage());
            }
         } else {
            ArrayList<String> songListSuccessful = new ArrayList<>();
            // Delete files and populate `songListSuccessful` with successful uris
            for (Song song : songs) {
               File file = new File(song.data);

               if (file.exists()) {
                  // Delete the actual file
                  if (file.delete()) {
                     songListSuccessful.add(song.data);
                  } else {
                     Log.e(Constants.LogTag, "file not deleted: " + song.data);
                  }
               }
            }

            Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
            String where = buildWhereClauseForDeletion(songs.length);
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
