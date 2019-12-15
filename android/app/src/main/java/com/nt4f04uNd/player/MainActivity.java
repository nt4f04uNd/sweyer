/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player;

import com.nt4f04uNd.player.channels.GeneralChannel;
import com.nt4f04uNd.player.channels.NativeEventsChannel;
import com.nt4f04uNd.player.channels.PlayerChannel;
import com.nt4f04uNd.player.channels.ServiceChannel;
import com.nt4f04uNd.player.channels.SongChannel;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;
import com.nt4f04uNd.player.handlers.GeneralHandler;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;
import com.nt4f04uNd.player.handlers.PlayerHandler;
import com.nt4f04uNd.player.handlers.PlaylistHandler;
import com.nt4f04uNd.player.handlers.ServiceHandler;
import com.nt4f04uNd.player.player.PlayerForegroundService;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import android.os.IBinder;

// Method channel


public class MainActivity extends FlutterActivity {

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
        GeneralHandler.init(getApplicationContext(), this); // The most important, as it contains app context
        // ----------------------------------------------------------------------------------

        // Setup channels
        // ----------------------------------------------------------------------------------
        GeneralChannel.init(getFlutterView(), this); // Inits general channel
        PlaylistHandler.init(); // TODO: remove

        AudioFocusHandler.init();
        NativeEventsChannel.init(getFlutterView()); // Inits event channel
        PlayerHandler.init(); // Inits player instance
        PlayerChannel.init(getFlutterView()); // Inits player channel
        MediaButtonHandler.init();
        ServiceHandler.init(); // Contains intent to start service
       // ServiceHandler.startService();
        ServiceChannel.init(getFlutterView());
        SongChannel.init(getFlutterView());
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
        NativeEventsChannel.kill();
        GeneralChannel.kill();
        PlayerChannel.kill();
        SongChannel.kill();
        ServiceChannel.kill();
    }
}

// TODO: probably? add launch intent broadcast receiver and get extra argument
// that denotes that activity has been opened from notification

// TODO: as I specify very big priority for mediabutton intent-filter, i should
// add handler to start music when media button gets clicked, but the application is
// not started