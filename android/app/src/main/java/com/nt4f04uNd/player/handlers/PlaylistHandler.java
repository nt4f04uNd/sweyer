package com.nt4f04uNd.player.handlers;

import android.content.Intent;

import com.nt4f04uNd.player.player.PlayerForegroundService;
import com.nt4f04uNd.player.player.Song;

import java.util.ArrayList;

import androidx.annotation.Nullable;


/** Contains all data and methods needed to play songs on service side
 *  Like temporary container for last playlist, when activity is destroyed, for service to continue functioning as normal
 */
public class PlaylistHandler {

    public static ArrayList<Song> songs;
    private static int playingSongIdx = 0;

    public static void init() {
        if(songs == null)
        songs = SerializationHandler.getPlaylistSongs();
    }

    /**
     * Will return current song
     * Returns `null` if `songs` array is empty
     */
    @Nullable
    public static Song getCurrentSong() {
        if (songs.size() <= 0) return null;
        return songs.get(playingSongIdx);
    }


    public static Song getNextSong() {
        int new_id = playingSongIdx + 1 > songs.size() - 1 ? 0 : playingSongIdx + 1;
        return songs.get(new_id);
    }

    public static Song getPrevSong() {
        int new_id = playingSongIdx - 1 < 0 ? songs.size() - 1 : playingSongIdx - 1;
        return songs.get(new_id);
    }

}
