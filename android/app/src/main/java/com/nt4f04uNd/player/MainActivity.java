package com.nt4f04uNd.player;

import com.nt4f04uNd.player.handlers.*;
import com.nt4f04uNd.player.receivers.*;
import com.nt4f04uNd.player.songs.*;

import android.content.Context;
import android.os.Bundle;

import androidx.annotation.NonNull;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.util.Log;

// Method channel
import io.flutter.plugin.common.MethodChannel;

import java.lang.ref.WeakReference;
import java.util.List;

import android.view.KeyEvent;
import android.media.session.MediaSession;

import android.os.AsyncTask;

public class MainActivity extends FlutterActivity {

   private static IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

   private static NotificationReceiver myNotificationReceiver = null;
   private static BecomingNoisyReceiver myNoisyAudioStreamReceiver = null;

   private static MethodChannel playerChannel;
   private static MethodChannel songsChannel;
   private static EventChannel eventChannel;

   private AudioFocusHandler audioFocusHandler;
   private NotificationHandler notificationHandler;
   private MediaButtonsHandler mediaButtonsHandler;

   private class AudioFocusHandler extends AudioFocusHandlerAbstraction {
      AudioFocusHandler() {
         super(getApplicationContext());
      }

      @Override
      protected void onFocusGain() {
         Log.w(Constants.LogTag, Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN);
         playerChannel.invokeMethod(Constants.PLAYER_METHOD_FOCUS_CHANGE,
               Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN);
      }

      @Override
      protected void onFocusLoss() {
         Log.w(Constants.LogTag, Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS);
         playerChannel.invokeMethod(Constants.PLAYER_METHOD_FOCUS_CHANGE,
               Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS);
      }

      @Override
      protected void onFocusLossTransient() {
         Log.w(Constants.LogTag, Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT);
         playerChannel.invokeMethod(Constants.PLAYER_METHOD_FOCUS_CHANGE,
               Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT);
      }

      @Override
      protected void onFocusLossTransientCanDuck() {
         Log.w(Constants.LogTag, Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
         playerChannel.invokeMethod(Constants.PLAYER_METHOD_FOCUS_CHANGE,
               Constants.PLAYER_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
      }
   }

   private static class TaskSearchSongs extends AsyncTask<Void, Void, List<String>> {
      private WeakReference<Context> appReference;

      // only retain a weak reference to the activity
      // see https://stackoverflow.com/a/46166223/9710294
      TaskSearchSongs(Context context) {
         appReference = new WeakReference<>(context);
      }

      @Override
      protected List<String> doInBackground(Void... params) {
         return SongFetcher.retrieveSongs(appReference.get());
      }

      @Override
      protected void onPostExecute(List<String> result) {
         songsChannel.invokeMethod(Constants.SONGS_METHOD_METHOD_SEND_SONGS, result);
      }
   }

   /**
    * Check for if Intent action is VIEW
    */
   private boolean isIntentActionView() {
      Intent intent = getIntent();
      return Intent.ACTION_VIEW.equals(intent.getAction());
   }

   @Override
   protected void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      GeneratedPluginRegistrant.registerWith(this);

      audioFocusHandler = new AudioFocusHandler();
      notificationHandler = new NotificationHandler(getApplicationContext());
      mediaButtonsHandler = new MediaButtonsHandler(getApplicationContext(), playerChannel);

      // Setup playerChannel
      playerChannel = new MethodChannel(getFlutterView(), Constants.PLAYER_CHANNEL_STREAM);
      // Setup songsChannel
      songsChannel = new MethodChannel(getFlutterView(), Constants.SONGS_CHANNEL_STREAM);
      // Setup event channel
      eventChannel = new EventChannel(getFlutterView(), Constants.EVENT_CHANNEL_STREAM);

      eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
         @Override
         public void onListen(Object args, final EventChannel.EventSink events) {
            myNotificationReceiver = new NotificationReceiver(events);
            myNoisyAudioStreamReceiver = new BecomingNoisyReceiver(events);
            registerReceiver(myNotificationReceiver, notificationHandler.intentFilter);
            registerReceiver(myNoisyAudioStreamReceiver, noisyIntentFilter);

            mediaButtonsHandler.turnActive();
         }

         @Override
         public void onCancel(Object args) {
            unregisterReceiver(myNotificationReceiver);
            unregisterReceiver(myNoisyAudioStreamReceiver);
         }
      });

      playerChannel.setMethodCallHandler((call, result) -> {
         // NOTE: this method is invoked on the main thread.
         final String method = call.method;
         if (method.equals(Constants.PLAYER_METHOD_REQUEST_FOCUS)) {
            result.success(audioFocusHandler.requestFocus());
         } else if (method.equals(Constants.PLAYER_METHOD_ABANDON_FOCUS)) {
            result.success(audioFocusHandler.abandonFocus());
         } else if (method.equals(Constants.PLAYER_METHOD_INTENT_ACTION_VIEW)) {
            result.success(isIntentActionView());
         } else if (method.equals(Constants.PLAYER_METHOD_NOTIFICATION_SHOW)) {
            notificationHandler.buildNotification(getApplicationContext(),
                  call.argument(Constants.PLAYER_METHOD_NOTIFICATION_SHOW_ARG_TITLE),
                  call.argument(Constants.PLAYER_METHOD_NOTIFICATION_SHOW_ARG_ARTIST),
                  call.argument(Constants.PLAYER_METHOD_NOTIFICATION_SHOW_ARG_ALBUM_ART_BYTES),
                  call.argument(Constants.PLAYER_METHOD_NOTIFICATION_SHOW_ARG_IS_PLAYING));
            result.success("");
         } else if (method.equals(Constants.PLAYER_METHOD_NOTIFICATION_CLOSE)) {
            notificationHandler.closeNotification();
            result.success("");
         } else {
            Log.w(Constants.LogTag, "playerChannel: Invalid method name call from Dart code");
         }
      });

      songsChannel.setMethodCallHandler((call, result) -> {
         // Note: this method is invoked on the main thread.
         final String method = call.method;
         if (method.equals(Constants.SONGS_METHOD_METHOD_RETRIEVE_SONGS)) {
            // Run method on another thread
            new TaskSearchSongs(getApplicationContext()).execute();
            result.success("");
         } else {
            Log.w(Constants.LogTag, "songsChannel: Invalid method name call from Dart code");
         }
      });
   }

   @Override
   protected void onDestroy() {
      super.onDestroy();
      audioFocusHandler.abandonFocus();
      notificationHandler.closeNotification();
      mediaButtonsHandler.release();
      unregisterReceiver(myNoisyAudioStreamReceiver);
      unregisterReceiver(myNotificationReceiver);
   }
}

// TODO: add support for headset and/or bluetooth buttons (check vk)
// TODO: probably? add launch intent broadcast receiver and get extra argument
// that denotes that activity has been opened from notification

// TODO: as I specify very big priority for mediabutton intent-filter, i should
// add handler to start music when media buttonm got clicked, but application is
// not started
// TODO: add broadreceiver that will handle hook click in background