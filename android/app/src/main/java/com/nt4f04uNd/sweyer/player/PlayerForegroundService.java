/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.Binder;
import android.os.IBinder;

import com.nt4f04uNd.sweyer.handlers.AudioFocusHandler;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.handlers.MediaButtonHandler;
import com.nt4f04uNd.sweyer.handlers.NotificationHandler;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;
import com.nt4f04uNd.sweyer.handlers.PlaylistHandler;
import com.nt4f04uNd.sweyer.handlers.PrefsHandler;
import com.nt4f04uNd.sweyer.receivers.BecomingNoisyReceiver;
import com.nt4f04uNd.sweyer.receivers.NotificationReceiver;

import androidx.annotation.Nullable;

public class PlayerForegroundService extends Service {

    private NotificationReceiver notificationReceiver;
    private BecomingNoisyReceiver noisyAudioStreamReceiver;
    private final IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

    @Override
    public void onCreate() {
        super.onCreate();

        // Initializing handlers
        GeneralHandler.init(getApplicationContext());
        AudioFocusHandler.init();
        NotificationHandler.init();
        MediaButtonHandler.init();

        // Registering receivers
        notificationReceiver = new NotificationReceiver();
        noisyAudioStreamReceiver = new BecomingNoisyReceiver();
        registerReceiver(notificationReceiver, NotificationHandler.intentFilter);
        registerReceiver(noisyAudioStreamReceiver, noisyIntentFilter);

        // Handle case when playingSong is null
        // This can be considered as case when activity did not start (or didn't call send song method for some reason, e.g. songs list is empty)
        //
        if (PlaylistHandler.playingSong == null) {
            PlaylistHandler.getLastPlaylist();
            PlaylistHandler.playingSong = PlaylistHandler.searchById((int)PrefsHandler.getSongId());
        }

        if (PlaylistHandler.playingSong != null)
            startForeground(
                    NotificationHandler.NOTIFICATION_ID,
                    NotificationHandler.getNotification(PlaylistHandler.playingSong, PlayerHandler.isPlaying())
            );
        else stopSelf();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // If we get killed, after returning from here, restart
        return START_STICKY;
    }


    @Override
    public void onDestroy() {
        // Handlers
        // These two one may affect user interaction with other apps if I won't destroy them
        // Other handlers seem to be not necessary to clear them
        AudioFocusHandler.abandonFocus();
        PlaylistHandler.resetPlaylist();

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

    public class LocalBinder extends Binder {
        public PlayerForegroundService getService() {
            // Return this instance of LocalService so clients can call public methods
            return PlayerForegroundService.this;
        }
    }
}
