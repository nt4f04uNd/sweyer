/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer;

import com.nt4f04uNd.sweyer.channels.GeneralChannel;
import com.nt4f04uNd.sweyer.channels.NativeEventsChannel;
import com.nt4f04uNd.sweyer.channels.PlayerChannel;
import com.nt4f04uNd.sweyer.channels.ServiceChannel;
import com.nt4f04uNd.sweyer.channels.SongChannel;
import com.nt4f04uNd.sweyer.handlers.AudioFocusHandler;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.handlers.MediaButtonHandler;
import com.nt4f04uNd.sweyer.handlers.NotificationHandler;
import com.nt4f04uNd.sweyer.handlers.PlaylistHandler;
import com.nt4f04uNd.sweyer.handlers.ServiceHandler;

import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        // Setup handlers
        // ----------------------------------------------------------------------------------
        PlaylistHandler.resetPlaylist();
        GeneralHandler.init(getApplicationContext()); // The most important, as it contains app context
        GeneralChannel.init(getFlutterView(), this); // Inits general channel
        NotificationHandler.init();
        AudioFocusHandler.init();
        NativeEventsChannel.init(getFlutterView()); // Inits event channel
        PlayerChannel.init(getFlutterView()); // Inits player channel
        MediaButtonHandler.init();
        ServiceHandler.init(); // Contains intent to start service
        ServiceChannel.init(getFlutterView());
        SongChannel.init(getFlutterView());
        // ----------------------------------------------------------------------------------
    }

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