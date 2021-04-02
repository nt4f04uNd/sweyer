/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.player;

public class Song {
    public int id;
    public final String album;
    public final int albumId;
    public final String artist;
    public final int artistId;
    public final String title;
    public final String track;
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
            final String track,
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
        this.track = track;
        this.dateAdded = dateAdded;
        this.dateModified = dateModified;
        this.duration = duration;
        this.size = size;
        this.data = data;
    }

    public Song(Song other) {
        this.id = other.id;
        this.album = other.album;
        this.albumId = other.albumId;
        this.artist = other.artist;
        this.artistId = other.artistId;
        this.title = other.title;
        this.track = other.track;
        this.dateAdded = other.dateAdded;
        this.dateModified = other.dateModified;
        this.duration = other.duration;
        this.size = other.size;
        this.data = other.data;
    }
}