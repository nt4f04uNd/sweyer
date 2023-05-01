package com.nt4f04und.sweyer.sweyer_plugin.services

import android.app.Service
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import com.nt4f04und.sweyer.sweyer_plugin.Constants
import com.nt4f04und.sweyer.sweyer_plugin.SweyerPlugin
import com.nt4f04und.sweyer.sweyer_plugin.handlers.FetchHandler
import java.io.File
import java.io.Serializable
import java.util.concurrent.Executors

class DeletionService : Service() {
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val executor = Executors.newSingleThreadExecutor()
        val handler = Handler(Looper.getMainLooper())
        executor.submit {
            @Suppress("UNCHECKED_CAST") val songs = intent.getSerializableExtra(SONGS_ARGUMENT) as Array<DeletionItem>
            val resolver = contentResolver

            // I'm setting `android:requestLegacyExternalStorage="true"`, because there's no consistent way
            // to delete a bulk of music files in scoped storage in Android Q, or at least I didn't find it
            //
            // See https://stackoverflow.com/questions/58283850/scoped-storage-how-to-delete-multiple-audio-files-via-mediastore
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val uris = ArrayList<Uri>()
                // Populate `songListSuccessful` with uris for the intent
                for (song in songs) {
                    uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, song.id))
                }
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                handler.post {
                    // On R it's required to request an OS permission for file deletions
                    SweyerPlugin.instance!!.startIntentSenderForResult(
                        pendingIntent, Constants.Intents.PERMANENT_DELETION_REQUEST
                    )
                }
            } else {
                val songListSuccessful = ArrayList<String>()
                // Delete files and populate `songListSuccessful` with successful uris
                for (song in songs) {
                    val path = song.path
                    if (path == null) {
                        Log.e(Constants.LogTag, "File without path not deleted")
                        continue
                    }
                    val file = File(path)
                    if (file.exists()) {
                        // Delete the actual file
                        if (file.delete()) {
                            songListSuccessful.add(path)
                        } else {
                            Log.e(Constants.LogTag, "File not deleted: $path")
                        }
                    }
                }
                val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                val where = FetchHandler.buildWhereForCount(MediaStore.Audio.Media.DATA, songs.size)
                val selectionArgs = songListSuccessful.toTypedArray()
                // Delete file from `MediaStore`
                resolver.delete(uri, where, selectionArgs)
                resolver.notifyChange(uri, null)
                SweyerPlugin.instance!!.sendResultFromIntent(true)
            }
            stopSelf()
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    /**
     * An item that is to be deleted.
     * @property id The id of the item.
     * @property path The absolute path to this item on the file system, if available.
     */
    data class DeletionItem(val id: Long, val path: String?) : Serializable

    companion object {
        /** The name of the argument where an array of DeletionItems is expected to be passed.  */
        private const val SONGS_ARGUMENT = "songs"

        /**
         * Start this service with a list of songs to delete.
         *
         * @param context The context that is used to start the service.
         * @param songs The list of songs to delete.
         */
        fun start(context: Context, songs: Array<DeletionItem>) {
            val serviceIntent = Intent(context, DeletionService::class.java)
            serviceIntent.putExtra(SONGS_ARGUMENT, songs)
            context.startService(serviceIntent)
        }
    }
}
