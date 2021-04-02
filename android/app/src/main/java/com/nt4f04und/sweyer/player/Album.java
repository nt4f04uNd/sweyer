package com.nt4f04und.sweyer.player;

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
}
