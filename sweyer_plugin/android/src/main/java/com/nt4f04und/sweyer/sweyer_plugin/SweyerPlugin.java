package com.nt4f04und.sweyer.sweyer_plugin;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Intent;
import android.content.IntentSender;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.CancellationSignal;
import android.os.Handler;
import android.os.Looper;
import android.os.OperationCanceledException;
import android.provider.MediaStore;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;

import com.nt4f04und.sweyer.sweyer_plugin.handlers.FetchHandler;
import com.nt4f04und.sweyer.sweyer_plugin.services.DeletionService;

import org.jetbrains.annotations.NotNull;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Objects;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;


public class SweyerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware,
        PluginRegistry.ActivityResultListener {
    public static SweyerPlugin instance;

    @Nullable
    private FlutterPlugin.FlutterPluginBinding binding;

    /// The MethodChannel that provides the communication between Flutter and native Android.
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity.
    @Nullable
    private MethodChannel channel;

    @Nullable
    private MethodChannel.Result result;

    @Nullable
    private ActivityPluginBinding activityBinding;

    private final HashMap<String, CancellationSignal> loadingSignals = new HashMap<>();

    private static final String UNEXPECTED_ERROR = "UNEXPECTED_ERROR";
    private static final String INTENT_SENDER_ERROR = "INTENT_SENDER_ERROR";
    private static final String IO_ERROR = "IO_ERROR";
    private static final String SDK_ERROR = "SDK_ERROR";
    private static final String PLAYLIST_NOT_EXISTS_ERROR = "PLAYLIST_NOT_EXISTS_ERROR";

    public SweyerPlugin() {
        super();
        instance = this;
    }

    @Override
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sweyer_plugin");
        channel.setMethodCallHandler(this);
        binding = flutterPluginBinding;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
        this.binding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activityBinding = binding;
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        if (activityBinding != null) {
            activityBinding.removeActivityResultListener(this);
        }
        activityBinding = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }


    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == Constants.intents.PERMANENT_DELETION_REQUEST.value ||
                requestCode == Constants.intents.FAVORITE_REQUEST.value
        ) {
            sendResultFromIntent(resultCode == Activity.RESULT_OK);
            return true;
        }
        return false;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NotNull MethodChannel.Result result) {
        try {
            switch (call.method) {
            case "loadAlbumArt": {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    Handler handler = new Handler(Looper.getMainLooper());
                    ContentResolver contentResolver = getContentResolver();
                    CancellationSignal signal = new CancellationSignal();
                    String id = call.argument("id");
                    loadingSignals.put(id, signal);
                    Executors.newSingleThreadExecutor().execute(() -> {
                        byte[] bytes = null;
                        boolean reported = false;
                        try {
                            Bitmap bitmap = contentResolver.loadThumbnail(
                                    Uri.parse(call.argument("uri")),
                                    new Size(Objects.requireNonNull(call.argument("width")),
                                             Objects.requireNonNull(call.argument("height"))),
                                    signal);
                            ByteArrayOutputStream stream = new ByteArrayOutputStream();
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                            bytes = stream.toByteArray();
                            stream.close();
                        } catch (OperationCanceledException ex) {
                            // do nothing
                        } catch (IOException e) {
                            reported = true;
                            handler.post(
                                    () -> result.error(IO_ERROR, "loadThumbnail failed", Log.getStackTraceString(e)));
                        } finally {
                            if (!reported) {
                                byte[] finalBytes = bytes;
                                handler.post(() -> {
                                    loadingSignals.remove(id);
                                    result.success(finalBytes);
                                });
                            }
                        }
                    });
                } else {
                    result.error(SDK_ERROR, "This method requires Android 29 and above", "");
                }
                break;
            }
            case "cancelAlbumArtLoading": {
                String id = call.argument("id");
                CancellationSignal signal = loadingSignals.remove(id);
                if (signal != null) {
                    signal.cancel();
                }
                result.success(null);
                break;
            }
            case "fixAlbumArt": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        Long id = getLong(call.argument("id"));
                        Uri songCover = Uri.parse("content://media/external/audio/albumart");
                        Uri uriSongCover = ContentUris.withAppendedId(songCover, id);
                        ContentResolver res = getContentResolver();
                        try {
                            res.openInputStream(uriSongCover).close();
                        } catch (Exception ex) {
                            // do nothing
                        }
                        handler.post(() -> result.success(null));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "retrieveSongs": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<HashMap<String, ?>> res = FetchHandler.retrieveSongs(getContentResolver());
                        handler.post(() -> result.success(res));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "retrieveAlbums": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<HashMap<String, ?>> res = FetchHandler.retrieveAlbums(getContentResolver());
                        handler.post(() -> result.success(res));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "retrievePlaylists": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<HashMap<String, ?>> res = FetchHandler.retrievePlaylists(getContentResolver());
                        handler.post(() -> result.success(res));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "retrieveArtists": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<HashMap<String, ?>> res = FetchHandler.retrieveArtists(getContentResolver());
                        handler.post(() -> result.success(res));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "retrieveGenres": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<HashMap<String, ?>> res = FetchHandler.retrieveGenres(getContentResolver());
                        handler.post(() -> result.success(res));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "setSongsFavorite": {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    this.result = result;
                    Boolean value = Objects.requireNonNull(call.argument("value"));
                    ArrayList<ArrayList<Object>> songIds = Objects.requireNonNull(call.argument("songIds"));
                    ArrayList<Uri> uris = new ArrayList<>();
                    for (Object songId : songIds) {
                        Long id = getLong(songId);
                        uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id));
                    }
                    PendingIntent pendingIntent = MediaStore.createFavoriteRequest(
                            getContentResolver(),
                            uris,
                            value
                    );
                    startIntentSenderForResult(
                            pendingIntent,
                            Constants.intents.FAVORITE_REQUEST
                    );
                } else {
                    result.error(
                            SDK_ERROR,
                            "This method requires Android 30 and above",
                            ""
                    );
                }
                break;
            }
            case "deleteSongs": {
                ArrayList<HashMap<String, Object>> songs = Objects.requireNonNull(call.argument("songs"));
                DeletionService.DeletionItem[] deletionItems = new DeletionService.DeletionItem[songs.size()];
                for (int i = 0; i < songs.size(); i++) {
                    HashMap<String, Object> song = songs.get(i);
                    deletionItems[i] = new DeletionService.DeletionItem(
                            getLong(song.get("id")), (String) song.get("filesystemPath"));
                }
                DeletionService.start(Objects.requireNonNull(binding).getApplicationContext(), deletionItems);
                // Save the result to report to the flutter code later in `sendResultFromIntent`
                this.result = result;
                break;
            }
            case "createPlaylist": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        String name = Objects.requireNonNull(call.argument("name"));
                        ContentResolver resolver = getContentResolver();
                        ContentValues values = new ContentValues(1);
                        values.put(MediaStore.Audio.Playlists.NAME, name);
                        Uri uri = resolver.insert(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, values);
                        if (uri != null) {
                            resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                        }
                        handler.post(() -> result.success(null));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "renamePlaylist": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        Long id = getLong(call.argument("id"));
                        ContentResolver resolver = getContentResolver();
                        if (playlistExists(id)) {
                            String name = Objects.requireNonNull(call.argument("name"));
                            ContentValues values = new ContentValues(1);
                            values.put(MediaStore.Audio.Playlists.NAME, name);
                            int rows = resolver.update(
                                    ContentUris.withAppendedId(
                                            MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                            id
                                    ),
                                    values,
                                    null,
                                    null
                            );
                            if (rows > 0) {
                                resolver.notifyChange(
                                        MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                        null
                                );
                            }
                            handler.post(() -> result.success(null));
                        } else {
                            handler.post(() -> result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id));
                        }
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "removePlaylists": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ArrayList<Object> ids = Objects.requireNonNull(call.argument("ids"));
                        ArrayList<String> idsStrings = new ArrayList<>();
                        for (Object id : ids) {
                            idsStrings.add(id.toString());
                        }
                        ContentResolver resolver = getContentResolver();
                        resolver.delete(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                FetchHandler.buildWhereForCount(
                                        MediaStore.Audio.Playlists._ID,
                                        ids.size()
                                ),
                                idsStrings.toArray(new String[0])
                        );
                        resolver.notifyChange(
                                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                null
                        );
                        handler.post(() -> result.success(null));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "insertSongsInPlaylist": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        Long id = getLong(call.argument("id"));
                        if (playlistExists(id)) {
                            long index = getLong(call.argument("index"));
                            ArrayList<Object> songIds = Objects.requireNonNull(call.argument("songIds"));
                            ContentResolver resolver = getContentResolver();
                            Uri uri;
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                uri = MediaStore.Audio.Playlists.Members.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL,
                                        id
                                );
                            } else {
                                uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                            }
                            ArrayList<ContentValues> valuesList = new ArrayList<>();
                            for (int i = 0; i < songIds.size(); i++) {
                                ContentValues values = new ContentValues(2);
                                values.put(
                                        MediaStore.Audio.Playlists.Members.AUDIO_ID,
                                        getLong(songIds.get(i))
                                );
                                values.put(
                                        MediaStore.Audio.Playlists.Members.PLAY_ORDER,
                                        // Play order is one based, so add 1 to the zero based index.
                                        i + index + 1
                                );
                                valuesList.add(values);
                            }
                            resolver.bulkInsert(
                                    uri,
                                    valuesList.toArray(new ContentValues[0])
                            );
                            handler.post(() -> result.success(null));
                        } else {
                            handler.post(
                                    () -> result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id));
                        }
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "moveSongInPlaylist": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        ContentResolver resolver = getContentResolver();
                        boolean moved = MediaStore.Audio.Playlists.Members.moveItem(
                                resolver,
                                getLong(call.argument("id")),
                                Objects.requireNonNull(call.argument("from")),
                                Objects.requireNonNull(call.argument("to"))
                        );
                        if (moved) {
                            resolver.notifyChange(
                                    MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                    null
                            );
                        }
                        handler.post(() -> result.success(moved));
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "removeFromPlaylistAt": {
                Handler handler = new Handler(Looper.getMainLooper());
                Executors.newSingleThreadExecutor().execute(() -> {
                    try {
                        Long id = Objects.requireNonNull(getLong(call.argument("id")));
                        if (playlistExists(id)) {
                            ArrayList<Object> indexes = Objects.requireNonNull(call.argument("indexes"));
                            ArrayList<String> stringIndexes = new ArrayList<>();
                            for (Object index : indexes) {
                                // Android seems to require indexes to be offset by 1.
                                //
                                // It might be because when songs are inserted into the playlist,
                                // the indexing is quite similar an there it makes sense, because we need
                                // to be able to insert to `playlistLength + 1` position.
                                stringIndexes.add(String.valueOf(getLong(index) + 1));
                            }
                            ContentResolver resolver = getContentResolver();
                            Uri uri;
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                uri = MediaStore.Audio.Playlists.Members.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL,
                                        id
                                );
                            } else {
                                uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                            }
                            int deletedRows = resolver.delete(
                                    uri,
                                    FetchHandler.buildWhereForCount(
                                            MediaStore.Audio.Playlists.Members.PLAY_ORDER,
                                            indexes.size()
                                    ),
                                    stringIndexes.toArray(new String[0])
                            );
                            if (deletedRows > 0) {
                                resolver.notifyChange(
                                        MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                                        null
                                );
                            }
                            handler.post(() -> result.success(null));
                        } else {
                            handler.post(
                                    () -> result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id));
                        }
                    } catch (Exception e) {
                        handler.post(() -> result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e)));
                    }
                });
                break;
            }
            case "isIntentActionView": {
                Activity activity = null;
                if (activityBinding != null) {
                    activity = activityBinding.getActivity();
                }
                if (activity != null) {
                    Intent intent = activity.getIntent();
                    result.success(Intent.ACTION_VIEW.equals(intent.getAction()));
                } else {
                    throw new IllegalStateException("Not attached to activity");
                }
                break;
            }
            default:
                result.notImplemented();
            }
        } catch (Exception e) {
            result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
        }
    }

    private boolean playlistExists(Long id) {
        Cursor cursor = getContentResolver().query(
                MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                new String[] {MediaStore.Audio.Playlists._ID},
                MediaStore.Audio.Playlists._ID + "=?",
                new String[] {id.toString()},
                null
        );
        if (cursor == null) {
            return false;
        }
        if (cursor.getCount() == 0) {
            cursor.close();
            return false;
        }
        return true;
    }

    private ContentResolver getContentResolver() {
        return Objects.requireNonNull(binding).getApplicationContext().getContentResolver();
    }

    @UiThread
    public void startIntentSenderForResult(PendingIntent pendingIntent, Constants.intents intent) {
        try {
            Objects.requireNonNull(activityBinding).getActivity().startIntentSenderForResult(
                    pendingIntent.getIntentSender(),
                    intent.value,
                    null,
                    0,
                    0,
                    0);
        } catch (IntentSender.SendIntentException e) {
            if (this.result != null) {
                result.error(INTENT_SENDER_ERROR, e.getMessage(), Log.getStackTraceString(e));
                this.result = null;
            }
        } catch (Exception error) {
            if (this.result != null) {
                result.error(UNEXPECTED_ERROR, error.getMessage(), Log.getStackTraceString(error));
                this.result = null;
            }
        }
    }

    /**
     * Sends a results after activity receives a result after calling
     * {@link #startIntentSenderForResult}
     */
    public void sendResultFromIntent(boolean value) {
        if (this.result != null) {
            result.success(value);
            this.result = null;
        }
    }

    private Long getLong(Object rawValue) {
        if (rawValue instanceof Long) {
            return (Long) rawValue;
        } else if (rawValue instanceof Integer) {
            return Long.valueOf((Integer) rawValue);
        } else {
            throw new IllegalArgumentException();
        }
    }
}
