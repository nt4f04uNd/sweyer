/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;

import java.io.IOException;

import io.flutter.Log;

/**
 * Basic wrapper over media player, very raw
 */
public class Player extends PlayerAbstract implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    // TODO: logging
    //private Logger LOGGER = Logger.getLogger(Player.class.getCanonicalName());

//    public Player(Context appContext) {
//        PowerManager powerManager = (PowerManager) appContext.getSystemService(Context.POWER_SERVICE);
//        PowerManager.WakeLock wl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":wakeLockTag");
//       // wl.acquire();
//  // ..screen will stay on during this section..
////     / /  wl.release();
//
//    }

    private Uri uri;
    private double volume = 1.0;
    private boolean respectSilence;
    private boolean stayAwake;
    private ReleaseMode releaseMode = ReleaseMode.RELEASE;
    private boolean released = true;
    private boolean prepared = false;
    private boolean playing = false;

    private int shouldSeekTo = -1;

    private MediaPlayer player;

    /**
     * Setter methods
     */


    /**
     * NOTE THAT THIS CAN THROW ILLEGAL STATE EXCEPTION
     */
    public void setUri(Uri uri) {
        if (!objectEquals(this.uri, uri)) {
            this.uri = uri;
            if (this.released) {
                this.player = createPlayer();
                this.released = false;
            } else if (this.prepared) {
                this.player.reset();
                this.prepared = false;
            }

            this.setSource(GeneralHandler.getAppContext(), uri);
            this.player.setVolume((float) volume, (float) volume);
            this.player.setLooping(this.releaseMode == ReleaseMode.LOOP);
            this.player.prepareAsync();

        }
    }


    @Override
    public void setVolume(double volume) {
        if (this.volume != volume) {
            this.volume = volume;
            if (!this.released) {
                this.player.setVolume((float) volume, (float) volume);
            }
        }
    }

    @Override
    public void setAwake(Context context, boolean stayAwake) {
        if (this.stayAwake != stayAwake) {
            this.stayAwake = stayAwake;
            if (!this.released && this.stayAwake) {
                this.player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK);
            }
        }
    }

    @Override
    public void setReleaseMode(ReleaseMode releaseMode) {
        if (this.releaseMode != releaseMode) {
            this.releaseMode = releaseMode;
            if (!this.released) {
                this.player.setLooping(releaseMode == ReleaseMode.LOOP);
            }
        }
    }


    /**
     * Getter methods
     */

    @Override
    public double getVolume() {
        return volume;
    }

    @Override
    public int getDuration() {
        return this.player.getDuration();
    }

    @Override
    public int getCurrentPosition() {
        return this.player.getCurrentPosition();
    }

    @Override
    public ReleaseMode getReleaseMode() {
        return this.releaseMode;
    }

    @Override
    public boolean isActuallyPlaying() {
        return this.playing && this.prepared;
    }

    /**
     * Used to check cases when url is null (e.g. flutter hasn't setup it up for some reason)
     */
    @Override
    public boolean isUriNull() {
        return uri == null;
    }


    /**
     * Playback handling methods
     */

    @Override
    public void play(Context appContext) {
        if (!this.playing) {
            this.playing = true;
            if (this.released) {
                this.released = false;
                this.player = createPlayer();
                this.setSource(appContext, uri);
                this.player.prepareAsync();
            } else if (this.prepared) {
                this.player.start();
                PlayerHandler.startPositionUpdates();
            }
        }
    }

    @Override
    public void stop() {
        if (this.released) {
            return;
        }

        PlayerHandler.stopPositionUpdates();
        if (releaseMode != ReleaseMode.RELEASE) {
            if (this.playing) {
                this.playing = false;
                this.player.pause();
                this.player.seekTo(0);
            }
        } else {
            this.release();
        }
    }

    @Override
    public void release() {
        if (this.released) {
            return;
        }

        if (this.playing) {
            this.player.stop();
        }
        this.player.reset();
        this.player.release();
        this.player = null;

        this.prepared = false;
        this.released = true;
        this.playing = false;
    }

    @Override
    public void pause() {
        if (this.playing) {
            PlayerHandler.stopPositionUpdates();
            this.playing = false;
            this.player.pause();
        }
    }

    // seek operations cannot be called until after
    // the player is ready.
    @Override
    public void seek(int position) {
        if (this.prepared)
            this.player.seekTo(position);
        else
            this.shouldSeekTo = position;
    }


    /**
     * MediaPlayer callbacks
     */

    @Override
    public void onPrepared(final MediaPlayer mediaPlayer) {
        this.prepared = true;
        PlayerHandler.handleDuration(this);
        if (this.playing) {
            mediaPlayer.start();
            PlayerHandler.startPositionUpdates();
        }
        if (this.shouldSeekTo >= 0) {
            mediaPlayer.seekTo(this.shouldSeekTo);
            this.shouldSeekTo = -1;
        }
    }

    @Override
    public void onCompletion(final MediaPlayer mediaPlayer) {
        if (releaseMode != ReleaseMode.LOOP) {
            this.stop();
        }
        PlayerHandler.handleCompletion();
    }


    /**
     * Internal logic. Private methods
     */

    private MediaPlayer createPlayer() {
        MediaPlayer player = new MediaPlayer();
        player.setOnPreparedListener(this);
        player.setOnCompletionListener(this);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            player.setAudioAttributes(new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            );
        } else {
            // This method is deprecated but must be used on older devices
            player.setAudioStreamType(AudioManager.STREAM_MUSIC);
        }

        player.setVolume((float) volume, (float) volume);
        player.setLooping(this.releaseMode == ReleaseMode.LOOP);
        return player;
    }

    private void setSource(Context appContext, Uri uri) {
        try {
            this.player.setDataSource(appContext, uri);
        } catch (IOException e) {
            throw new RuntimeException("Unable to access resource", e);
        }
    }

}
