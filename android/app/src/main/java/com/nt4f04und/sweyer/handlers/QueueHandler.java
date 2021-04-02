/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.os.AsyncTask;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.player.Song;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.Nullable;

import android.util.Log;

import io.flutter.view.FlutterMain;

/**
 * Holds songs data on service side.
 * It's a temporary container for queue, when activity is destroyed, for service to continue functioning as normal.
 */
public class QueueHandler {

   private static ArrayList<Song> songs;
   private static boolean customQueue = false;
   public static HashMap<String, Integer> idMap = null;
   /**
    * Normally, it will come on activity start from dart code
    */
   private static Song currentSong;
   // Primary app color to blend it into album art mask
   private static Integer primaryColor;
   private static byte[] currentSongArtBytes;
   private static byte[] artPlaceholderBytes;
   private static CurrentSongArtAsyncTask artAsyncTask;

   private static class CurrentSongArtAsyncTask extends AsyncTask<Song, Void, byte[]> {
      private Integer songId;

      @Override
      protected byte[] doInBackground(Song... newSong) {
         byte[] bytes = null;
         Song song = newSong[0];
         if (song == null) {
            song = currentSong;
         }
         if (song != null) {
            songId = song.id;
            bytes = FetchHandler.getArtBytes(song.data);
         }
         if (bytes == null) {
            getArtPlaceholder();
            bytes = artPlaceholderBytes;
         }
         return bytes;
      }

      @Override
      protected void onPostExecute(byte[] bytes) {
         super.onPostExecute(bytes);
         // Needed to not apply async task result for stale arts
         if (songId != null && songId.equals(QueueHandler.currentSong.id)) {
            currentSongArtBytes = bytes;
            NotificationHandler.updateNotification(true, PlayerHandler.isLooping());
            artAsyncTask = null;
         }
      }
   }


   private static final int mask = 0x1a;

   private static int clamp(int val, int min, int max) {
      return Math.max(min, Math.min(max, val));
   }

   /**
    * Copy of `getColorForBlend` on dart side in `lib/core/colors.dart`
    */
   private static int getColorForBlend(int color) {
      final int r = clamp((((color >> 16) & 0xff) - mask), 0, 0xff);
      final int g = clamp((((color >> 8) & 0xff) - mask), 0, 0xff);
      final int b = clamp(((color & 0xff) - mask), 0, 0xff);
      return (0xff << 24) + (r << 16) + (g << 8) + b;
   }

   private static void getArtPlaceholder() {
      if (artPlaceholderBytes == null) {
         AssetManager assetManager = GeneralHandler.getAppContext().getAssets();
         String key = FlutterMain.getLookupKeyForAsset("assets/images/logo_mask_thumb_notification.png");
         try {
            InputStream inputStream = assetManager.open(key);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
            // Canvas can accept only mutable bitmaps
            bitmap = bitmap.copy(bitmap.getConfig(), true);

            if (primaryColor == null) {
               primaryColor = (int) PrefsHandler.getSettingPrimaryColor();
            }
            // Applying color to mask
            // https://stackoverflow.com/a/31970565/9710294
            Paint paint = new Paint();
            ColorFilter filter = new PorterDuffColorFilter(getColorForBlend(primaryColor), PorterDuff.Mode.ADD);
            paint.setColorFilter(filter);
            Canvas canvas = new Canvas(bitmap);
            canvas.drawBitmap(bitmap, 0, 0, paint);

            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
            artPlaceholderBytes = outputStream.toByteArray();
         } catch (IOException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            artPlaceholderBytes = null;
         }
      }
   }

   public static void reloadArtPlaceholder(int color) {
      primaryColor = (int) color;
      artPlaceholderBytes = null;
      if (artAsyncTask != null) {
         artAsyncTask.cancel(true);
      }
      artAsyncTask = new CurrentSongArtAsyncTask();
      artAsyncTask.execute((Song) null);
   }

