/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.content.pm.PackageManager;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.player.Song;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.lang.reflect.Array;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

import io.flutter.Log;


/***CURRENTLY OUT OF USE*******************************************************************************************/
public class SerializationHandler {

    public static String getFlutterAppPath() {
        try {
            String directory = GeneralHandler.getAppContext().getPackageManager().getPackageInfo(GeneralHandler.getAppContext().getPackageName(), 0).applicationInfo.dataDir;
            return directory + "/app_flutter/";
        } catch (PackageManager.NameNotFoundException e) {
            Log.w(Constants.LogTag, "Error Package name not found", e);
            return "<error>";
        }
    }


    public static String loadJSON(String uri) {
        String json;
        FileInputStream fileInputStream;
        try {
            File file = new File(uri);
            fileInputStream = new FileInputStream(file);
            int size = fileInputStream.available();
            byte[] buffer = new byte[size];
            fileInputStream.read(buffer);
            fileInputStream.close();
            json = new String(buffer, StandardCharsets.UTF_8);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        return json;
    }

    /**
     * Reads playlist and songs jsons and gets needed songs
     **/
    public static ArrayList<Song> getPlaylistSongs() {
        JSONArray jsonPlaylist;
        ArrayList<Song> fetchedSongs;
        ArrayList<Song> songs = new ArrayList<>();
        try {
            jsonPlaylist = new JSONArray(SerializationHandler.loadJSON(SerializationHandler.getFlutterAppPath() + "playlist.json"));
            fetchedSongs = FetchHandler.retrieveSongsForBackground();

            if (jsonPlaylist.length() == 0) { // If playlist array is empty, then it is global and all playlist will be deserialized
                return fetchedSongs;
            } else {
                for (int i = 0; i < jsonPlaylist.length(); i++) {
                    int songId = jsonPlaylist.getInt(i);
                    for (int j = 0; j < fetchedSongs.size(); j++) {
                        if (songId == fetchedSongs.get(j).id) {
                            songs.add(fetchedSongs.get(j));
                            break;
                        }
                    }
                }
            }
            Log.w(Constants.LogTag, songs.toString());
            return songs;
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }
}
