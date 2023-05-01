package com.nt4f04und.sweyer.sweyer_plugin.handlers

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
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

    fun retrieveSongs(resolver: ContentResolver): ArrayList<MutableMap<String, Any?>> {
        return executeQuery(resolver, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songsSelection, buildMap {
            put(MediaStore.Audio.Media._ID, "id" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.ALBUM, "album" to { cursor, index -> cursor.getString(index) })
            put(MediaStore.Audio.Media.ALBUM_ID, "albumId" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.ARTIST, "artist" to { cursor, index -> cursor.getString(index) })
            put(MediaStore.Audio.Media.ARTIST_ID, "artistId" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.TITLE, "title" to { cursor, index -> cursor.getString(index) })
            put(MediaStore.Audio.Media.TRACK,
                "track" to { cursor, index -> cursor.getString(index) }) // position in album
            put(MediaStore.Audio.Media.YEAR, "year" to { cursor, index -> cursor.getString(index) })
            put(MediaStore.Audio.Media.DATE_ADDED, "dateAdded" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.DATE_MODIFIED, "dateModified" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.DURATION, "duration" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.SIZE, "size" to { cursor, index -> cursor.getInt(index) })
            put(MediaStore.Audio.Media.DATA, "filesystemPath" to { cursor, index -> cursor.getString(index) })
            // Found useless/redundant:
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                put(MediaStore.Audio.Media.IS_FAVORITE,
                    "isFavoriteInMediaStore" to { cursor, index -> cursor.getInt(index) == 1 })
                put(MediaStore.Audio.Media.GENERATION_ADDED,
                    "generationAdded" to { cursor, index -> cursor.getInt(index) })
                put(MediaStore.Audio.Media.GENERATION_MODIFIED,
                    "generationModified" to { cursor, index -> cursor.getInt(index) })
                put(MediaStore.Audio.Media.GENRE, "genre" to { cursor, index -> cursor.getString(index) })
                put(MediaStore.Audio.Media.GENRE_ID, "genreId" to { cursor, index -> cursor.getInt(index) })
            }
        })
    }

    fun retrieveAlbums(resolver: ContentResolver): ArrayList<MutableMap<String, Any?>> {
        return executeQuery(resolver,
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Albums.ALBUM + " IS NOT NULL",
            buildMap {
                put(MediaStore.Audio.Albums._ID, "id" to { cursor, index -> cursor.getInt(index) })
                put(MediaStore.Audio.Albums.ALBUM, "album" to { cursor, index -> cursor.getString(index) })
                put(MediaStore.Audio.Albums.ALBUM_ART, "albumArt" to { cursor, index -> cursor.getString(index) })
                put(MediaStore.Audio.Albums.ARTIST, "artist" to { cursor, index -> cursor.getString(index) })
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Audio.Albums.ARTIST_ID, "artistId" to { cursor, index -> cursor.getInt(index) })
                }
                put(MediaStore.Audio.Albums.FIRST_YEAR, "firstYear" to { cursor, index -> cursor.getInt(index) })
                put(MediaStore.Audio.Albums.LAST_YEAR, "lastYear" to { cursor, index -> cursor.getInt(index) })
                put(MediaStore.Audio.Albums.NUMBER_OF_SONGS,
                    "numberOfSongs" to { cursor, index -> cursor.getInt(index) })
            })
    }

    fun retrievePlaylists(resolver: ContentResolver): ArrayList<MutableMap<String, Any?>> {
        val memberProjection = arrayOf(MediaStore.Audio.Playlists.Members._ID)
        return executeQuery(
            resolver,
            MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Playlists.NAME + " IS NOT NULL",
            mapOf(
                MediaStore.Audio.Playlists._ID to Pair("id") { cursor, index -> cursor.getLong(index) },
                MediaStore.Audio.Playlists.DATA to Pair("filesystemPath") { cursor, index -> cursor.getString(index) },
                MediaStore.Audio.Playlists.DATE_ADDED to Pair("dateAdded") { cursor, index -> cursor.getInt(index) },
                MediaStore.Audio.Playlists.DATE_MODIFIED to Pair("dateModified") { cursor, index ->
                    cursor.getInt(index)
                },
                MediaStore.Audio.Playlists.NAME to Pair("name") { cursor, index -> cursor.getString(index) },
            )
        ).onEach { playlistInfo ->
            val id = playlistInfo["id"] as Long
            resolver.query(
                MediaStore.Audio.Playlists.Members.getContentUri("external", id),
                memberProjection,
                songsSelection,
                null,
                MediaStore.Audio.Playlists.Members.DEFAULT_SORT_ORDER
            )?.use { membersCursor ->
                val songIds = ArrayList<Int>()
                while (membersCursor.moveToNext()) {
                    songIds.add(membersCursor.getInt(0))
                }
                playlistInfo["songIds"] = songIds
            }
        }
    }

    fun retrieveArtists(resolver: ContentResolver): ArrayList<MutableMap<String, Any?>> {
        return executeQuery(
            resolver,
            MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Artists.ARTIST + " IS NOT NULL",
            mapOf(
                MediaStore.Audio.Artists._ID to Pair("id") { cursor, index -> cursor.getInt(index) },
                MediaStore.Audio.Artists.ARTIST to Pair("artist") { cursor, index -> cursor.getString(index) },
                MediaStore.Audio.Artists.NUMBER_OF_ALBUMS to Pair("numberOfAlbums") { cursor, index ->
                    cursor.getInt(index)
                },
                MediaStore.Audio.Artists.NUMBER_OF_TRACKS to Pair("numberOfTracks") { cursor, index ->
                    cursor.getInt(index)
                },
            )
        )
    }

    fun retrieveGenres(resolver: ContentResolver): ArrayList<MutableMap<String, Any?>> {
        val memberProjection = arrayOf(MediaStore.Audio.Genres.Members._ID)
        return executeQuery(
            resolver,
            MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Genres.NAME + " IS NOT NULL",
            mapOf(
                MediaStore.Audio.Genres._ID to Pair("id") { cursor, index -> cursor.getInt(index) },
                MediaStore.Audio.Genres.NAME to Pair("name") { cursor, index -> cursor.getString(index) },
            )
        ).onEach { genreInfo ->
            val id = genreInfo["id"] as Int
            resolver.query(
                MediaStore.Audio.Genres.Members.getContentUri("external", id.toLong()),
                memberProjection,
                null,
                null,
                null
            )?.use { membersCursor ->
                val songIds = ArrayList<Int>()
                while (membersCursor.moveToNext()) {
                    songIds.add(membersCursor.getInt(0))
                }
                genreInfo["songIds"] = songIds
            }
        }
    }

    /**
     * Execute the [query] against the [uri] in [resolver].
     * The [fields] map describes each field in the resulting map:
     * The key is the name of the field in the queried database,
     * the value is the key in the new map and a function to extract the value from the cursor by its index.
     */
    private fun executeQuery(
        resolver: ContentResolver, uri: Uri, query: String, fields: Map<String, Pair<String, (Cursor, Int) -> Any?>>
    ): ArrayList<MutableMap<String, Any?>> {
        val maps = ArrayList<MutableMap<String, Any?>>()
        resolver.query(uri, fields.keys.toTypedArray(), query, null, null)?.use { cursor ->
            val columns = fields.keys.map { cursor.getColumnIndexOrThrow(it) }
            while (cursor.moveToNext()) {
                val itemInfo = mutableMapOf<String, Any?>()
                fields.values.zip(columns).associateTo(itemInfo) { (fieldInfo, index) ->
                    val (name, accessor) = fieldInfo
                    name to if (cursor.isNull(index)) null else accessor(cursor, index)
                }
                maps.add(itemInfo)
            }
        }
        return maps
    }
}
