/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.player;

import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Binder;
import android.os.IBinder;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.MediaButtonChannel;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;
import com.nt4f04uNd.player.handlers.NotificationHandler;
import com.nt4f04uNd.player.handlers.PlayerHandler;
import com.nt4f04uNd.player.handlers.SerializationHandler;

import java.util.ArrayList;

import androidx.annotation.Nullable;
import io.flutter.Log;

public class PlayerForegroundService extends Service {

    ArrayList<Song> songs;
    int playingSongIdx = 0;

    @Override
    public void onCreate() {
        super.onCreate();

        SerializationHandler.init(getApplicationContext());
        songs = SerializationHandler.getPlaylistSongs();

        PlayerHandler.init(getApplicationContext());

        AudioFocusHandler.init(getApplicationContext()); // TODO: handle audio focus this

        MediaButtonHandler.init(getApplicationContext());
        MediaButtonHandler.addListener(new ImplementedOnMediaButtonListener());

        NotificationHandler.init(getApplicationContext());

        String title;
        String artist;

        if (songs.size() > 0) {
            title = songs.get(playingSongIdx).title;
            artist = songs.get(playingSongIdx).artist;
        } else {
            title = "Empty";
            artist = "Empty";
        }

        // TODO: album art
        startForeground(100, NotificationHandler.getForegroundNotification(title, artist, new byte[0], PlayerHandler.isPlaying()));
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
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


    private int getNextSongIdx() {
        return playingSongIdx + 1 > songs.size() - 1 ? 0 : playingSongIdx + 1;
    }

    private int getPrevSongIdx() {
        return playingSongIdx - 1 < 0 ? songs.size() - 1 : playingSongIdx - 1;
    }


    private class ImplementedOnMediaButtonListener extends com.nt4f04uNd.player.handlers.OnMediaButtonListener {

        @Override
        protected void onAudioTrack() {
            playingSongIdx = getNextSongIdx();
            PlayerHandler.play(songs.get(playingSongIdx).trackUri, PlayerHandler.getVolume(), 0, false, true, true);
        }

        @Override
        protected void onFastForward() {
            PlayerHandler.seek(PlayerHandler.getCurrentPosition() + 3000);
        }

        @Override
        protected void onRewind() {
            PlayerHandler.seek(PlayerHandler.getCurrentPosition() - 3000);
        }

        @Override
        protected void onNext() {
            playingSongIdx = getNextSongIdx();
            PlayerHandler.play(songs.get(playingSongIdx).trackUri, PlayerHandler.getVolume(), 0, false, true, true);
        }

        @Override
        protected void onPrevious() {
            playingSongIdx = getPrevSongIdx();
            PlayerHandler.play(songs.get(playingSongIdx).trackUri, PlayerHandler.getVolume(), 0, false, true, true);
        }

        @Override
        protected void onPlayPause() {
            if (PlayerHandler.isPlaying())
                PlayerHandler.pause();
            else PlayerHandler.resume();
        }

        @Override
        protected void onPlay() {
            PlayerHandler.resume();
        }

        @Override
        protected void onStop() {
            PlayerHandler.pause();
        }

        @Override
        protected void onHook() {
            // TODO: implement
            Log.w(Constants.LogTag, "HOOK PRESS");
        }
    }
}
