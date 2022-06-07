package com.nt4f04und.sweyer.handlers;

import android.content.ContentResolver;
import android.database.Cursor;
import android.os.Build;
import android.provider.MediaStore;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class FetchHandler {
   // Some audio may be explicitly marked as not being music or be trashed (on Android R and above),
   // I'm excluding such.
   static String songsSelection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
   static String AND = " AND ";
   static {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
         songsSelection += AND +
            MediaStore.Audio.Media.IS_TRASHED + " == 0" + AND +
            MediaStore.Audio.Media.IS_PENDING + " == 0";
      }
   }


   /** Produces the `where` parameter for selection multiple items from the `MediaStore`
    *  Creates a string like "_data IN (?, ?, ?, ...)" */
   public static String buildWhereForCount(String column, int count) {
      StringBuilder builder = new StringBuilder(column);
      builder.append(" IN (");
      for (int i = 0; i < count - 1; i++) {
         builder.append("?, ");
      }
      builder.append("?)");
      return builder.toString();
   }

   public static ArrayList<HashMap<?, ?>> retrieveSongs() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();

      ArrayList<String> projection = new ArrayList<>(Arrays.asList(
              MediaStore.Audio.Media._ID,
              MediaStore.Audio.Media.ALBUM,
              MediaStore.Audio.Media.ALBUM_ID,
              MediaStore.Audio.Media.ARTIST,
              MediaStore.Audio.Media.ARTIST_ID,
              MediaStore.Audio.Media.TITLE,
              MediaStore.Audio.Media.TRACK, // position in album
              MediaStore.Audio.Media.YEAR,
              MediaStore.Audio.Media.DATE_ADDED,
              MediaStore.Audio.Media.DATE_MODIFIED,
              MediaStore.Audio.Media.DURATION,
              MediaStore.Audio.Media.SIZE,
              MediaStore.Audio.Media.DATA

              // Found useless/redundant:
              //
              // * ALBUM_ARTIST - for this one I can simply check the song album
              //
              // * AUTHOR
              // * COMPOSER
              // * WRITER
              //
              // * BITRATE
              // * CAPTURE_FRAMERATE
              // * CD_TRACK_NUMBER
              // * COMPILATION
              // * DATE_EXPIRES
              // * DATE_TAKEN
              // * DISC_NUMBER
              // * DISPLAY_NAME - this is same as TITLE, but with file extension at the end
              // * DOCUMENT_ID
              // * HEIGHT
              // * WIDTH
              // * INSTANCE_ID
              //
              // * IS_ALARM
              // * IS_AUDIOBOOK
              // * IS_MUSIC - we fetch only music, see `selection` above
              // * IS_NOTIFICATION
              // * IS_PODCAST
              // * IS_RECORDING
              // * IS_RINGTONE
              //
              // * IS_DOWNLOAD
              // * IS_DRM
              //
              // * IS_TRASHED - trashed items are excluded, see `selection` above
              // * IS_PENDING - pedning items are excluded, see `selection` above
              //
              // * MIME_TYPE
              // * NUM_TRACKS - the number of songs in the origin this media comes from
              // * ORIENTATION
              // * ORIGINAL_DOCUMENT_ID
              // * OWNER_PACKAGE_NAME
              // * RELATIVE_PATH
              // * RESOLUTION
              // * VOLUME_NAME
              // * XMP
              // * TITLE_RESOURCE_URI
              //
              // * BOOKMARK - position within the audio item at which
              // playback should be resumed. For me it's making no sense to remember position for each
              // media item.
      ));

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
         projection.add(MediaStore.Audio.Media.IS_FAVORITE);
         projection.add(MediaStore.Audio.Media.GENERATION_ADDED);
         projection.add(MediaStore.Audio.Media.GENERATION_MODIFIED);
         projection.add(MediaStore.Audio.Media.GENRE);
         projection.add(MediaStore.Audio.Media.GENRE_ID);
      }

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              projection.toArray(new String[0]),
              songsSelection,
              null,
              null
      );

      if (cursor != null) {
         while (cursor.moveToNext()) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("id", cursor.getInt(0));
            map.put("album", cursor.getString(1));
            map.put("albumId", cursor.getInt(2));
            map.put("artist", cursor.getString(3));
            map.put("artistId", cursor.getInt(4));
            map.put("title", cursor.getString(5));
            map.put("track", cursor.getString(6));
            map.put("year", cursor.getString(7));
            map.put("dateAdded", cursor.getInt(8));
            map.put("dateModified", cursor.getInt(9));
            map.put("duration", cursor.getInt(10));
            map.put("size", cursor.getInt(11));
            map.put("data", cursor.getString(12));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
               map.put("isFavoriteInMediaStore", cursor.getInt(13) == 1);
               map.put("generationAdded", cursor.getInt(14));
               map.put("generationModified", cursor.getInt(15));
               map.put("genre", cursor.getString(16));
               map.put("genreId", cursor.getInt(17));
            }
            maps.add(map);
         }
         cursor.close();
      }
      return maps;
   }

   public static ArrayList<HashMap<?, ?>> retrieveAlbums() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();

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
              MediaStore.Audio.Albums.ALBUM + " IS NOT NULL",
              null,
              null
      );

      if (cursor != null) {
         while (cursor.moveToNext()) {
            HashMap<String, Object> map = new HashMap<>();
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
      }
      return maps;
   }

   public static ArrayList<HashMap<?, ?>> retrievePlaylists() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
              new String[]{
                      MediaStore.Audio.Playlists._ID,
                      MediaStore.Audio.Playlists.DATA,
                      MediaStore.Audio.Playlists.DATE_ADDED,
                      MediaStore.Audio.Playlists.DATE_MODIFIED,
                      MediaStore.Audio.Playlists.NAME,
              },
              MediaStore.Audio.Playlists.NAME + " IS NOT NULL",
              null,
              null
      );

      if (cursor != null) {
         String[] memberProjection = new String[]{
                 MediaStore.Audio.Playlists.Members.AUDIO_ID,
         };
         while (cursor.moveToNext()) {
            long id = cursor.getLong(0);
            Cursor membersCursor = resolver.query(
                    MediaStore.Audio.Playlists.Members.getContentUri("external", id),
                    memberProjection,
                    songsSelection,
                    null,
                    MediaStore.Audio.Playlists.Members.DEFAULT_SORT_ORDER
            );
            if (membersCursor != null) {
               ArrayList<Integer> songIds = new ArrayList<>();
               while (membersCursor.moveToNext()) {
                  songIds.add(membersCursor.getInt(0));
               }
               HashMap<String, Object> map = new HashMap<>();
               map.put("id", cursor.getInt(0));
               map.put("data", cursor.getString(1));
               map.put("dateAdded", cursor.getInt(2));
               map.put("dateModified", cursor.getInt(3));
               map.put("name", cursor.getString(4));
               map.put("songIds", songIds);
               maps.add(map);
               membersCursor.close();
            }
         }
         cursor.close();
      }
      return maps;
   }

   public static ArrayList<HashMap<?, ?>> retrieveArtists() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI,
              new String[]{
                      MediaStore.Audio.Artists._ID,
                      MediaStore.Audio.Artists.ARTIST,
                      MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
                      MediaStore.Audio.Artists.NUMBER_OF_TRACKS,
              },
              MediaStore.Audio.Artists.ARTIST + " IS NOT NULL",
              null,
              null
      );

      if (cursor != null) {
         while (cursor.moveToNext()) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("id", cursor.getInt(0));
            map.put("artist", cursor.getString(1));
            map.put("numberOfAlbums", cursor.getInt(2));
            map.put("numberOfTracks", cursor.getInt(3));
            maps.add(map);
         }
         cursor.close();
      }
      return maps;
   }

   public static ArrayList<HashMap<?, ?>> retrieveGenres() {
      ArrayList<HashMap<?, ?>> maps = new ArrayList<>();

      ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
      Cursor cursor = resolver.query(
              MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI,
              new String[]{
                      MediaStore.Audio.Genres._ID,
                      MediaStore.Audio.Genres.NAME,
              },
              MediaStore.Audio.Genres.NAME + " IS NOT NULL",
              null,
              null
      );

      if (cursor != null) {
         String[] memberProjection = new String[]{
                 MediaStore.Audio.Genres.Members._ID,
         };
         while (cursor.moveToNext()) {
            int id = cursor.getInt(0);
            Cursor membersCursor = resolver.query(
                    MediaStore.Audio.Genres.Members.getContentUri("external", id),
                    memberProjection,
                    null,
                    null,
                    null
            );
            if (membersCursor != null) {
               ArrayList<Integer> songIds = new ArrayList<>();
               while (membersCursor.moveToNext()) {
                  songIds.add(membersCursor.getInt(0));
               }
               HashMap<String, Object> map = new HashMap<>();
               map.put("id", cursor.getInt(0));
               map.put("name", cursor.getString(1));
               map.put("songIds", songIds);
               maps.add(map);
               membersCursor.close();
            }
         }
         cursor.close();
      }
      return maps;
   }
}
