package com.nt4f04uNd.player.songs;

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

    Song(final int id, final String artist, final String album, final String albumArtUri, final String title,
         final String trackUri, final int duration, final int dateModified) {
        this.id = id;
        this.artist = artist;
        this.album = album;
        this.albumArtUri = albumArtUri;
        this.title = title;
        this.trackUri = trackUri;
        this.duration = duration;
        this.dateModified = dateModified;
    }

    /**
     * Wraps string with commas
     */
    private static String wrapWithCommas(String value) {
        if (value != null)
            return "" + '"' + value + '"';
        return "";
    }

    String toJson() {
        return String.format(
                "{\"id\":%d,\"artist\": %s,\"album\": %s,\"albumArtUri\": %s,\"title\": %s,\"trackUri\": %s,\"duration\": %d, \"dateModified\": %d}",
                this.id, wrapWithCommas(this.artist), wrapWithCommas(this.album), wrapWithCommas(this.albumArtUri),
                wrapWithCommas(this.title), wrapWithCommas(this.trackUri), this.duration, this.dateModified);
    }
}