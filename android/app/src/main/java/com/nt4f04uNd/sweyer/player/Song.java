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
    public final int albumKey;
    public final String artist;
    public final int artistId;
    public final int artistKey;
    public final String title;
    public final int titleKey;
    public final int dateAdded;
    public final int dateModified;
    public final int duration;
    public final int size;
    public final String data;
    @Nullable
    public final String albumArtUri;

    public Song(
            final int id,
            final String album,
            final int albumId,
            final int albumKey,
            final String artist,
            final int artistId,
            final int artistKey,
            final String title,
            final int titleKey,
            final int dateAdded,
            final int dateModified,
            final int duration,
            final int size,
            final String data,
            @Nullable final String albumArtUri
    ) {
        this.id = id;
        this.album = album;
        this.albumId = albumId;
        this.albumKey = albumKey;
        this.artist = artist;
        this.artistId = artistId;
        this.artistKey = artistKey;
        this.title = title;
        this.titleKey = titleKey;
        this.dateAdded = dateAdded;
        this.dateModified = dateModified;
        this.duration = duration;
        this.size = size;
        this.data = data;
        this.albumArtUri = albumArtUri;
    }

    public String toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("id", this.id);
            json.put("album", this.album);
            json.put("albumId", this.albumId);
            json.put("albumKey", this.albumKey);
            json.put("artist", this.artist);
            json.put("artistId", this.artistId);
            json.put("artistKey", this.artistKey);
            json.put("title", this.title);
            json.put("titleKey", this.titleKey);
            json.put("dateAdded", this.dateAdded);
            json.put("dateModified", this.dateModified);
            json.put("duration", this.duration);
            json.put("size", this.size);
            json.put("data", this.data);
            json.put("albumArtUri", this.albumArtUri);

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
                    json.getInt("albumKey"),
                    json.getString("artist"),
                    json.getInt("artistId"),
                    json.getInt("artistKey"),
                    json.getString("title"),
                    json.getInt("titleKey"),
                    json.getInt("dateAdded"),
                    json.getInt("dateModified"),
                    json.getInt("duration"),
                    json.getInt("size"),
                    json.getString("data"),
                    json.getString("albumArtUri")
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
            final int albumKey,
            final String artist,
            final int artistId,
            final int artistKey,
            final String title,
            final int titleKey,
            final int dateAdded,
            final int dateModified,
            final int duration,
            final int size,
            final String data,
            @Nullable final String albumArtUri
    ) {
        JSONObject json = new JSONObject();
        try {
            json.put("id", id);
            json.put("album", album);
            json.put("albumId", albumId);
            json.put("albumKey", albumKey);
            json.put("artist", artist);
            json.put("artistId", artistId);
            json.put("artistKey", artistKey);
            json.put("title", title);
            json.put("titleKey", titleKey);
            json.put("dateAdded", dateAdded);
            json.put("dateModified", dateModified);
            json.put("duration", duration);
            json.put("size", size);
            json.put("data", data);
            json.put("albumArtUri", albumArtUri);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }
}