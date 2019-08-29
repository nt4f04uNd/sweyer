package com.example.app;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.media.AudioManager;
import android.media.AudioFocusRequest;
import android.util.Log;
import io.flutter.plugin.common.EventChannel;

// Method channel
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.List;
import java.util.ArrayList;
import android.provider.MediaStore;
import android.database.Cursor;
import android.net.Uri;
import android.content.ContentUris;

public class MainActivity extends FlutterActivity {
   private static final String eventChannelStream = "eventChannelStream";
   private static final String methodChannelStream = "methodChannelStream";
   private static String TAG = "player/java file";
   private static IntentFilter intentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);
   private static BecomingNoisyReceiver myNoisyAudioStreamReceiver = null;

   /** Focus request for audio manager */
   private static AudioFocusRequest focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
         .setAcceptsDelayedFocusGain(true).setOnAudioFocusChangeListener(new OnFocusChangeListener()).build();
   private static MethodChannel methodChannel;

   private AudioManager audioManager;

   /** Request audio manager focus for app */
   private String requestFocus() {
      int res = audioManager.requestAudioFocus(focusRequest);
      Log.w(TAG, "REQUEST FOCUS " + res);
      if (res == AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
         return "AUDIOFOCUS_REQUEST_FAILED";
      } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
         return "AUDIOFOCUS_REQUEST_GRANTED";
      } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
         return "AUDIOFOCUS_REQUEST_DELAYED";
      }
      return "WRONG_EVENT";
   }

   private int abandonFocus() {
      int res = audioManager.abandonAudioFocusRequest(focusRequest);
      Log.w(TAG, "ABANDON FOCUS " + res);
      return res;
   }

   /** Listener for audio manager focus change */
   private static final class OnFocusChangeListener implements AudioManager.OnAudioFocusChangeListener {
      @Override
      public void onAudioFocusChange(int focusChange) {
         Log.w(TAG, "ONFOCUSCHANGE: " + focusChange);
         switch (focusChange) {
         case AudioManager.AUDIOFOCUS_GAIN:
            Log.w(TAG, "GAIN");
            methodChannel.invokeMethod("focus_change", "AUDIOFOCUS_GAIN");
            break;
         case AudioManager.AUDIOFOCUS_LOSS:
            Log.w(TAG, "LOSS");
            methodChannel.invokeMethod("focus_change", "AUDIOFOCUS_LOSS");
            break;
         case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
            Log.w(TAG, "ANOTHER LOSS");
            methodChannel.invokeMethod("focus_change", "AUDIOFOCUS_LOSS_TRANSIENT");
            break;
         case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
            Log.w(TAG, "KAVO");
            methodChannel.invokeMethod("focus_change", "AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK");
            break;
         }
      }
   }

   /** Event receiver for become noisy event */
   private static class BecomingNoisyReceiver extends BroadcastReceiver {
      final EventChannel.EventSink eventSink;

      BecomingNoisyReceiver(EventChannel.EventSink eventSink) {
         super();
         this.eventSink = eventSink;
      }

      @Override
      public void onReceive(Context context, Intent intent) {
         if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) {
            eventSink.success("became_noisy");
         }
      }

   }

   /** Check for if Intent action is VIEW */
   private boolean isIntentActionView() {
      Intent intent = getIntent();
      if (Intent.ACTION_VIEW.equals(intent.getAction())) {
         return true;
      }
      return false;
   }

   private List<String> retrieveSongs() {
      // Retrieve a list of Music files currently listed in the Media store DB via
      // URI.

      List<String> songs = new ArrayList<>();
      // Some audio may be explicitly marked as not being music
      String selection = MediaStore.Audio.Media.IS_MUSIC + " != 0";

      String[] projection = { MediaStore.Audio.Media._ID, MediaStore.Audio.Media.ARTIST, MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID, MediaStore.Audio.Media.TITLE, MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DURATION };

      Cursor cursor = getApplicationContext().getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection, selection, null, null);

      String sArtworkUri = "content://media/external/audio/albumart/";

      while (cursor.moveToNext()) {
         // songs.add(cursor.getString(0) + "||" + cursor.getString(1) + "||" +
         // cursor.getString(2) + "||"
         // + cursor.getString(3) + "||" + cursor.getString(4) + "||" +
         // cursor.getString(5) + "||"
         // + cursor.getString(6) + "||" + ContentUris.withAppendedId(sArtworkUri,
         // cursor.getInt(7)));
         songs.add(new Song(cursor.getInt(0), cursor.getString(1), cursor.getString(2), getAlbumArt(cursor.getInt(3)),
               cursor.getString(4), cursor.getString(5), cursor.getInt(6)).toJson());
      }
      cursor.close();
      return songs;
   }

   private String getAlbumArt(int albumId) {
      Cursor cursor = getContentResolver().query(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            new String[] { MediaStore.Audio.Albums._ID, MediaStore.Audio.Albums.ALBUM_ART },
            MediaStore.Audio.Albums._ID + "=?", new String[] { String.valueOf(albumId) }, null);

      String path = null;
      if (cursor.moveToFirst())
         path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART));
      cursor.close();
      return path;
   }

   /** Class representing a song */
   private static class Song {
      private final int id;
      private final String artist;
      private final String album;
      private final String albumArtUri;
      private final String title;
      private final String trackUri;
      private final int duration;

      Song(final int id, final String artist, final String album, final String albumArtUri, final String title,
            final String trackUri, final int duration) {
         this.id = id;
         this.artist = artist;
         this.album = album;
         this.albumArtUri = albumArtUri;
         this.title = title;
         this.trackUri = trackUri;
         this.duration = duration;
      }

      static private char commaChar = '"';

      static String wrapWithCommas(String value) {
         if (value != null)
            return commaChar + value + commaChar;
         return value;
      }

      String toJson() {
         return String.format(
               "{\"id\":%d,\"artist\": %s,\"album\": %s,\"albumArtUri\": %s,\"title\": %s,\"trackUri\": %s,\"duration\": %d}",
               this.id, wrapWithCommas(this.artist), wrapWithCommas(this.album), wrapWithCommas(this.albumArtUri),
               wrapWithCommas(this.title), wrapWithCommas(this.trackUri), this.duration);
      }

   }


   @Override
   protected void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      GeneratedPluginRegistrant.registerWith(this);

      // Setup methodChannel
      methodChannel = new MethodChannel(getFlutterView(), methodChannelStream);

      // Audio manager become noisy event
      new EventChannel(getFlutterView(), eventChannelStream).setStreamHandler(new EventChannel.StreamHandler() {
         @Override
         public void onListen(Object args, final EventChannel.EventSink events) {
            myNoisyAudioStreamReceiver = new BecomingNoisyReceiver(events);
            registerReceiver(myNoisyAudioStreamReceiver, intentFilter);
         }

         @Override
         public void onCancel(Object args) {
            unregisterReceiver(myNoisyAudioStreamReceiver);
         }
      });

      // Audio manager focus
      if (audioManager == null)
         audioManager = (AudioManager) getApplicationContext().getSystemService(getApplicationContext().AUDIO_SERVICE);

      methodChannel.setMethodCallHandler(new MethodCallHandler() {
         @Override
         public void onMethodCall(MethodCall call, Result result) {
            // Note: this method is invoked on the main thread.
            switch (call.method) {
            case "request_focus":
               result.success(requestFocus());
               break;
            case "abandon_focus":
            result.success(abandonFocus());
               break;
            case "intent_action_view":
               result.success(isIntentActionView());
               break;
            case "retrieve_songs":
               result.success(retrieveSongs());
               break;
            default:
               Log.w(TAG, "Invalid method name call from Dart code");
            }
         }
      });
   }

   @Override
   protected void onDestroy() {
      super.onDestroy();
      unregisterReceiver(myNoisyAudioStreamReceiver);
   }
}