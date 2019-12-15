/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.os.AsyncTask;
import android.provider.MediaStore;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.SongChannel;
import com.nt4f04uNd.player.player.Song;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import io.flutter.Log;

public class FetchHandler {
    public static class TaskSearchSongs extends AsyncTask<Void, Void, List<String>> {
        @Override
        protected void onPreExecute() {
      Log.w(Constants.LogTag, "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWDDDD");
        }

        @Override
        protected List<String> doInBackground(Void... params) {
            return retrieveSongs();
        }

        @Override
        protected void onPostExecute(List<String> result) {
            SongChannel.channel.invokeMethod(Constants.channels.SONGS_METHOD_SEND_SONGS, result);
        }
    }

    private static final String[] defaultProjection = {
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_MODIFIED
    };

    /**
     * Retrieve a list of music files currently listed in the Media store DB via URI
     */
    public static List<String> retrieveSongs() {
        List<String> songs = new ArrayList<>();
        // Some audio may be explicitly marked as not being music
        String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";

        Cursor cursor = GeneralHandler.getAppContext().getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                defaultProjection, selection, null, "DATE_MODIFIED DESC");

        if (cursor == null) {
            return songs;
        }

        while (cursor.moveToNext()) {
            songs.add(
                    Song.jsonString(
                            cursor.getInt(0),
                            cursor.getString(1),
                            cursor.getString(2),
                            getAlbumArt(GeneralHandler.getAppContext().getContentResolver(),
                                    cursor.getInt(3)),
                            cursor.getString(4),
                            cursor.getString(5),
                            cursor.getInt(6),
                            cursor.getInt(7)
                    )
            );
        }
        cursor.close();
        return songs;
    }

    /**
     * Fetches album art by id
     */
    public static String getAlbumArt(ContentResolver contentResolver, int albumId) {
        Cursor cursor = contentResolver.query(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                new String[]{MediaStore.Audio.Albums._ID, MediaStore.Audio.Albums.ALBUM_ART},
                MediaStore.Audio.Albums._ID + "=?", new String[]{String.valueOf(albumId)}, null);

        String path = null;
        if (cursor.moveToFirst())
            path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART));
        cursor.close();
        return path;
    }
}
