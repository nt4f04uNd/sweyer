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
   private static final String INTENT_SENDER_ERROR = "INTENT_SENDER_ERROR";
   private static final String IO_ERROR = "IO_ERROR";
   private static final String SDK_ERROR = "SDK_ERROR";
   private static final String PLAYLIST_NOT_EXISTS_ERROR = "PLAYLIST_NOT_EXISTS_ERROR";

   public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
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
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "retrieveSongs": {
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
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
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
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
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
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
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
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
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
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
            case "setSongsFavorite": {
               if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                  this.result = result;
                  Boolean value = call.argument("value");
                  ArrayList<HashMap<String, Object>> songs = call.argument("songs");
                  ArrayList<Uri> uris = new ArrayList<>();
                  for (HashMap<String, Object> song : songs) {
                     Long id = GeneralHandler.getLong(song.get("id"));
                     uris.add(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id));
                  }
                  PendingIntent pendingIntent = MediaStore.createFavoriteRequest(
                          GeneralHandler.getAppContext().getContentResolver(),
                          uris,
                          value
                  );
                  startIntentSenderForResult(pendingIntent, Constants.intents.FAVORITE_REQUEST);
               } else {
                  result.error(SDK_ERROR, "This method requires Android 30 and above", "");
               }
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
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
                  try {
                     String name = call.argument("name");
                     ContentResolver resolver = getContentResolver();
                     ContentValues values = new ContentValues(1);
                     values.put(MediaStore.Audio.Playlists.NAME, name);

                     Uri uri = resolver.insert(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, values);
                     if (uri != null) {
                        resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                     }
                     handler.post(() -> {
                        result.success(null);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });

                  }
               });
               break;
            }
            case "renamePlaylist": {
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
                  try {
                     Long id = GeneralHandler.getLong(call.argument("id"));
                     ContentResolver resolver = getContentResolver();
                     if (playlistExists(id)) {
                        String name = call.argument("name");
                        ContentValues values = new ContentValues(1);
                        values.put(MediaStore.Audio.Playlists.NAME, name);

                        int rows = resolver.update(
                                ContentUris.withAppendedId(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, id),
                                values,
                                null,
                                null
                        );
                        if (rows > 0) {
                           resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                        }
                        handler.post(() -> {
                           result.success(null);
                        });
                     } else {
                        handler.post(() -> {
                           result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id);
                        });
                     }
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "removePlaylists": {
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
                  try {
                     ArrayList<Object> songIds = call.argument("ids");
                     ArrayList<String> songIdStrings = new ArrayList<>();
                     for (Object id : songIds) {
                        songIdStrings.add(id.toString());
                     }
                     ContentResolver resolver = getContentResolver();
                     resolver.delete(
                             MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI,
                             FetchHandler.buildWhereForCount(MediaStore.Audio.Playlists._ID, songIdStrings.size()),
                             songIdStrings.toArray(new String[0])
                     );
                     resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                     handler.post(() -> {
                        result.success(null);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "insertSongsInPlaylist": {
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
                  try {
                     Long id = GeneralHandler.getLong(call.argument("id"));
                     if (playlistExists(id)) {
                        Long index = GeneralHandler.getLong(call.argument("index"));
                        ArrayList<Object> songIds = call.argument("songIds");
                        ContentResolver resolver = getContentResolver();
                        Uri uri;
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                           uri = MediaStore.Audio.Playlists.Members.getContentUri(MediaStore.VOLUME_EXTERNAL, id);
                        } else {
                           uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                        }
                        ArrayList<ContentValues> valuesList = new ArrayList<>();
                        for (int i = 0; i < songIds.size(); i++) {
                           ContentValues values = new ContentValues(2);
                           values.put(MediaStore.Audio.Playlists.Members.AUDIO_ID, GeneralHandler.getLong(songIds.get(i)));
                           values.put(MediaStore.Audio.Playlists.Members.PLAY_ORDER, i + index);
                           valuesList.add(values);
                        }
                        resolver.bulkInsert(uri, valuesList.toArray(new ContentValues[0]));
                        handler.post(() -> {
                           result.success(null);
                        });
                     } else {
                        handler.post(() -> {
                           result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id);
                        });
                     }
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
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
                             GeneralHandler.getLong(call.argument("id")),
                             call.argument("from"),
                             call.argument("to")
                     );
                     if (moved) {
                        resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                     }
                     handler.post(() -> {
                        result.success(moved);
                     });
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
            }
            case "removeSongsFromPlaylist": {
               Handler handler = new Handler(Looper.getMainLooper());
               Executors.newSingleThreadExecutor().execute(() -> {
                  try {
                     Long id = GeneralHandler.getLong(call.argument("id"));
                     if (playlistExists(id)) {
                        ArrayList<Object> songIds = call.argument("songIds");
                        ArrayList<String> stringSongIds = new ArrayList<>();
                        for (Object songId : songIds) {
                           stringSongIds.add(songId.toString());
                        }
                        ContentResolver resolver = getContentResolver();
                        Uri uri;
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                           uri = MediaStore.Audio.Playlists.Members.getContentUri(MediaStore.VOLUME_EXTERNAL, id);
                        } else {
                           uri = MediaStore.Audio.Playlists.Members.getContentUri("external", id);
                        }
                        int deletedRows = resolver.delete(
                                uri,
                                FetchHandler.buildWhereForCount(MediaStore.Audio.Playlists.Members.AUDIO_ID, songIds.size()),
                                stringSongIds.toArray(new String[0])
                        );
                        if (deletedRows > 0) {
                           resolver.notifyChange(MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI, null);
                        }
                        handler.post(() -> {
                           result.success(null);
                        });
                     } else {
                        handler.post(() -> {
                           result.error(PLAYLIST_NOT_EXISTS_ERROR, "No playlists with such id", id);
                        });
                     }
                  } catch (Exception e) {
                     handler.post(() -> {
                        result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
                     });
                  }
               });
               break;
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
   public void startIntentSenderForResult(PendingIntent pendingIntent, Constants.intents intent) {
      try {
         activity.startIntentSenderForResult(
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
      } catch (Exception e) {
         if (this.result != null) {
            result.error(UNEXPECTED_ERROR, e.getMessage(), Log.getStackTraceString(e));
            this.result = null;
         }
      }
   }

   /**
    * Sends a results after activity receives a result after calling
    * {@link #startIntentSenderForResult}
    */
   public void sendResultFromIntent(boolean result) {
      if (this.result != null) {
         this.result.success(result);
         this.result = null;
      }
   }
}
