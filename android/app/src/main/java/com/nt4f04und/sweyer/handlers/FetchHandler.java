/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.provider.MediaStore;

import com.nt4f04und.sweyer.services.DeletionService;

import java.util.ArrayList;
import java.util.HashMap;

public class FetchHandler {
   /// Accepts json string of array of songs
   public static void deleteSongs(ArrayList<HashMap<?, ?>> songs) {
      Intent serviceIntent = new Intent(GeneralHandler.getAppContext(), DeletionService.class);
      serviceIntent.putExtra("songs", songs);
      GeneralHandler.getAppContext().startService(serviceIntent);
   }

   public static ArrayList<HashMap<?, ?>> retrieveSongs() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();
      // Some audio may be explicitly marked as not being music
      String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
      String sortOrder = MediaStore.Audio.Media.DATE_MODIFIED + " DESC";

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              new String[]{
                      MediaStore.Audio.Media._ID,
                      MediaStore.Audio.Media.ALBUM,
                      MediaStore.Audio.Media.ALBUM_ID,
                      MediaStore.Audio.Media.ARTIST,
                      MediaStore.Audio.Media.ARTIST_ID,
                      // TODO: COMPOSER ?????
                      // TODO: BOOKMARK ?????
                      // TODO: GENRE ?????
                      // TODO: GENRE_ID ?????
                      MediaStore.Audio.Media.TITLE,
                      MediaStore.Audio.Media.TRACK, // position in album
                      // TODO: TITLE_RESOURCE_URI ?????
                      // TODO: YEAR ?????
                      MediaStore.Audio.Media.DATE_ADDED,
                      MediaStore.Audio.Media.DATE_MODIFIED,
                      MediaStore.Audio.Media.DURATION,
                      MediaStore.Audio.Media.SIZE,
                      MediaStore.Audio.Media.DATA,
              },
              selection,
              null,
              sortOrder
      );

      if (cursor == null) {
         return maps;
      }
      while (cursor.moveToNext()) {
         HashMap<String, Object> map = new HashMap();
         map.put("id", cursor.getInt(0));
         map.put("album", cursor.getString(1));
         map.put("albumId", cursor.getInt(2));
         map.put("artist", cursor.getString(3));
         map.put("artistId", cursor.getInt(4));
         map.put("title", cursor.getString(5));
         map.put("track", cursor.getString(6));
         map.put("dateAdded", cursor.getInt(7));
         map.put("dateModified", cursor.getInt(8));
         map.put("duration", cursor.getInt(9));
         map.put("size", cursor.getInt(10));
         map.put("data", cursor.getString(11));
         maps.add(map);
      }
      cursor.close();
      return maps;
   }

   public static ArrayList<HashMap<?, ?>> retrieveAlbums() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();
      String selection = MediaStore.Audio.Albums.ALBUM + " IS NOT NULL";
      String sortOrder = MediaStore.Audio.Albums._ID + " ASC";

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
              new String[]{
                      MediaStore.Audio.Albums._ID,
                      MediaStore.Audio.Albums.ALBUM,
                      MediaStore.Audio.Albums.ALBUM_ART,
                      MediaStore.Audio.Albums.ARTIST,
                      MediaStore.Audio.Albums.ARTIST_ID,
                      MediaStore.Audio.Albums.FIRST_YEAR,
                      MediaStore.Audio.Albums.LAST_YEAR,
                      MediaStore.Audio.Albums.NUMBER_OF_SONGS
              },
              selection,
              null,
              sortOrder
      );


      if (cursor == null) {
         return maps;
      }
      while (cursor.moveToNext()) {
         HashMap<String, Object> map = new HashMap();
         map.put("id", cursor.getInt(0));
         map.put("album", cursor.getString(1));
         map.put("albumArt", cursor.getString(2));
         map.put("artist", cursor.getString(3));
         map.put("artistId", cursor.getInt(4));
         map.put("firstYear", cursor.getInt(5));
         map.put("lastYear", cursor.getInt(6));
         map.put("numberOfSongs", cursor.getInt(7));
         maps.add(map);
      }
      cursor.close();
      return maps;
   }
}
