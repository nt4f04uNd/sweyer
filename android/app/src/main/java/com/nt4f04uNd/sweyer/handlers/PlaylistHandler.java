/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.player.Song;

import java.util.ArrayList;

import androidx.annotation.Nullable;
import io.flutter.Log;


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
    public static Song playingSong;

    public static void resetPlaylist() {
        songs = null;
    }

    /**
     * This method gets last played playlist when activity is destroyed
     */
    public static void getLastPlaylist() {
        if (songs == null) // Songs will be rested to null every time app activity starts
            songs = SerializationHandler.getPlaylistSongs();
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
            if (songs.get(i).id == playingSong.id) return i;
        }
        return null;
    }

    public static Song getNextSong() {
        int new_id = getCurrentSongIndex() + 1 > songs.size() - 1 ? 0 : getCurrentSongIndex() + 1;
        return songs.get(new_id);
    }

    public static Song getPrevSong() {
        int new_id = getCurrentSongIndex() - 1 < 0 ? songs.size() - 1 : getCurrentSongIndex() - 1;
        return songs.get(new_id);
    }

    @Nullable
    public static Song searchById(int id) {
        if (songs.size() <= 0) {
            Log.e(Constants.LogTag, "Error: called `searchById` when songs array has 0 length!");
            return null;
        }
        for (int i = 0; i < songs.size(); i++) {
            Song song = songs.get(i);
            if (song.id == id){
                return song;
            }
        }
        return null;
    }

}