   /**
    * This method restores queue when activity is destroyed
    */
   public static void restoreQueue() {
      if (songs == null) { // Songs will be reset to null every time app activity starts
         initIdMap();
         int[] ids;
         ArrayList<Song> fetchedSongs;
         ArrayList<Song> songs = new ArrayList<>();
         ids = new Gson().fromJson(SerializationHandler.loadJson(SerializationHandler.getFlutterAppPath() + "queue.json"), int[].class);
         fetchedSongs = FetchHandler.retrieveSongsForBackground();

         if (ids.length == 0) {
            // If queue array happened is empty, then leave as it is.
            // It might be not ok, as queue always should contain something (except before initial launch).
            QueueHandler.songs = fetchedSongs;
            customQueue = false;
         } else {
            customQueue = true;
            for (int songId : ids) {
               for (int j = 0; j < fetchedSongs.size(); j++) {
                  boolean negative = songId < 0;
                  int sourceId = negative ? idMap.get(String.valueOf(songId)) : songId;
                  if (sourceId == fetchedSongs.get(j).id) {
                     Song song = new Song(fetchedSongs.get(j));
                     if (negative) {
                        song.id = songId;
                     }
                     songs.add(song);
                     break;
                  }
               }
            }
            QueueHandler.songs = songs;
         }
      }
   }

   /**
    * Handle case when playingSong is null
    * This can be considered as case when activity did not start (or didn't call send song method for some reason, e.g. songs list is empty)
    */
   public static void initCurrentSong() {
      if (currentSong == null) {
         restoreQueue();
         setCurrentSong(searchById((int) PrefsHandler.getSongId()));
      }
   }

   public static void initIdMap() {
      if (idMap == null) {
         Type mapType = new TypeToken<HashMap<String, Integer>>() {
         }.getType();
         idMap = new Gson().fromJson(SerializationHandler.loadJson(SerializationHandler.getFlutterAppPath() + "id_map.json"), mapType);
      }
   }

   public static void handleDuplicate(Song song, Boolean duplicate) {
      initIdMap();
      boolean inBackground = duplicate == null;
      if (inBackground) { // If null, this means that the activity does not exist.
         duplicate = false;
         if (customQueue) {
            int count = 0;
            for (Song _song : QueueHandler.songs) {
               if (_song.id == song.id) {
                  count++;
                  if (count == 2) {
                     duplicate = true;
                     break;
                  }
               }
            }
         }
      }
      if (duplicate) {
         int newId = -(idMap.size() + 1);
         idMap.put(String.valueOf(newId), song.id);
         song.id = newId;
         Gson gson = new Gson();
         SerializationHandler.saveJson(SerializationHandler.getFlutterAppPath() + "id_map.json", gson.toJson(idMap));
         if (inBackground) {
            int[] ids = new int[songs.size()];
            for (int i = 0; i < songs.size(); i++) {
               ids[i] = songs.get(i).id;
            }
            SerializationHandler.saveJson(SerializationHandler.getFlutterAppPath() + "queue.json", gson.toJson(ids));
         }
      }
   }

   public static void resetQueue() {
      songs = null;
   }

   public static Song getCurrentSong() {
      return currentSong;
   }

   public static void setCurrentSong(Song newSong) {
      if (newSong != null) {
         currentSong = newSong;
         if (artAsyncTask != null) {
            artAsyncTask.cancel(true);
         }
         artAsyncTask = new CurrentSongArtAsyncTask();
         artAsyncTask.execute(newSong);
      }
   }

   /**
    * Returns current song art
    */
   @Nullable
   public static byte[] getArt() {
      return currentSongArtBytes;
   }

   /**
    * Will return current song
    * Returns `null` if `songs` array is empty
    */
   @Nullable
   private static Integer getCurrentSongIndex() {
      if (songs.size() <= 0) {
         Log.e(Constants.LogTag, "Error: called `getCurrentSong` when songs array has 0 length!");
         return null;
      }
      for (int i = 0; i < songs.size(); i++) {
         if (songs.get(i).id == currentSong.id) return i;
      }
      return null;
   }

   public static Song getNextSong() {
      Integer new_idx = getCurrentSongIndex();
      if (new_idx == null)
         new_idx = 0;
      else
         new_idx = new_idx + 1 > songs.size() - 1 ? 0 : new_idx + 1;
      return songs.get(new_idx);
   }

   public static Song getPrevSong() {
      Integer new_idx = getCurrentSongIndex();
      if (new_idx == null)
         new_idx = 0;
      else
         new_idx = new_idx - 1 < 0 ? songs.size() - 1 : new_idx - 1;
      return songs.get(new_idx);
   }

   @Nullable
   public static Song searchById(int id) {
      if (songs.size() <= 0) {
         Log.e(Constants.LogTag, "Error: called `searchById` when songs array has 0 length!");
         return null;
      }
      for (int i = 0; i < songs.size(); i++) {
         Song song = songs.get(i);
         if (song.id == id) {
            return song;
         }
      }
      return null;
   }

}
