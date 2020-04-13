/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.player.Album;
import com.nt4f04uNd.sweyer.player.Song;
import com.nt4f04uNd.sweyer.handlers.PrefsHandler;

import org.json.JSONObject;

import java.io.File;
import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel;

public class FetchHandler {

    public static class TaskSearchSongs extends AsyncTask<Void, Void, List<String>> {
        final MethodChannel.Result channelResult;

        public TaskSearchSongs(MethodChannel.Result result) {
            this.channelResult = result;
        }

        @Override
        protected List<String> doInBackground(Void... params) {
            return retrieveSongs();
        }

        @Override
        protected void onPostExecute(List<String> result) {
            channelResult.success(result);
        }
    }

    public static class TaskSearchAlbums extends AsyncTask<Void, Void, List<String>> {
        final MethodChannel.Result channelResult;

        public TaskSearchAlbums(MethodChannel.Result result) {
            this.channelResult = result;
        }

        @Override
        protected List<String> doInBackground(Void... params) {
            return retrieveAlbums();
        }

        @Override
        protected void onPostExecute(List<String> result) {
            channelResult.success(result);
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
            MediaStore.Audio.Media.TITLE,
            // TODO: TRACK ?????
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


    public static Uri getSongUri(int songId) {
        return ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId);
    }

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

    public static void deleteSongs(ArrayList<String> songDataList) {
        // I'm setting `android:requestLegacyExternalStorage="true"`, because there's no consistent way
        // to delete a bulk of music files in scoped storage in Android Q, or I didn't find it
        //
        // See https://stackoverflow.com/questions/58283850/scoped-storage-how-to-delete-multiple-audio-files-via-mediastore
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {

            ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();

            ArrayList<String> songDataListSuccessful = new ArrayList<>();

            for (String data : songDataList) {

                File file = new File(data);

                if (file.exists()) {
                    // Delete the actual file
                    if (file.delete()) {
                        songDataListSuccessful.add(data);
                    } else {
                        System.out.println("file not Deleted :" + data);
                    }
                }
            }


            Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
            String where = buildWhereClauseForDeletion(songDataList.size());
            String[] selectionArgs = songDataListSuccessful.toArray(new String[0]);
            // Delete file from `MediaStore`
            resolver.delete(uri, where, selectionArgs);

        }
    }

    /**
     * Retrieve a list of music files currently listed in the Media store DB via URI.
     */
    public static ArrayList<String> retrieveSongs() {
        ArrayList<String> songs = new ArrayList<>();
        // Some audio may be explicitly marked as not being music
        String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
        String sortOrder = "DATE_MODIFIED DESC";

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

        while (cursor.moveToNext()) {
            songs.add(
                    Song.jsonString(
                            cursor.getInt(0),
                            cursor.getString(1),
                            cursor.getInt(2),
                            cursor.getString(3),
                            cursor.getInt(4),
                            cursor.getString(5),
                            cursor.getInt(6),
                            cursor.getInt(7),
                            cursor.getInt(8),
                            cursor.getInt(9),
                            cursor.getString(10)
                            // getAlbumArt(GeneralHandler.getAppContext().getContentResolver(), cursor.getInt(2))
                    )
            );
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
        String sortOrder =  PrefsHandler.getSortFeature() == 0 ? "DATE_MODIFIED DESC" : "TITLE COLLATE NOCASE ASC";

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
        String sortOrder = "_ID ASC";

        ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
        Cursor cursor = resolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                albumProjection,
                null,
                null,
                sortOrder
        );


        if (cursor == null) {
            return albums;
        }

        while (cursor.moveToNext()) {
            String alb = Album.jsonString(
                    cursor.getInt(0),
                    cursor.getString(1),
                    cursor.getString(2),
                    cursor.getString(3),
                    cursor.getInt(4),
                    cursor.getInt(5),
                    cursor.getInt(6),
                    cursor.getInt(7)
            );

            albums.add(
                    alb
            );
        }
        cursor.close();
        return albums;
    }

    /**
     * Fetches album art by id
     */
//    @Nullable
//    public static String getAlbumArt(ContentResolver contentResolver, int albumId) {
//        Cursor cursor = contentResolver.query(
//                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
//                new String[]{
//                        MediaStore.Audio.Albums._ID,
//                        MediaStore.Audio.Albums.ALBUM_ART
//                },
//                MediaStore.Audio.Albums._ID + "=?",
//                new String[]{String.valueOf(albumId)},
//                null
//        );
//
//        String path = null;
//        if (cursor != null) {
//            if (cursor.moveToFirst())
//                path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART));
//            cursor.close();
//        }
//        return path;

//
//        Bitmap bm = null;
//        try {
//            final Uri artworkBaseUri = Uri
//                    .parse("content://media/external/audio/albumart");
//
//            Uri uri = ContentUris.withAppendedId(artworkBaseUri , albumId);
//
//            ParcelFileDescriptor pfd = context.getContentResolver()
//                    .openFileDescriptor(uri, "r");
//
//            if (pfd != null) {
//                FileDescriptor fd = pfd.getFileDescriptor();
//                bm = BitmapFactory.decodeFileDescriptor(fd);
//            }
//        } catch (Exception e) {
//        }
//        return bm;

//    }
}
