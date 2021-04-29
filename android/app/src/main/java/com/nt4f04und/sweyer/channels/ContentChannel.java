/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.channels;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Intent;
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

import androidx.annotation.Nullable;
import androidx.annotation.UiThread;

import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.handlers.FetchHandler;
import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.nt4f04und.sweyer.services.DeletionService;

import org.jetbrains.annotations.NotNull;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public enum ContentChannel {
   instance;

   public void init(BinaryMessenger messenger, FlutterActivity activity) {
      if (channel == null) {
         this.activity = activity;
         channel = new MethodChannel(messenger, "content_channel");
         channel.setMethodCallHandler(this::onMethodCall);
      }
   }

   public void destroy() {
      channel = null;
      activity = null;
   }

   @Nullable
   MethodChannel channel;
   @Nullable
   private MethodChannel.Result result;
   @Nullable
   public Activity activity;
   private final HashMap<String, CancellationSignal> loadingSignals = new HashMap<>();

   private static final String UNEXPECTED_ERROR = "UNEXPECTED_ERROR";
   private static final String DELETION_ERROR = "DELETION_ERROR";
   private static final String IO_ERROR = "IO_ERROR";
   private static final String SDK_ERROR = "SDK_ERROR";
   private static final String PLAYLIST_EXISTS_ERROR = "PLAYLIST_EXISTS_ERROR";
   private static final String PLAYLIST_NOT_EXISTS_ERROR = "PLAYLIST_NOT_EXISTS_ERROR";
   private static final String PLAYLIST_CREATE_FAILED_ERROR = "PLAYLIST_CREATE_FAILED_ERROR";
   private static final String PLAYLIST_REMOVE_FAILED_ERROR = "PLAYLIST_REMOVE_FAILED_ERROR";

   public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
      try {
         switch (call.method) {
            case "loadAlbumArt": {
               if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                  ExecutorService executor = Executors.newSingleThreadExecutor();
                  Handler handler = new Handler(Looper.getMainLooper());
                  ContentResolver contentResolver = getContentResolver();
                  CancellationSignal signal = new CancellationSignal();
                  String id = call.argument("id");
                  loadingSignals.put(id, signal);
                  executor.execute(() -> {
                     byte[] bytes = null;
                     try {
                        Bitmap bitmap = contentResolver.loadThumbnail(
                                Uri.parse(call.argument("uri")),
                                new Size((int) call.argument("width"), (int) call.argument("height")),
                                signal);
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                        bytes = stream.toByteArray();
                        stream.close();
                     } catch (OperationCanceledException ex) {
                        // do nothing
                     } catch (IOException e) {
                        result.error(IO_ERROR, "loadThumbnail failed", Log.getStackTraceString(e));
                     } finally {
                        byte[] finalBytes = bytes;
                        handler.post(() -> {
                           loadingSignals.remove(id);
                           result.success(finalBytes);
                        });
                     }
                  });
               } else {
                  result.error(SDK_ERROR, "This method requires Android Q and above", "");
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
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  Long id = GeneralHandler.getLong(call.argument("id"));
                  Uri songCover = Uri.parse("content://media/external/audio/albumart");
                  Uri uriSongCover = ContentUris.withAppendedId(songCover, id);
                  ContentResolver res = getContentResolver();
                  try {
                     InputStream is = res.openInputStream(uriSongCover);
                     is.close();
                  } catch (Exception ex) {
                     // do nothing
                  }
                  handler.post(() -> {
                     result.success(null);
                  });
               });
               break;
            }
            case "retrieveSongs": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  try {
                     ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveSongs();
                     handler.post(() -> {
                        result.success(res);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "retrieveAlbums": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  try {
                     ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveAlbums();
                     handler.post(() -> {
                        result.success(res);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "retrievePlaylists": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  try {
                     ArrayList<HashMap<?, ?>> res = FetchHandler.retrievePlaylists();
                     handler.post(() -> {
                        result.success(res);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "retrieveArtists": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  try {
                     ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveArtists();
                     handler.post(() -> {
                        result.success(res);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "retrieveGenres": {
               ExecutorService executor = Executors.newSingleThreadExecutor();
               Handler handler = new Handler(Looper.getMainLooper());
               executor.execute(() -> {
                  try {
                     ArrayList<HashMap<?, ?>> res = FetchHandler.retrieveGenres();
                     handler.post(() -> {
                        result.success(res);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "deleteSongs": {
               Intent serviceIntent = new Intent(GeneralHandler.getAppContext(), DeletionService.class);
               serviceIntent.putExtra("songs", (ArrayList<HashMap<?, ?>>) call.argument("songs"));
               GeneralHandler.getAppContext().startService(serviceIntent);
               if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                  // Save the result to report to the flutter code later in `sendDeletionResult`
                  this.result = result;
               } else {
                  result.success(true);
               }
               break;
            }
            case "createPlaylist": {
               String name = call.argument("name");
               ContentResolver resolver = getContentResolver();
               if (playlistExists(name)) {
                  result.error(PLAYLIST_EXISTS_ERROR, "Playlist with such already exists", name);
               } else {
                  ContentValues values = new ContentValues();
                  values.put(MediaStore.Audio.Playlists.NAME, name);
                  try {
                     Uri uri = resolver.insert(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, values);
                     if (uri != null) {
                        resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                     }
                  } catch (Exception e) {
                     result.error(PLAYLIST_CREATE_FAILED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                  }
               }
               break;
            }
            case "removePlaylist": {
               try {
                  ContentResolver resolver = getContentResolver();
                  resolver.delete(
                          MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                          MediaStore.Audio.Playlists._ID + "=?",
                          new String[]{call.argument("id")}
                  );
                  resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                  result.success(null);
               } catch (Exception e) {
                  result.error(PLAYLIST_REMOVE_FAILED_ERROR, e.getMessage(), Log.getStackTraceString(e));
               }
               break;
            }
            case "insertSongsInPlaylist": {
               Long id = GeneralHandler.getLong(call.argument("id"));
               if (playlistExists(id)) {
                  Long index = GeneralHandler.getLong(call.argument("index"));
                  ArrayList<Long> songIds = call.argument("songIds");
                  ContentResolver resolver = getContentResolver();
                  Uri uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                  ArrayList<ContentValues> valuesList = new ArrayList<>();
                  for (int i = index.intValue(); i < index + songIds.size(); i++) {
                     ContentValues values = new ContentValues();
                     values.put(MediaStore.Audio.Playlists.Members.AUDIO_ID, songIds.get(i));
                     values.put(MediaStore.Audio.Playlists.Members.PLAY_ORDER, i);
                     valuesList.add(values);
                  }
                  resolver.bulkInsert(uri, valuesList.toArray(new ContentValues[0]));
                  result.success(null);
               } else {
                  result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id);
               }
               break;
            }
            case "moveSongInPlaylist": {
               ContentResolver resolver = getContentResolver();
               boolean moved = MediaStore.Audio.Playlists.Members.moveItem(
                       resolver,
                       GeneralHandler.getLong(call.argument("id")),
                       call.argument("from"),
                       call.argument("to")
               );
               if (moved) {
                  resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
               }
               result.success(moved);
               break;
            }
            case "removeSongsFromPlaylist": {
               Long id = GeneralHandler.getLong(call.argument("id"));
               if (playlistExists(id)) {
                  ArrayList<Long> songIds = call.argument("songIds");
                  ArrayList<String> stringSongIds = new ArrayList<>();
                  for (Long songId : songIds) {
                     stringSongIds.add(songId.toString());
                  }
                  ContentResolver resolver = getContentResolver();
                  Uri uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                  int deletedRows = resolver.delete(
                          uri,
                          FetchHandler.buildWhereForCount(MediaStore.Audio.Playlists.Members.AUDIO_ID, songIds.size()),
                          stringSongIds.toArray(new String[0])
                  );
                  if (deletedRows > 0) {
                     resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                  }
                  break;
               } else {
                  result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id);
               }
            }
            case "isIntentActionView": {
               if (activity != null) {
                  Intent intent = activity.getIntent();
                  result.success(Intent.ACTION_VIEW.equals(intent.getAction()));
               } else {
                  throw new IllegalStateException("activity is null");
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

   private boolean playlistExists(String name) {
      Cursor cursor = getContentResolver().query(
              MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
              new String[]{MediaStore.Audio.Playlists.NAME},
              MediaStore.Audio.Playlists.NAME + "=?",
              new String[]{name},
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

   private boolean playlistExists(Long id) {
      Cursor cursor = getContentResolver().query(
              MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
              new String[]{MediaStore.Audio.Playlists._ID},
              MediaStore.Audio.Playlists._ID + "=?",
              new String[]{id.toString()},
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
      return GeneralHandler.getAppContext().getContentResolver();
   }

   @UiThread
   public void startDeletion(PendingIntent intent) {
      try {
         if (activity != null) {
            activity.startIntentSenderForResult(
                    intent.getIntentSender(),
                    Constants.intents.PERMANENT_DELETION_REQUEST,
                    null,
                    0,
                    0,
                    0);
         } else {
            throw new IllegalStateException("activity is null");
         }
      } catch (Exception e) {
         if (this.result != null) {
            result.error(DELETION_ERROR, e.getMessage(), "");
            this.result = null;
         }
      }
   }

   public void sendDeletionResult(boolean result) {
      if (this.result != null) {
         this.result.success(result);
         this.result = null;
      }
   }
}
