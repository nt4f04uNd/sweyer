package com.nt4f04und.sweyer.sweyer_plugin.handlers

import android.content.ContentResolver
import android.os.Build
import android.provider.MediaStore

object FetchHandler {
    private var songsSelection = MediaStore.Audio.Media.IS_MUSIC + " != 0"

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Some audio may be explicitly marked as not being music or be trashed (on Android R and above),
            // I'm excluding such.
            songsSelection += " AND " + MediaStore.Audio.Media.IS_TRASHED + " == 0 AND " + MediaStore.Audio.Media.IS_PENDING + " == 0"
        }
    }

    /**
     * Produces the `where` parameter for selection multiple items from the `MediaStore`
     * Creates a string like "_data IN (?, ?, ?, ...)"
     */
    fun buildWhereForCount(column: String, count: Int): String {
        val builder = StringBuilder(column)
        builder.append(" IN (")
        for (i in 0 until count - 1) {
            builder.append("?, ")
        }
        builder.append("?)")
        return builder.toString()
    }

    fun retrieveSongs(resolver: ContentResolver): ArrayList<HashMap<String, *>> {
        val maps = ArrayList<HashMap<String, *>>()
        val projection = ArrayList(
            listOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ARTIST_ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.TRACK,  // position in album
                MediaStore.Audio.Media.YEAR,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.DATE_MODIFIED,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.DATA // Found useless/redundant:
                //
                // * ALBUM_ARTIST - for this one I can simply check the song album
                //
                // * AUTHOR
                // * COMPOSER
                // * WRITER
                //
                // * BITRATE
                // * CAPTURE_FRAMERATE
                // * CD_TRACK_NUMBER
                // * COMPILATION
                // * DATE_EXPIRES
                // * DATE_TAKEN
                // * DISC_NUMBER
                // * DISPLAY_NAME - this is same as TITLE, but with file extension at the end
                // * DOCUMENT_ID
                // * HEIGHT
                // * WIDTH
                // * INSTANCE_ID
                //
                // * IS_ALARM
                // * IS_AUDIOBOOK
                // * IS_MUSIC - we fetch only music, see `selection` above
                // * IS_NOTIFICATION
                // * IS_PODCAST
                // * IS_RECORDING
                // * IS_RINGTONE
                //
                // * IS_DOWNLOAD
                // * IS_DRM
                //
                // * IS_TRASHED - trashed items are excluded, see `selection` above
                // * IS_PENDING - pending items are excluded, see `selection` above
                //
                // * MIME_TYPE
                // * NUM_TRACKS - the number of songs in the origin this media comes from
                // * ORIENTATION
                // * ORIGINAL_DOCUMENT_ID
                // * OWNER_PACKAGE_NAME
                // * RELATIVE_PATH
                // * RESOLUTION
                // * VOLUME_NAME
                // * XMP
                // * TITLE_RESOURCE_URI
                //
                // * BOOKMARK - position within the audio item at which
                // playback should be resumed. For me it's making no sense to remember position for each
                // media item.
            )
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            projection.add(MediaStore.Audio.Media.IS_FAVORITE)
            projection.add(MediaStore.Audio.Media.GENERATION_ADDED)
            projection.add(MediaStore.Audio.Media.GENERATION_MODIFIED)
            projection.add(MediaStore.Audio.Media.GENRE)
            projection.add(MediaStore.Audio.Media.GENRE_ID)
        }
        val cursor = resolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, projection.toTypedArray(), songsSelection, null, null
        )
        cursor?.use {
            while (cursor.moveToNext()) {
                val map = HashMap<String, Any?>()
                map["id"] = cursor.getInt(0)
                map["album"] = if (cursor.isNull(1)) null else cursor.getString(1)
                map["albumId"] = if (cursor.isNull(2)) null else cursor.getInt(2)
                map["artist"] = cursor.getString(3)
                map["artistId"] = cursor.getInt(4)
                map["title"] = cursor.getString(5)
                map["track"] = if (cursor.isNull(6)) null else cursor.getString(6)
                map["year"] = cursor.getString(7)
                map["dateAdded"] = cursor.getInt(8)
                map["dateModified"] = cursor.getInt(9)
                map["duration"] = cursor.getInt(10)
                map["size"] = cursor.getInt(11)
                map["filesystemPath"] = if (cursor.isNull(12)) null else cursor.getString(12)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    map["isFavoriteInMediaStore"] = if (cursor.isNull(13)) null else (cursor.getInt(13) == 1)
                    map["generationAdded"] = if (cursor.isNull(14)) null else cursor.getInt(14)
                    map["generationModified"] = if (cursor.isNull(15)) null else cursor.getInt(15)
                    map["genre"] = if (cursor.isNull(16)) null else cursor.getString(16)
                    map["genreId"] = if (cursor.isNull(17)) null else cursor.getInt(17)
                }
                maps.add(map)
            }
        }
        return maps
    }

    fun retrieveAlbums(resolver: ContentResolver): ArrayList<HashMap<String, *>> {
        val maps = ArrayList<HashMap<String, *>>()
        val cursor = resolver.query(
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI, arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM,
                MediaStore.Audio.Albums.ALBUM_ART,
                MediaStore.Audio.Albums.ARTIST,
                MediaStore.Audio.Albums.ARTIST_ID,
                MediaStore.Audio.Albums.FIRST_YEAR,
                MediaStore.Audio.Albums.LAST_YEAR,
                MediaStore.Audio.Albums.NUMBER_OF_SONGS
            ), MediaStore.Audio.Albums.ALBUM + " IS NOT NULL", null, null
        )
        cursor?.use {
            while (cursor.moveToNext()) {
                val map = HashMap<String, Any?>()
                map["id"] = cursor.getInt(0)
                map["album"] = cursor.getString(1)
                map["albumArt"] = if (cursor.isNull(2)) null else cursor.getString(2)
                map["artist"] = cursor.getString(3)
                map["artistId"] = cursor.getInt(4)
                map["firstYear"] = cursor.getInt(5)
                map["lastYear"] = cursor.getInt(6)
                map["numberOfSongs"] = cursor.getInt(7)
                maps.add(map)
            }
        }
        return maps
    }

    fun retrievePlaylists(resolver: ContentResolver): ArrayList<HashMap<String, *>> {
        val maps = ArrayList<HashMap<String, *>>()
        val cursor = resolver.query(
            MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, arrayOf(
                MediaStore.Audio.Playlists._ID,
                MediaStore.Audio.Playlists.DATA,
                MediaStore.Audio.Playlists.DATE_ADDED,
                MediaStore.Audio.Playlists.DATE_MODIFIED,
                MediaStore.Audio.Playlists.NAME
            ), MediaStore.Audio.Playlists.NAME + " IS NOT NULL", null, null
        )
        cursor?.use {
            val memberProjection = arrayOf(MediaStore.Audio.Playlists.Members.AUDIO_ID)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(0)
                val membersCursor = resolver.query(
                    MediaStore.Audio.Playlists.Members.getContentUri("external", id),
                    memberProjection,
                    songsSelection,
                    null,
                    MediaStore.Audio.Playlists.Members.DEFAULT_SORT_ORDER
                )
                membersCursor?.use {
                    val songIds = ArrayList<Int>()
                    while (membersCursor.moveToNext()) {
                        songIds.add(membersCursor.getInt(0))
                    }
                    val map = HashMap<String, Any>()
                    map["id"] = cursor.getInt(0)
                    map["filesystemPath"] = cursor.getString(1)
                    map["dateAdded"] = cursor.getInt(2)
                    map["dateModified"] = cursor.getInt(3)
                    map["name"] = cursor.getString(4)
                    map["songIds"] = songIds
                    maps.add(map)
                }
            }
        }
        return maps
    }

    fun retrieveArtists(resolver: ContentResolver): ArrayList<HashMap<String, *>> {
        val maps = ArrayList<HashMap<String, *>>()
        val cursor = resolver.query(
            MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI, arrayOf(
                MediaStore.Audio.Artists._ID,
                MediaStore.Audio.Artists.ARTIST,
                MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
                MediaStore.Audio.Artists.NUMBER_OF_TRACKS
            ), MediaStore.Audio.Artists.ARTIST + " IS NOT NULL", null, null
        )
        cursor?.use {
            while (cursor.moveToNext()) {
                val map = HashMap<String, Any>()
                map["id"] = cursor.getInt(0)
                map["artist"] = cursor.getString(1)
                map["numberOfAlbums"] = cursor.getInt(2)
                map["numberOfTracks"] = cursor.getInt(3)
                maps.add(map)
            }
        }
        return maps
    }

    fun retrieveGenres(resolver: ContentResolver): ArrayList<HashMap<String, *>> {
        val maps = ArrayList<HashMap<String, *>>()
        val cursor = resolver.query(
            MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI, arrayOf(
                MediaStore.Audio.Genres._ID, MediaStore.Audio.Genres.NAME
            ), MediaStore.Audio.Genres.NAME + " IS NOT NULL", null, null
        )
        cursor?.use {
            val memberProjection = arrayOf(
                MediaStore.Audio.Genres.Members._ID
            )
            while (cursor.moveToNext()) {
                val id = cursor.getInt(0)
                val membersCursor = resolver.query(
                    MediaStore.Audio.Genres.Members.getContentUri("external", id.toLong()),
                    memberProjection,
                    null,
                    null,
                    null
                )
                membersCursor?.use {
                    val songIds = ArrayList<Int>()
                    while (membersCursor.moveToNext()) {
                        songIds.add(membersCursor.getInt(0))
                    }
                    val map = HashMap<String, Any>()
                    map["id"] = cursor.getInt(0)
                    map["name"] = cursor.getString(1)
                    map["songIds"] = songIds
                    maps.add(map)
                }
            }
        }
        return maps
    }
}
