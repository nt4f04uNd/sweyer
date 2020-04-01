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
import com.nt4f04uNd.sweyer.player.Song;

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
        final WeakReference<MethodChannel> songChannelRef;

        public TaskSearchSongs(MethodChannel songChannel) {
            this.songChannelRef = new WeakReference<>(songChannel);
        }

        @Override
        protected List<String> doInBackground(Void... params) {
            return retrieveSongs();
        }

        @Override
        protected void onPostExecute(List<String> result) {
            MethodChannel channel = songChannelRef.get();
            if (channel != null)
                channel.invokeMethod(Constants.channels.songs.METHOD_SEND_SONGS, result);
        }
    }

    private static final String[] defaultProjection = {
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.ALBUM_KEY,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ARTIST_ID,
            MediaStore.Audio.Media.ARTIST_KEY,
            // TODO: COMPOSER ?????
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.TITLE_KEY,
            // TODO: TRACK ?????
            // TODO: YEAR ?????
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATA,
    };

// ** OLD
//    MediaStore.Audio.Media._ID,
//    MediaStore.Audio.Media.ARTIST,
//    MediaStore.Audio.Media.ALBUM,
//    MediaStore.Audio.Media.ALBUM_ID,
//    MediaStore.Audio.Media.TITLE,
//    MediaStore.Audio.Media.DATA,
//    MediaStore.Audio.Media.DURATION,
//    MediaStore.Audio.Media.DATE_MODIFIED


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
                        System.out.println("file Deleted :" + data);
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
     * Retrieve a list of music files currently listed in the Media store DB via URI
     */
    public static List<String> retrieveSongs() {
        List<String> songs = new ArrayList<>();
        // Some audio may be explicitly marked as not being music
        String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";
        String sortOrder = "DATE_MODIFIED DESC";

        ContentResolver resolver = GeneralHandler.getAppContext().getContentResolver();
        Cursor cursor = resolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                defaultProjection,
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
                            cursor.getInt(3),
                            cursor.getString(4),
                            cursor.getInt(5),
                            cursor.getInt(6),
                            cursor.getString(7),
                            cursor.getInt(8),
                            cursor.getInt(9),
                            cursor.getInt(10),
                            cursor.getInt(11),
                            cursor.getInt(12),
                            cursor.getString(13),
                            getAlbumArt(GeneralHandler.getAppContext().getContentResolver(), cursor.getInt(2))
                    )
            );
        }
        cursor.close();
        return songs;
    }

    /**
     * Fetches album art by id
     */
    @Nullable
    public static String getAlbumArt(ContentResolver contentResolver, int albumId) {
        Cursor cursor = contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                new String[]{
                        MediaStore.Audio.Albums._ID,
                        MediaStore.Audio.Albums.ALBUM_ART
                },
                MediaStore.Audio.Albums._ID + "=?",
                new String[]{String.valueOf(albumId)},
                null
        );

        String path = null;
        if (cursor != null) {
            if (cursor.moveToFirst())
                path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART));
            cursor.close();
        }
        return path;

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

    }
}
