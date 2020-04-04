/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.R;
import com.nt4f04uNd.sweyer.player.Song;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.view.FlutterMain;


/**
 * Contains all data and methods needed to play songs on service side
 * Like temporary container for last playlist, when activity is destroyed, for service to continue functioning as normal
 */
public class PlaylistHandler {

    private static ArrayList<Song> songs;
    /**
     * Normally, it will come on activity start from dart code
     * But in service a have added additional check for cases when android restarts it (cause service is sticky)
     */
    private static Song currentSong;
    private static byte[] currentSongArtBitmapBytes;


    public static byte[] getArtPlaceholder() {
        AssetManager assetManager = GeneralHandler.getAppContext().getAssets();
        String key = 
          GeneralHandler.isSystemThemeDark()
                ? FlutterMain.getLookupKeyForAsset("assets/images/placeholder_thumb_new_dark.png")
                : FlutterMain.getLookupKeyForAsset("assets/images/placeholder_thumb_new.png");
      //   GeneralHandler.isSystemThemeDark()
      //           ? FlutterMain.getLookupKeyForAsset("assets/images/placeholder_thumb_old.png")
      //           : FlutterMain.getLookupKeyForAsset("assets/images/placeholder_thumb.png");

        try {
            InputStream istream = assetManager.open(key);
            Bitmap bitmap = BitmapFactory.decodeStream(istream);
            ByteArrayOutputStream ostream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, ostream);
            return ostream.toByteArray();
        } catch (IOException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            return new byte[0];
        }
    }

    /**
     * This method gets last played playlist when activity is destroyed
     */
    public static void getLastPlaylist() {
        if (songs == null) { // Songs will be rested to null every time app activity starts
            songs = SerializationHandler.getPlaylistSongs();
//
//           // Song song =  songs.get(7);
//            GeneralHandler.print("wfwfwfwfwfwfwfwfwfwfwfwfwfwfwfwfwfwfwf, ID"
//                    + song.id + "  TITLE  "
//                    + song.title + " ALBUM  "
//                    + song.album + "  ALB_ID "
//                    + song.albumId + "  ALB_KEY  "
//                    + song.albumKey + "  ALB_URI  "
//                    + song.albumArtUri
//            );
        }
    }

    /**
     * Handle case when playingSong is null
     * This can be considered as case when activity did not start (or didn't call send song method for some reason, e.g. songs list is empty)
     */
    public static void initCurrentSong() {
        if (PlaylistHandler.getCurrentSong() == null) {
            PlaylistHandler.getLastPlaylist();
            PlaylistHandler.setCurrentSong(PlaylistHandler.searchById((int) PrefsHandler.getSongId()));
        }
    }

    public static void resetPlaylist() {
        songs = null;
    }


    public static Song getCurrentSong() {
        return currentSong;
    }

    public static void setCurrentSong(Song newSong) {
        currentSong = newSong;
        if (newSong != null) {
            boolean success = false;
            // Album art fetch
            if (newSong.albumArtUri != null) {
                File imgFile = new File(newSong.albumArtUri);
                if (imgFile.exists()) {
                    Bitmap bitmap = BitmapFactory.decodeFile(imgFile.getAbsolutePath());
                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                    currentSongArtBitmapBytes = stream.toByteArray();
                    success = true;
                }
            }
            if (!success) {
                currentSongArtBitmapBytes = null;
            }
        }
    }

    /**
     * Returns current song art
     */
    @Nullable
    public static byte[] getArt() {
        return currentSongArtBitmapBytes;
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
