/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.IBinder;

import com.nt4f04uNd.sweyer.handlers.AudioFocusHandler;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.handlers.MediaSessionHandler;
import com.nt4f04uNd.sweyer.handlers.NotificationHandler;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;
import com.nt4f04uNd.sweyer.handlers.PlaylistHandler;
import com.nt4f04uNd.sweyer.handlers.PrefsHandler;
import com.nt4f04uNd.sweyer.receivers.BecomingNoisyReceiver;
import com.nt4f04uNd.sweyer.receivers.NotificationReceiver;

import androidx.annotation.Nullable;

public class PlayerForegroundService extends Service {


    public static boolean isRunning = false;

    private NotificationReceiver notificationReceiver;
    private BecomingNoisyReceiver noisyAudioStreamReceiver;
    private final IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

    @Override
    public void onCreate() {
        super.onCreate();

        isRunning = true;

        PlaylistHandler.initCurrentSong();
        if(!GeneralHandler.activityExists() && PrefsHandler.getSongIsPlaying()){
            // Start playing if flag is playing is set to true
            // This is just a handling for sticky service
            PlayerHandler.playPause();
        }

        // Initializing handlers
        GeneralHandler.init(getApplicationContext());
        PlayerHandler.init();
        AudioFocusHandler.init();
        NotificationHandler.init();
        MediaSessionHandler.init();

        // Registering receivers
        notificationReceiver = new NotificationReceiver();
        noisyAudioStreamReceiver = new BecomingNoisyReceiver();
        registerReceiver(notificationReceiver, NotificationHandler.intentFilter);
        registerReceiver(noisyAudioStreamReceiver, noisyIntentFilter);

        if (PlaylistHandler.getCurrentSong() != null)
            startForeground(
                    NotificationHandler.NOTIFICATION_ID,
                    NotificationHandler.getNotification(PlayerHandler.isPlaying(), PlayerHandler.isLooping())
            );
        else stopSelf();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return intent.getIntExtra("STICKINESS", Service.START_NOT_STICKY);
    }


    @Override
    public void onDestroy() {
        isRunning = false;

        // Handlers
        // These two one may affect user interaction with other apps if I won't destroy them
        // Other handlers seem to be not necessary to clear them
        AudioFocusHandler.abandonFocus();
        PlaylistHandler.resetPlaylist();
        MediaSessionHandler.release();

        // Receivers
        unregisterReceiver(notificationReceiver);
        unregisterReceiver(noisyAudioStreamReceiver);
        super.onDestroy();
    }

    @Override
    public void onTrimMemory(int level) {
        PlaylistHandler.resetPlaylist();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
