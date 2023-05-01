package com.nt4f04und.sweyer.sweyer_plugin.services;

import android.app.PendingIntent;
import android.app.Service;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Log;

import com.nt4f04und.sweyer.sweyer_plugin.Constants;
import com.nt4f04und.sweyer.sweyer_plugin.SweyerPlugin;
import com.nt4f04und.sweyer.sweyer_plugin.handlers.FetchHandler;

import java.io.File;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import androidx.annotation.Nullable;

public class DeletionService extends Service {
    /** The name of the argument where an array of DeletionItems is expected to be passed. */
    private final static String SONGS_ARGUMENT = "songs";

   @Override
   public int onStartCommand(Intent intent, int flags, int startId) {
      ExecutorService executor = Executors.newSingleThreadExecutor();
      Handler handler = new Handler(Looper.getMainLooper());
      executor.submit(() -> {
         DeletionItem[] songs = (DeletionItem[]) intent.getSerializableExtra(SONGS_ARGUMENT);
         ContentResolver resolver = getContentResolver();

         // I'm setting `android:requestLegacyExternalStorage="true"`, because there's no consistent way
         // to delete a bulk of music files in scoped storage in Android Q, or at least I didn't find it
         //
         // See https://stackoverflow.com/questions/58283850/scoped-storage-how-to-delete-multiple-audio-files-via-mediastore
         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            ArrayList<Uri> uris = new ArrayList<>();
            // Populate `songListSuccessful` with uris for the intent
            for (DeletionItem song : songs) {
               uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, song.id));
            }
            PendingIntent pendingIntent = MediaStore.createDeleteRequest(
                    getContentResolver(),
                    uris
            );
            handler.post(() -> {
               // On R it's required to request an OS permission for file deletions
               SweyerPlugin.instance.startIntentSenderForResult(pendingIntent, Constants.intents.PERMANENT_DELETION_REQUEST);
            });
         } else {
            ArrayList<String> songListSuccessful = new ArrayList<>();
            // Delete files and populate `songListSuccessful` with successful uris
            for (DeletionItem song : songs) {
               String path = song.path;
               if (path == null) {
                  Log.e(Constants.LogTag, "File without path not deleted");
                  continue;
               }
               File file = new File(path);
               if (file.exists()) {
                  // Delete the actual file
                  if (file.delete()) {
                     songListSuccessful.add(path);
                  } else {
                     Log.e(Constants.LogTag, "File not deleted: " + path);
                  }
               }
            }

            Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
            String where = FetchHandler.buildWhereForCount(
                    MediaStore.Audio.Media.DATA, songs.length);
            String[] selectionArgs = songListSuccessful.toArray(new String[0]);
            // Delete file from `MediaStore`
            resolver.delete(uri, where, selectionArgs);
            resolver.notifyChange(uri, null);
            SweyerPlugin.instance.sendResultFromIntent(true);
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

   /**
    * Start this service with a list of songs to delete.
    *
    * @param context The context that is used to start the service.
    * @param songs The list of songs to delete.
    */
   public static void start(Context context, DeletionItem[] songs) {
      Intent serviceIntent = new Intent(context, DeletionService.class);
      serviceIntent.putExtra(SONGS_ARGUMENT, songs);
      context.startService(serviceIntent);
   }

   /**
    * An item that is to be deleted.
    */
   public static class DeletionItem implements Serializable {
       /**
        * The id of the item.
        */
       final public Long id;

       /**
        * The absolute path to this item on the file system, if available.
        */
       @Nullable
       final public String path;

       public DeletionItem(Long id, @Nullable String path) {
           this.id = id;
           this.path = path;
       }
   }
}
