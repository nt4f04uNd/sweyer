package com.nt4f04uNd.player.songs;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.provider.MediaStore;

import java.util.ArrayList;
import java.util.List;

public abstract class SongFetcher {

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
     *
     * @param appContext should be from `getApplicationContext()`
     */
    public static List<String> retrieveSongs(Context appContext) {
        List<String> songs = new ArrayList<>();
        // Some audio may be explicitly marked as not being music
        String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";

        Cursor cursor = appContext.getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
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
                            getAlbumArt(appContext.getContentResolver(),
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
