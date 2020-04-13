package com.nt4f04uNd.sweyer.player;

import org.json.JSONException;
import org.json.JSONObject;

public class Album {
   public final int id;
   public final String album;
   public final String albumArt;
   public final String artist;
   public final int artistId;
   public final int firstYear;
   public final int lastYear;
   public final int numberOfSongs;

    public Album(
            final int id,
            final String album,
            final String albumArt,
            final String artist,
            final int artistId,
            final int firstYear,
            final int lastYear,
            final int numberOfSongs
    ) {
        this.id = id;
        this.album = album;
        this.albumArt = albumArt;
        this.artist = artist;
        this.artistId = artistId;
        this.firstYear = firstYear;
        this.lastYear = lastYear;
        this.numberOfSongs = numberOfSongs;
    }

    public String toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("id", this.id);
            json.put("album", this.album);
            json.put("albumArt", this.albumArt);
            json.put("artist", this.artist);
            json.put("artistId", this.artistId);
            json.put("firstYear", this.firstYear);
            json.put("lastYear", this.lastYear);
            json.put("numberOfSongs", this.numberOfSongs);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }


    public static Album fromJson(JSONObject json) {
        try {
            return new Album(
                    json.getInt("id"),
                    json.getString("album"),
                    json.getString("albumArt"),
                    json.getString("artist"),
                    json.getInt("artistId"),
                    json.getInt("firstYear"),
                    json.getInt("lastYear"),
                    json.getInt("numberOfSongs")
            );
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static String jsonString(
            final int id,
            final String album,
            final String albumArt,
            final String artist,
            final int artistId,
            final int firstYear,
            final int lastYear,
            final int numberOfSongs
    ) {
        JSONObject json = new JSONObject();
        try {
            json.put("id", id);
            json.put("album", album);
            json.put("albumArt", albumArt);
            json.put("artist", artist);
            json.put("artistId", artistId);
            json.put("firstYear", firstYear);
            json.put("lastYear", lastYear);
            json.put("numberOfSongs", numberOfSongs);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return json.toString();
    }
}
