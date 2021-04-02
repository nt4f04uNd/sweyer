/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Intent;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.gson.Gson;
import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.player.Album;
import com.nt4f04und.sweyer.player.Song;
import com.nt4f04und.sweyer.services.DeletionService;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.MethodChannel;

public class FetchHandler {

   public static class SearchSongsTask extends AsyncTask<MethodChannel.Result, Void, List<String>> {
      private MethodChannel.Result result;

      @Override
      protected List<String> doInBackground(MethodChannel.Result... params) {
         result = params[0];
         return retrieveSongs();
      }

      @Override
      protected void onPostExecute(List<String> songs) {
         result.success(songs);
      }
   }

   public static class SearchAlbumsTask extends AsyncTask<MethodChannel.Result, Void, List<String>> {
      private MethodChannel.Result result;

      @Override
      protected List<String> doInBackground(MethodChannel.Result... params) {
         result = params[0];
         return retrieveAlbums();
      }

      @Override
      protected void onPostExecute(List<String> albums) {
         result.success(albums);
      }
   }

   /// Projection used in `retrieveSongs`
   private static final String[] songProjection = {
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
   };

   /// Projection used in `retrieveSongsForBackground`
   /// Gets only fields needed for background playback without an activity
   private static final String[] songForBackgroundProjection = {
           MediaStore.Audio.Media._ID,
           MediaStore.Audio.Media.ALBUM_ID,
           MediaStore.Audio.Media.ARTIST,
           MediaStore.Audio.Media.ARTIST_ID,
           MediaStore.Audio.Media.TITLE,
           MediaStore.Audio.Media.DATA,
   };

   /// Projection used in `retrieveAlbums`
   private static final String[] albumProjection = {
           MediaStore.Audio.Albums._ID,
           MediaStore.Audio.Albums.ALBUM,
           MediaStore.Audio.Albums.ALBUM_ART,
           MediaStore.Audio.Albums.ARTIST,
           MediaStore.Audio.Albums.ARTIST_ID,
           MediaStore.Audio.Albums.FIRST_YEAR,
           MediaStore.Audio.Albums.LAST_YEAR,
           MediaStore.Audio.Albums.NUMBER_OF_SONGS
   };

   /// Will return null if there's no artwork.
   @Nullable
   public static byte[] getArtBytes(String path) {
      MediaMetadataRetriever retriever = new MediaMetadataRetriever();
      try {
         retriever.setDataSource(path);
      } catch (IllegalArgumentException ex) {
         // Catch when the content by specified path doesn't exist
         return null;
      }
      return retriever.getEmbeddedPicture();
   }

   /// Accepts json string of array of songs
   public static void deleteSongs(String songs) {
      Intent serviceIntent = new Intent(GeneralHandler.getAppContext(), DeletionService.class);
      serviceIntent.putExtra("songs", songs);
      GeneralHandler.getAppContext().startService(serviceIntent);
   }

   /**
    * Retrieve a list of music files currently listed in the Media store DB via URI.
    */
   public static ArrayList<String> retrieveSongs() {
      ArrayList<String> songs = new ArrayList<>();
      // Some audio may be explicitly marked as not being music
      String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
      String sortOrder = MediaStore.Audio.Media.DATE_MODIFIED + " DESC";

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              songProjection,
              selection,
              null,
              sortOrder
      );

      if (cursor == null) {
         return songs;
      }

      Gson gson = new Gson();
      while (cursor.moveToNext()) {
         songs.add(
                 gson.toJson(new Song(
                         cursor.getInt(0),
                         cursor.getString(1),
                         cursor.getInt(2),
                         cursor.getString(3),
                         cursor.getInt(4),
                         cursor.getString(5),
                         cursor.getString(6),
                         cursor.getInt(7),
                         cursor.getInt(8),
                         cursor.getInt(9),
                         cursor.getInt(10),
                         cursor.getString(11)
                 )));
      }
      cursor.close();
      return songs;
   }

   /**
    * Retrieve a list of music files currently listed in the Media store DB via URI.
    * <p>
    * Needed to fetch songs when the activity is not opened.
    */
   public static ArrayList<Song> retrieveSongsForBackground() {
      ArrayList<Song> songs = new ArrayList<>();
      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();

      // Some audio may be explicitly marked as not being music
      String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
      String sortOrder = MediaStore.Audio.Media.DATE_MODIFIED + " DESC";

      Cursor cursor = resolver.query(
              MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              songForBackgroundProjection,
              selection,
              null,
              sortOrder
      );

      if (cursor == null) {
         return songs;
      }

      while (cursor.moveToNext()) {
         songs.add(
                 new Song(
                         cursor.getInt(0),
                         null,
                         cursor.getInt(1),
                         cursor.getString(2),
                         cursor.getInt(3),
                         cursor.getString(4),
                         null,
                         0,
                         0,
                         0,
                         0,
                         cursor.getString(5)
                 )
         );
      }
      cursor.close();
      return songs;
   }

   public static ArrayList<String> retrieveAlbums() {
      ArrayList<String> albums = new ArrayList<>();
      String selection = MediaStore.Audio.Albums.ALBUM + " IS NOT NULL";
      String sortOrder = MediaStore.Audio.Albums._ID + " ASC";

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
              albumProjection,
              selection,
              null,
              sortOrder
      );


      if (cursor == null) {
         return albums;
      }

      Gson gson = new Gson();
      while (cursor.moveToNext()) {
         String album = gson.toJson(new Album(
                 cursor.getInt(0),
                 cursor.getString(1),
                 cursor.getString(2),
                 cursor.getString(3),
                 cursor.getInt(4),
                 cursor.getInt(5),
                 cursor.getInt(6),
                 cursor.getInt(7)
         ));

         albums.add(
                 album
         );
      }
      cursor.close();
      return albums;
   }
}
