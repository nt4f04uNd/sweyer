/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

import org.json.JSONException;
import org.json.JSONObject;

import androidx.annotation.Nullable;

/**
 * Class representing a song
 */
public class Song {
    public final int id;
    public final String album;
    public final int albumId;
    public final String artist;
    public final int artistId;
    public final String title;
    public final int dateAdded;
    public final int dateModified;
    public final int duration;
    public final int size;
    public final String data;

    public Song(
            final int id,
            final String album,
            final int albumId,
            final String artist,
            final int artistId,
            final String title,
            final int dateAdded,
            final int dateModified,
            final int duration,
            final int size,
            final String data
    ) {
        this.id = id;
        this.album = album;
        this.albumId = albumId;
        this.artist = artist;
        this.artistId = artistId;
        this.title = title;
        this.dateAdded = dateAdded;
        this.dateModified = dateModified;
        this.duration = duration;
        this.size = size;
        this.data = data;
    }

    public String toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("id", this.id);
            json.put("album", this.album);
            json.put("albumId", this.albumId);
            json.put("artist", this.artist);
            json.put("artistId", this.artistId);
            json.put("title", this.title);
            json.put("dateAdded", this.dateAdded);
            json.put("dateModified", this.dateModified);
            json.put("duration", this.duration);
            json.put("size", this.size);
            json.put("data", this.data);

        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }

    public static Song fromJson(JSONObject json) {
        try {
            return new Song(
                    json.getInt("id"),
                    json.getString("album"),
                    json.getInt("albumId"),
                    json.getString("artist"),
                    json.getInt("artistId"),
                    json.getString("title"),
                    json.getInt("dateAdded"),
                    json.getInt("dateModified"),
                    json.getInt("duration"),
                    json.getInt("size"),
                    json.getString("data")
            );
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static String jsonString(
            final int id,
            final String album,
            final int albumId,
            final String artist,
            final int artistId,
            final String title,
            final int dateAdded,
            final int dateModified,
            final int duration,
            final int size,
            final String data
    ) {
        JSONObject json = new JSONObject();
        try {
            json.put("id", id);
            json.put("album", album);
            json.put("albumId", albumId);
            json.put("artist", artist);
            json.put("artistId", artistId);
            json.put("title", title);
            json.put("dateAdded", dateAdded);
            json.put("dateModified", dateModified);
            json.put("duration", duration);
            json.put("size", size);
            json.put("data", data);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }
}