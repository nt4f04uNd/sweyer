package com.nt4f04uNd.player.songs;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Class representing a song
 */
public class Song {
    private final int id;
    private final String artist;
    private final String album;
    private final String albumArtUri;
    private final String title;
    private final String trackUri;
    private final int duration;
    private final int dateModified;

    public Song(
            final int id,
            final String artist,
            final String album,
            final String albumArtUri,
            final String title,
            final String trackUri,
            final int duration,
            final int dateModified
    ) {
        this.id = id;
        this.artist = artist;
        this.album = album;
        this.albumArtUri = albumArtUri;
        this.title = title;
        this.trackUri = trackUri;
        this.duration = duration;
        this.dateModified = dateModified;
    }

    public String toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("id", this.id);
            json.put("artist", this.artist);
            json.put("album", this.album);
            json.put("albumArtUri", this.albumArtUri);
            json.put("title", this.title);
            json.put("trackUri", this.trackUri);
            json.put("duration", this.duration);
            json.put("dateModified", this.dateModified);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }

    public static String jsonString(
            final int id,
            final String artist,
            final String album,
            final String albumArtUri,
            final String title,
            final String trackUri,
            final int duration,
            final int dateModified
    ) {
        JSONObject json = new JSONObject();
        try {
            json.put("id", id);
            json.put("artist", artist);
            json.put("album", album);
            json.put("albumArtUri", albumArtUri);
            json.put("title", title);
            json.put("trackUri", trackUri);
            json.put("duration", duration);
            json.put("dateModified", dateModified);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }
}