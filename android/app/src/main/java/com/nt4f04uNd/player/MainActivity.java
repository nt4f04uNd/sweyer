package com.nt4f04uNd.player;

import com.nt4f04uNd.player.channels.AudioFocusChannelHandler;
import com.nt4f04uNd.player.channels.GeneralChannelHandler;
import com.nt4f04uNd.player.channels.NotificationChannelHandler;
import com.nt4f04uNd.player.channels.PlayerChannelWrapper;
import com.nt4f04uNd.player.channels.SongChannelHandler;
import com.nt4f04uNd.player.handlers.*;
import com.nt4f04uNd.player.player.PlayerForegroundService;
import com.nt4f04uNd.player.receivers.*;
import com.nt4f04uNd.player.songs.*;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import android.content.IntentFilter;
import android.media.AudioManager;

// Method channel
import io.flutter.plugin.common.MethodChannel;

import java.lang.ref.WeakReference;
import java.util.List;

import android.os.AsyncTask;

public class MainActivity extends FlutterActivity {

    private static IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

    private static NotificationReceiver myNotificationReceiver = null;
    private static BecomingNoisyReceiver myNoisyAudioStreamReceiver = null;

    private static MethodChannel audioFocusChannel;
    private static EventChannel eventChannel;
    private static MethodChannel generalChannel;
    private static MethodChannel mediaButtonChannel;
    private static MethodChannel notificationChannel;
    private static MethodChannel playerChannel;
    private static MethodChannel songsChannel;

    private static PlayerChannelWrapper playerChannelWrapper;

    private class OnAudioFocusListener extends com.nt4f04uNd.player.handlers.OnAudioFocusChangeListener {
        @Override
        protected void onFocusGain() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN);
            audioFocusChannel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN
            );
        }

        @Override
        protected void onFocusLoss() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS);
            audioFocusChannel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS
            );
        }

        @Override
        protected void onFocusLossTransient() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT);
            audioFocusChannel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT
            );
        }

        @Override
        protected void onFocusLossTransientCanDuck() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
            audioFocusChannel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK
            );
        }
    }

    private class OnMediaButtonListener extends com.nt4f04uNd.player.handlers.OnMediaButtonListener {

        @Override
        protected void onAudioTrack() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_AUDIO_TRACK);
        }

        @Override
        protected void onFastForward() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_FAST_FORWARD);
        }

        @Override
        protected void onRewind() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_REWIND);
        }

        @Override
        protected void onNext() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_NEXT);
        }

        @Override
        protected void onPrevious() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PREVIOUS);
        }

        @Override
        protected void onPlayPause() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PLAY_PAUSE);
        }

        @Override
        protected void onPlay() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PLAY);
        }

        @Override
        protected void onStop() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_STOP);
        }

        @Override
        protected void onHook() {
            mediaButtonChannel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_HOOK);
        }
    }

    public static class TaskSearchSongs extends AsyncTask<Void, Void, List<String>> {
        private WeakReference<Context> appReference;

        // only retain a weak reference to the activity
        // see https://stackoverflow.com/a/46166223/9710294
        public TaskSearchSongs(Context context) {
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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        // Setup action handlers
        AudioFocusHandler.init(getApplicationContext(), new OnAudioFocusListener());
        NotificationHandler.init(getApplicationContext());
        MediaButtonHandler.init(getApplicationContext(), new OnMediaButtonListener());

        // Setup channels
        audioFocusChannel = new MethodChannel(getFlutterView(), Constants.AUDIO_FOCUS_CHANNEL);
        eventChannel = new EventChannel(getFlutterView(), Constants.EVENT_CHANNEL_STREAM);
        generalChannel = new MethodChannel(getFlutterView(), Constants.GENERAL_CHANNEL_STREAM);
        mediaButtonChannel = new MethodChannel(getFlutterView(), Constants.MEDIABUTTON_CHANNEL_STREAM);
        notificationChannel = new MethodChannel(getFlutterView(), Constants.NOTIFICATION_CHANNEL_STREAM);
        playerChannel = new MethodChannel(getFlutterView(), Constants.PLAYER_CHANNEL_STREAM);
        songsChannel = new MethodChannel(getFlutterView(), Constants.SONGS_CHANNEL_STREAM);

        audioFocusChannel.setMethodCallHandler(new AudioFocusChannelHandler());
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, final EventChannel.EventSink events) {
                myNotificationReceiver = new NotificationReceiver(events);
                myNoisyAudioStreamReceiver = new BecomingNoisyReceiver(events);
                registerReceiver(myNotificationReceiver, NotificationHandler.intentFilter);
                registerReceiver(myNoisyAudioStreamReceiver, noisyIntentFilter);

                MediaButtonHandler.turnActive();
            }

            @Override
            public void onCancel(Object args) {
                unregisterReceiver(myNotificationReceiver);
                unregisterReceiver(myNoisyAudioStreamReceiver);
            }
        });
        generalChannel.setMethodCallHandler(new GeneralChannelHandler(this));
        notificationChannel.setMethodCallHandler(new NotificationChannelHandler(getApplicationContext()));
        playerChannelWrapper = new PlayerChannelWrapper(playerChannel, getApplicationContext());
        songsChannel.setMethodCallHandler(new SongChannelHandler(getApplicationContext()));


//        Intent forService = new Intent(getApplicationContext(), PlayerForegroundService.class);
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            startForegroundService(forService);
//        } else {
//            startService(forService);
//        }

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        AudioFocusHandler.abandonFocus();
        NotificationHandler.closeNotification();
        MediaButtonHandler.release();
        unregisterReceiver(myNoisyAudioStreamReceiver);
        unregisterReceiver(myNotificationReceiver);
    }
}

// TODO: probably? add launch intent broadcast receiver and get extra argument
// that denotes that activity has been opened from notification

// TODO: as I specify very big priority for mediabutton intent-filter, i should
// add handler to start music when media button gets clicked, but the application is
// not started