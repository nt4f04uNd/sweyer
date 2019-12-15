/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player;

import com.nt4f04uNd.player.channels.AudioFocusChannel;
import com.nt4f04uNd.player.channels.GeneralChannel;
import com.nt4f04uNd.player.channels.MediaButtonChannel;
import com.nt4f04uNd.player.channels.NotificationChannel;
import com.nt4f04uNd.player.channels.PlayerChannel;
import com.nt4f04uNd.player.channels.SongChannel;
import com.nt4f04uNd.player.handlers.*;
import com.nt4f04uNd.player.player.PlayerForegroundService;
import com.nt4f04uNd.player.player.Song;
import com.nt4f04uNd.player.receivers.*;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.IBinder;
import android.view.View;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;

import static android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
import static android.view.WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS;

// Method channel


public class MainActivity extends FlutterActivity {

    private IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

    private NotificationReceiver notificationReceiver = null;
    private BecomingNoisyReceiver noisyAudioStreamReceiver = null;

    private EventChannel eventChannel;
    // Other channels are wrapped into classes, so they are initialized in on create

    private PlayerForegroundService service;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        int nightModeFlags = getApplicationContext().getResources().getConfiguration().uiMode &
                Configuration.UI_MODE_NIGHT_MASK;

        switch (nightModeFlags) {
            case Configuration.UI_MODE_NIGHT_YES:
            case Configuration.UI_MODE_NIGHT_UNDEFINED:
                setTheme(R.style.LaunchThemeSystemUIDark);
                break;

            case Configuration.UI_MODE_NIGHT_NO:
                setTheme(R.style.LaunchThemeSystemUILight);
                break;
        }

        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);


        // Service
        // ----------------------------------------------------------------------------------
        Intent forService = new Intent(getApplicationContext(), PlayerForegroundService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(forService);
        } else {
            startService(forService);
        }

//        bindService(
//                new Intent(this, PlayerForegroundService.class),
//                serviceConnection,
//                Context.BIND_AUTO_CREATE
//        );



        // Setup handlers
        // ----------------------------------------------------------------------------------
//        PlayerHandler.init(getApplicationContext());
//        AudioFocusHandler.init(getApplicationContext());
//        MediaButtonHandler.init(getApplicationContext());
//        NotificationHandler.init(getApplicationContext());
        // ----------------------------------------------------------------------------------

        // Setup channels
        // ----------------------------------------------------------------------------------
        AudioFocusChannel.init(getFlutterView());
        MediaButtonChannel.init(getFlutterView());

        GeneralChannel.init(getFlutterView(), this);
        SongChannel.init(getFlutterView(), getApplicationContext());
        NotificationChannel.init(getFlutterView(), getApplicationContext());
        PlayerChannel.init(getFlutterView(), getApplicationContext());
        // ----------------------------------------------------------------------------------


        // Setup event channels
        // ----------------------------------------------------------------------------------
        eventChannel = new EventChannel(getFlutterView(), Constants.EVENT_CHANNEL_STREAM);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, final EventChannel.EventSink events) {
                notificationReceiver = new NotificationReceiver(events);
                noisyAudioStreamReceiver = new BecomingNoisyReceiver(events);
                registerReceiver(notificationReceiver, NotificationHandler.intentFilter);
                registerReceiver(noisyAudioStreamReceiver, noisyIntentFilter);

                MediaButtonHandler.turnActive();
            }

            @Override
            public void onCancel(Object args) {
                unregisterReceiver(notificationReceiver);
                unregisterReceiver(noisyAudioStreamReceiver);
            }
        });
        // ----------------------------------------------------------------------------------

    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    //https://stackoverflow.com/questions/23017767/communicate-with-foreground-service-android///
    /////////////////////////////////////////////////////////////////////////////////////////////
    private final ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
            service = ((PlayerForegroundService.LocalBinder) iBinder).getService();
            // now you have the instance of service.
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            service = null;
        }
    };

    @Override
    protected void onDestroy() {
        super.onDestroy();
        MediaButtonChannel.kill();
        NotificationChannel.kill();
        unregisterReceiver(notificationReceiver);
        unregisterReceiver(noisyAudioStreamReceiver);
    }
}

// TODO: probably? add launch intent broadcast receiver and get extra argument
// that denotes that activity has been opened from notification

// TODO: as I specify very big priority for mediabutton intent-filter, i should
// add handler to start music when media button gets clicked, but the application is
// not started