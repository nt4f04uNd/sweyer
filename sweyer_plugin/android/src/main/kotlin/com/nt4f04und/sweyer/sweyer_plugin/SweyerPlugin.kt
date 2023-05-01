package com.nt4f04und.sweyer.sweyer_plugin

import android.app.Activity
import android.app.PendingIntent
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.IntentSender
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.OperationCanceledException
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import androidx.annotation.UiThread
import com.nt4f04und.sweyer.sweyer_plugin.Constants.Intents
import com.nt4f04und.sweyer.sweyer_plugin.handlers.FetchHandler
import com.nt4f04und.sweyer.sweyer_plugin.services.DeletionService
import com.nt4f04und.sweyer.sweyer_plugin.services.DeletionService.DeletionItem
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.concurrent.Executors

class SweyerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
    private var binding: FlutterPluginBinding? = null

    /// The MethodChannel that provides the communication between Flutter and native Android.
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity.
    private lateinit var channel: MethodChannel
    private var result: MethodChannel.Result? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val loadingSignals = HashMap<String, CancellationSignal>()

    init {
        instance = this
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sweyer_plugin")
        channel.setMethodCallHandler(this)
        binding = flutterPluginBinding
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == Intents.PERMANENT_DELETION_REQUEST.value || requestCode == Intents.FAVORITE_REQUEST.value) {
            sendResultFromIntent(resultCode == Activity.RESULT_OK)
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "loadAlbumArt" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val handler = Handler(Looper.getMainLooper())
                        val contentResolver = contentResolver
                        val signal = CancellationSignal()
                        val id = call.argument<String>("id")!!
                        loadingSignals[id] = signal
                        Executors.newSingleThreadExecutor().execute {
                            var bytes: ByteArray? = null
                            var reported = false
                            try {
                                val bitmap = contentResolver.loadThumbnail(
                                    Uri.parse(call.argument("uri")),
                                    Size(call.argument<Int>("width")!!, call.argument<Int>("height")!!),
                                    signal
                                )
                                ByteArrayOutputStream().use {
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, it)
                                    bytes = it.toByteArray()
                                }
                            } catch (ex: OperationCanceledException) {
                                // do nothing
                            } catch (e: IOException) {
                                reported = true
                                handler.post {
                                    result.error(IO_ERROR, "loadThumbnail failed", Log.getStackTraceString(e))
                                }
                            } finally {
                                if (!reported) {
                                    val finalBytes = bytes
                                    handler.post {
                                        loadingSignals.remove(id)
                                        result.success(finalBytes)
                                    }
                                }
                            }
                        }
                    } else {
                        result.error(SDK_ERROR, "This method requires Android 29 and above", "")
                    }
                }

                "cancelAlbumArtLoading" -> {
                    val id = call.argument<String>("id")!!
                    loadingSignals.remove(id)?.cancel()
                    result.success(null)
                }

                "fixAlbumArt" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id = getLong(call.argument("id"))
                            val songCover = Uri.parse("content://media/external/audio/albumart")
                            val uriSongCover = ContentUris.withAppendedId(songCover, id)
                            try {
                                contentResolver.openInputStream(uriSongCover)?.close()
                            } catch (ex: Exception) {
                                // do nothing
                            }
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "retrieveSongs" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res = FetchHandler.retrieveSongs(contentResolver)
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "retrieveAlbums" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res = FetchHandler.retrieveAlbums(contentResolver)
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "retrievePlaylists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res = FetchHandler.retrievePlaylists(contentResolver)
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "retrieveArtists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res = FetchHandler.retrieveArtists(contentResolver)
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "retrieveGenres" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res = FetchHandler.retrieveGenres(contentResolver)
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "setSongsFavorite" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        this.result = result
                        val value = call.argument<Boolean>("value")!!
                        val songIds = call.argument<ArrayList<ArrayList<Any>>>("songIds")!!
                        val uris = ArrayList<Uri>()
                        for (songId in songIds) {
                            val id = getLong(songId)
                            uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id))
                        }
                        val pendingIntent = MediaStore.createFavoriteRequest(contentResolver, uris, value)
                        startIntentSenderForResult(pendingIntent, Intents.FAVORITE_REQUEST)
                    } else {
                        result.error(SDK_ERROR, "This method requires Android 30 and above", "")
                    }
                }

                "deleteSongs" -> {
                    val songs = call.argument<ArrayList<HashMap<String, Any>>>("songs")!!
                    DeletionService.start(binding!!.applicationContext, songs.map { song ->
                        DeletionItem(getLong(song["id"]), song["filesystemPath"] as String?)
                    }.toTypedArray())
                    // Save the result to report to the flutter code later in `sendResultFromIntent`
                    this.result = result
                }

                "createPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val name = call.argument<String>("name")!!
                            val resolver = contentResolver
                            val values = ContentValues(1)
                            values.put(MediaStore.Audio.Playlists.NAME, name)
                            val uri = resolver.insert(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, values)
                            if (uri != null) {
                                resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null)
                            }
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "renamePlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id = getLong(call.argument("id"))
                            val resolver = contentResolver
                            if (playlistExists(id)) {
                                val name = call.argument<String>("name")!!
                                val values = ContentValues(1)
                                values.put(MediaStore.Audio.Playlists.NAME, name)
                                val rows = resolver.update(
                                    ContentUris.withAppendedId(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, id),
                                    values,
                                    null,
                                    null
                                )
                                if (rows > 0) {
                                    resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null)
                                }
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id)
                                }
                            }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "removePlaylists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val ids = call.argument<ArrayList<Any>>("ids")!!
                            val idsStrings = ArrayList<String>()
                            for (id in ids) {
                                idsStrings.add(id.toString())
                            }
                            val resolver = contentResolver
                            resolver.delete(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                FetchHandler.buildWhereForCount(MediaStore.Audio.Playlists._ID, ids.size),
                                idsStrings.toTypedArray()
                            )
                            resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null)
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "insertSongsInPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id = getLong(call.argument("id"))
                            if (playlistExists(id)) {
                                val index = getLong(call.argument("index"))
                                val songIds = call.argument<ArrayList<Any>>("songIds")!!
                                val resolver = contentResolver
                                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    MediaStore.Audio.Playlists.Members.getContentUri(MediaStore.VOLUME_EXTERNAL, id)
                                } else {
                                    MediaStore.Audio.Playlists.Members.getContentUri("external", id)
                                }
                                val valuesList = ArrayList<ContentValues>()
                                var i = 0
                                while (i < songIds.size) {
                                    val values = ContentValues(2)
                                    values.put(MediaStore.Audio.Playlists.Members.AUDIO_ID, getLong(songIds[i]))
                                    // Play order is one based, so add 1 to the zero based index.
                                    values.put(MediaStore.Audio.Playlists.Members.PLAY_ORDER, i + index + 1)
                                    valuesList.add(values)
                                    i++
                                }
                                resolver.bulkInsert(uri, valuesList.toTypedArray())
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id)
                                }
                            }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "moveSongInPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val resolver = contentResolver
                            val moved = MediaStore.Audio.Playlists.Members.moveItem(
                                resolver, getLong(call.argument("id")), call.argument("from")!!, call.argument("to")!!
                            )
                            if (moved) {
                                resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null)
                            }
                            handler.post { result.success(moved) }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "removeFromPlaylistAt" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id = getLong(call.argument("id"))
                            if (playlistExists(id)) {
                                val indexes = call.argument<ArrayList<Any>>("indexes")!!
                                val stringIndexes = ArrayList<String>()
                                for (index in indexes) {
                                    // Android seems to require indexes to be offset by 1.
                                    //
                                    // It might be because when songs are inserted into the playlist,
                                    // the indexing is quite similar an there it makes sense, because we need
                                    // to be able to insert to `playlistLength + 1` position.
                                    stringIndexes.add((getLong(index) + 1).toString())
                                }
                                val resolver = contentResolver
                                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    MediaStore.Audio.Playlists.Members.getContentUri(MediaStore.VOLUME_EXTERNAL, id)
                                } else {
                                    MediaStore.Audio.Playlists.Members.getContentUri("external", id)
                                }
                                val deletedRows = resolver.delete(
                                    uri, FetchHandler.buildWhereForCount(
                                        MediaStore.Audio.Playlists.Members.PLAY_ORDER, indexes.size
                                    ), stringIndexes.toTypedArray()
                                )
                                if (deletedRows > 0) {
                                    resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null)
                                }
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id)
                                }
                            }
                        } catch (e: Exception) {
                            handler.post { result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e)) }
                        }
                    }
                }

                "isIntentActionView" -> {
                    val activity = activityBinding?.activity
                    if (activity != null) {
                        result.success(Intent.ACTION_VIEW == activity.intent.action)
                    } else {
                        throw IllegalStateException("Not attached to activity")
                    }
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(UNEXPECTED_ERROR, e.message, Log.getStackTraceString(e))
        }
    }

    private fun playlistExists(id: Long): Boolean {
        val cursor = contentResolver.query(
            MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Playlists._ID),
            MediaStore.Audio.Playlists._ID + "=?",
            arrayOf(id.toString()),
            null
        ) ?: return false
        cursor.use {
            return cursor.count != 0
        }
    }

    private val contentResolver: ContentResolver get() = binding!!.applicationContext.contentResolver

    @UiThread
    fun startIntentSenderForResult(pendingIntent: PendingIntent, intent: Intents) {
        try {
            activityBinding!!.activity.startIntentSenderForResult(
                pendingIntent.intentSender, intent.value, null, 0, 0, 0
            )
        } catch (e: IntentSender.SendIntentException) {
            val result = this.result
            if (result != null) {
                result.error(INTENT_SENDER_ERROR, e.message, Log.getStackTraceString(e))
                this.result = null
            }
        } catch (error: Exception) {
            val result = this.result
            if (result != null) {
                result.error(UNEXPECTED_ERROR, error.message, Log.getStackTraceString(error))
                this.result = null
            }
        }
    }

    /**
     * Sends a results after activity receives a result after calling
     * [.startIntentSenderForResult]
     */
    fun sendResultFromIntent(value: Boolean) {
        val result = this.result
        if (result != null) {
            result.success(value)
            this.result = null
        }
    }

    private fun getLong(rawValue: Any?): Long {
        return when (rawValue) {
            is Long -> {
                rawValue
            }

            is Int -> {
                rawValue.toLong()
            }

            else -> {
                throw IllegalArgumentException()
            }
        }
    }

    companion object {
        @JvmField
        var instance: SweyerPlugin? = null

        // Constants for plugin errors.
        private const val UNEXPECTED_ERROR = "UNEXPECTED_ERROR"
        private const val INTENT_SENDER_ERROR = "INTENT_SENDER_ERROR"
        private const val IO_ERROR = "IO_ERROR"
        private const val SDK_ERROR = "SDK_ERROR"
        private const val PLAYLIST_NOT_EXISTS_ERROR = "PLAYLIST_NOT_EXISTS_ERROR"
    }
}
