/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.player;

import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.Binder;
import android.os.IBinder;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;
import com.nt4f04uNd.player.handlers.NotificationHandler;
import com.nt4f04uNd.player.handlers.PlayerHandler;
import com.nt4f04uNd.player.receivers.BecomingNoisyReceiver;
import com.nt4f04uNd.player.receivers.NotificationReceiver;

import androidx.annotation.Nullable;
import io.flutter.Log;

public class PlayerForegroundService extends Service {

    public NotificationReceiver notificationReceiver;
    public BecomingNoisyReceiver noisyAudioStreamReceiver;
    private final IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);


    @Override
    public void onCreate() {
        super.onCreate();

        AudioFocusHandler.init();
        NotificationHandler.init();

        // Registering receivers
        notificationReceiver = new NotificationReceiver();
        noisyAudioStreamReceiver = new BecomingNoisyReceiver();
        registerReceiver(notificationReceiver, NotificationHandler.intentFilter);
        registerReceiver(noisyAudioStreamReceiver, noisyIntentFilter);


        // Initializing handlers
        //GeneralHandler.init(getApplicationContext(), null);

        //Song currentSong = PlaylistHandler.getCurrentSong();
        // Cancel
//        if (currentSong == null) {
//            stopSelf();
//        }
        Log.w(Constants.LogTag, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        // TODO: album update notification
        startForeground(
                100,
                NotificationHandler.getNotification(new Song(
                        0,
                        "t",
                        "f",
                        "f",
                        "f",
                        "f",
                        100,
                        100
                ), PlayerHandler.player.isActuallyPlaying()));

    }


    @Override
    public void onDestroy() {
        Log.w(Constants.LogTag, "DESTROYDESTROYDESTROYDESTROYDESTROYDESTROYDESTROYDESTROYDESTROYDESTROY");

        // Handlers
        // These two one may affect user interaction with other apps if I won't destroy them
        // Other handlers seem to be not necessary to clear them
        MediaButtonHandler.release();
        AudioFocusHandler.abandonFocus();

        // Receivers
        unregisterReceiver(notificationReceiver);
        unregisterReceiver(noisyAudioStreamReceiver);
        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.w(Constants.LogTag, "START COMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMAND");
        return super.onStartCommand(intent, flags, startId);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public class LocalBinder extends Binder {
        public PlayerForegroundService getService() {
            // Return this instance of LocalService so clients can call public methods
            return PlayerForegroundService.this;
        }
    }
}
