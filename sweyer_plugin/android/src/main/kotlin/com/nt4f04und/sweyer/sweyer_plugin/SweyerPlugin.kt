package com.nt4f04und.sweyer.sweyer_plugin

import android.app.Activity
import android.app.PendingIntent
import android.content.*
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.*
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import androidx.annotation.UiThread
import com.nt4f04und.sweyer.sweyer_plugin.handlers.FetchHandler
import com.nt4f04und.sweyer.sweyer_plugin.services.DeletionService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.concurrent.Executors


/**
 * Constants for plugin errors.
 */
object SweyerErrorCodes {
    const val UNEXPECTED_ERROR = "UNEXPECTED_ERROR"
    const val INTENT_SENDER_ERROR = "INTENT_SENDER_ERROR"
    const val IO_ERROR = "IO_ERROR"
    const val SDK_ERROR = "SDK_ERROR"
    const val PLAYLIST_NOT_EXISTS_ERROR = "PLAYLIST_NOT_EXISTS_ERROR"
}


/** SweyerPlugin */
class SweyerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    companion object {
        var instance: SweyerPlugin? = null
    }

    init {
        instance = this
    }

    private var binding: FlutterPlugin.FlutterPluginBinding? = null

    /// The MethodChannel that provides the communication between Flutter and native Android.
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity.
    private lateinit var channel: MethodChannel

    private var result: Result? = null

    private var activityBinding: ActivityPluginBinding? = null
    private val loadingSignals: HashMap<String, CancellationSignal> = HashMap()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sweyer_plugin")
        channel.setMethodCallHandler(this)
        binding = flutterPluginBinding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
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
        if (requestCode == Constants.intents.PERMANENT_DELETION_REQUEST.value ||
            requestCode == Constants.intents.FAVORITE_REQUEST.value
        ) {
            sendResultFromIntent(resultCode == Activity.RESULT_OK)
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "loadAlbumArt" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val handler = Handler(Looper.getMainLooper())
                        val contentResolver: ContentResolver = getContentResolver()
                        val signal = CancellationSignal()
                        val id: String = call.argument("id")!!
                        loadingSignals[id] = signal
                        Executors.newSingleThreadExecutor().execute {
                            var bytes: ByteArray? = null
                            var reported = false
                            try {
                                val bitmap: Bitmap = contentResolver.loadThumbnail(
                                    Uri.parse(call.argument("uri")),
                                    Size(
                                        call.argument<Int>("width")!!,
                                        call.argument<Int>("height")!!
                                    ),
                                    signal
                                )
                                val stream = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                                bytes = stream.toByteArray()
                                stream.close()
                            } catch (ex: OperationCanceledException) {
                                // do nothing
                            } catch (e: IOException) {
                                reported = true
                                handler.post {
                                    result.error(
                                        SweyerErrorCodes.IO_ERROR,
                                        "loadThumbnail failed",
                                        Log.getStackTraceString(e)
                                    )
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
                        result.error(
                            SweyerErrorCodes.SDK_ERROR,
                            "This method requires Android 29 and above",
                            ""
                        )
                    }
                }
                "cancelAlbumArtLoading" -> {
                    val id: String = call.argument("id")!!
                    loadingSignals.remove(id)?.cancel()
                    result.success(null)
                }
                "fixAlbumArt" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id: Long = getLong(call.argument("id"))
                            val songCover: Uri =
                                Uri.parse("content://media/external/audio/albumart")
                            val uriSongCover: Uri = ContentUris.withAppendedId(songCover, id)
                            val res: ContentResolver = getContentResolver()
                            try {
                                res.openInputStream(uriSongCover)?.close()
                            } catch (ex: Exception) {
                                // do nothing
                            }
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "retrieveSongs" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res: ArrayList<HashMap<*, *>> = FetchHandler.retrieveSongs(getContentResolver())
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "retrieveAlbums" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res: ArrayList<HashMap<*, *>> = FetchHandler.retrieveAlbums(getContentResolver())
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "retrievePlaylists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res: ArrayList<HashMap<*, *>> = FetchHandler.retrievePlaylists(getContentResolver())
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "retrieveArtists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res: ArrayList<HashMap<*, *>> = FetchHandler.retrieveArtists(getContentResolver())
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "retrieveGenres" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val res: ArrayList<HashMap<*, *>> = FetchHandler.retrieveGenres(getContentResolver())
                            handler.post { result.success(res) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "setSongsFavorite" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        this.result = result
                        val value: Boolean = call.argument("value")!!
                        val songIds: ArrayList<ArrayList<Any>> = call.argument("songIds")!!
                        val uris: ArrayList<Uri> = ArrayList()
                        for (songId in songIds) {
                            val id: Long = getLong(songId)
                            uris.add(
                                ContentUris.withAppendedId(
                                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                    id
                                )
                            )
                        }
                        val pendingIntent: PendingIntent = MediaStore.createFavoriteRequest(
                            getContentResolver(),
                            uris,
                            value
                        )
                        startIntentSenderForResult(
                            pendingIntent,
                            Constants.intents.FAVORITE_REQUEST
                        )
                    } else {
                        result.error(
                            SweyerErrorCodes.SDK_ERROR,
                            "This method requires Android 30 and above",
                            ""
                        )
                    }
                }
                "deleteSongs" -> {
                    val serviceIntent = Intent(binding!!.applicationContext, DeletionService::class.java)
          serviceIntent.putExtra("songs", call.argument<ArrayList<HashMap<*, *>?>>("songs")!!)
                    binding!!.applicationContext.startService(serviceIntent)
                    // Save the result to report to the flutter code later in `sendResultFromIntent`
                    this.result = result
                }
                "createPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val name: String = call.argument("name")!!
                            val resolver: ContentResolver = getContentResolver()
                            val values = ContentValues(1)
                            values.put(MediaStore.Audio.Playlists.NAME, name)
                            val uri: Uri? = resolver.insert(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                values
                            )
                            if (uri != null) {
                                resolver.notifyChange(
                                    MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                    null
                                )
                            }
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "renamePlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id: Long = getLong(call.argument("id"))
                            val resolver: ContentResolver = getContentResolver()
                            if (playlistExists(id)) {
                                val name: String = call.argument("name")!!
                                val values = ContentValues(1)
                                values.put(MediaStore.Audio.Playlists.NAME, name)
                                val rows: Int = resolver.update(
                                    ContentUris.withAppendedId(
                                        MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                        id
                                    ),
                                    values,
                                    null,
                                    null
                                )
                                if (rows > 0) {
                                    resolver.notifyChange(
                                        MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                        null
                                    )
                                }
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(
                                        SweyerErrorCodes.PLAYLIST_NOT_EXISTS_ERROR,
                                        "No playlists with such id",
                                        id
                                    )
                                }
                            }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "removePlaylists" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val ids: ArrayList<Any> = call.argument("ids")!!
                            val idsStrings: ArrayList<String> = ArrayList()
                            for (id in ids) {
                                idsStrings.add(id.toString())
                            }
                            val resolver: ContentResolver = getContentResolver()
                            resolver.delete(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                FetchHandler.buildWhereForCount(
                                    MediaStore.Audio.Playlists._ID,
                                    ids.size
                                ),
                                idsStrings.toArray(arrayOfNulls<String>(0))
                            )
                            resolver.notifyChange(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                null
                            )
                            handler.post { result.success(null) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "insertSongsInPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id: Long = getLong(call.argument("id"))
                            if (playlistExists(id)) {
                                val index: Long = getLong(call.argument("index"))
                                val songIds: ArrayList<Any> = call.argument("songIds")!!
                                val resolver: ContentResolver = getContentResolver()
                                val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    MediaStore.Audio.Playlists.Members.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL,
                                        id
                                    )
                                } else {
                                    MediaStore.Audio.Playlists.Members.getContentUri("external", id)
                                }
                                val valuesList: ArrayList<ContentValues> = ArrayList()
                                var i = 0
                                while (i < songIds.size) {
                                    val values = ContentValues(2)
                                    values.put(
                                        MediaStore.Audio.Playlists.Members.AUDIO_ID,
                                        getLong(songIds[i])
                                    )
                                    values.put(
                                        MediaStore.Audio.Playlists.Members.PLAY_ORDER,
                                        i + index
                                    )
                                    valuesList.add(values)
                                    i++
                                }
                                resolver.bulkInsert(
                                    uri,
                                    valuesList.toArray(arrayOfNulls<ContentValues>(0))
                                )
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(
                                        SweyerErrorCodes.PLAYLIST_NOT_EXISTS_ERROR,
                                        "No playlists with such id",
                                        id
                                    )
                                }
                            }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "moveSongInPlaylist" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val resolver: ContentResolver = getContentResolver()
                            val moved: Boolean = MediaStore.Audio.Playlists.Members.moveItem(
                                resolver,
                                getLong(call.argument("id")),
                                call.argument("from")!!,
                                call.argument("to")!!
                            )
                            if (moved) {
                                resolver.notifyChange(
                                    MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                    null
                                )
                            }
                            handler.post { result.success(moved) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
                        }
                    }
                }
                "removeFromPlaylistAt" -> {
                    val handler = Handler(Looper.getMainLooper())
                    Executors.newSingleThreadExecutor().execute {
                        try {
                            val id: Long = getLong(call.argument("id"))
                            if (playlistExists(id)) {
                                val indexes: ArrayList<Any> = call.argument("indexes")!!
                                val stringIndexes: ArrayList<String> = ArrayList()
                                for (index in indexes) {
                                    // Android seems to require indexes to be offset by 1.
                                    //
                                    // It might be because when songs are inserted into the playlist,
                                    // the indexing is quite similar an there it makes sense, because we need
                                    // to be able to insert to `playlistLength + 1` position.
                                    stringIndexes.add((getLong(index) + 1).toString())
                                }
                                val resolver: ContentResolver = getContentResolver()
                                val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    MediaStore.Audio.Playlists.Members.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL,
                                        id
                                    )
                                } else {
                                    MediaStore.Audio.Playlists.Members.getContentUri("external", id)
                                }
                                val deletedRows: Int = resolver.delete(
                                    uri,
                                    FetchHandler.buildWhereForCount(
                                        MediaStore.Audio.Playlists.Members.PLAY_ORDER,
                                        indexes.size
                                    ),
                                    stringIndexes.toArray(arrayOfNulls<String>(0))
                                )
                                if (deletedRows > 0) {
                                    resolver.notifyChange(
                                        MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                        null
                                    )
                                }
                                handler.post { result.success(null) }
                            } else {
                                handler.post {
                                    result.error(
                                        SweyerErrorCodes.PLAYLIST_NOT_EXISTS_ERROR,
                                        "No playlists with such id",
                                        id
                                    )
                                }
                            }
                        } catch (e: Exception) {
                            handler.post {
                                result.error(
                                    SweyerErrorCodes.UNEXPECTED_ERROR,
                                    e.message,
                                    Log.getStackTraceString(e)
                                )
                            }
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
            result.error(
                SweyerErrorCodes.UNEXPECTED_ERROR,
                e.message,
                Log.getStackTraceString(e)
            )
        }
    }


    private fun playlistExists(id: Long): Boolean {
        val cursor = getContentResolver().query(
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

    private fun getContentResolver(): ContentResolver {
        return binding!!.applicationContext.contentResolver
    }

    @UiThread
    fun startIntentSenderForResult(pendingIntent: PendingIntent, intent: Constants.intents) {
        try {
            activityBinding!!.activity.startIntentSenderForResult(
                pendingIntent.intentSender,
                intent.value,
                null,
                0,
                0,
                0
            )
        } catch (e: IntentSender.SendIntentException) {
            val result = this.result
            if (result != null) {
                result.error(
                    SweyerErrorCodes.INTENT_SENDER_ERROR,
                    e.message,
                    Log.getStackTraceString(e)
                )
                this.result = null
            }
        } catch (error: Exception) {
            val result = this.result
            if (result != null) {
                result.error(
                    SweyerErrorCodes.UNEXPECTED_ERROR,
                    error.message,
                    Log.getStackTraceString(error)
                )
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
}
