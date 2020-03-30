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

import com.nt4f04uNd.sweyer.handlers.GeneralHandler;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;

import java.io.IOException;

/**
 * Basic wrapper over media player, very raw
 */
public class Player extends PlayerAbstract implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    // TODO: logging
    // private Logger LOGGER = Logger.getLogger(Player.class.getCanonicalName());

    private Uri uri;
    private double volume = 1.0;
    private boolean stayAwake;
    private ReleaseMode releaseMode = ReleaseMode.RELEASE;
    private PlayerResourceState resourceState = PlayerResourceState.RELEASED;
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
            if (resourceState == PlayerResourceState.RELEASED) {
                player = createPlayer();
                resourceState = PlayerResourceState.IDLE;
            } else if (resourceState == PlayerResourceState.PREPARED) {
                player.reset();
                resourceState = PlayerResourceState.IDLE;
            } else if (resourceState == PlayerResourceState.PREPARING) {
                // TODO: this is probably a bad idea to release it like that, because docs are silent about calling release during preparing stage
                release();
                setUri(uri);
                return;
            }

            setSource(GeneralHandler.getAppContext(), uri);
            player.setVolume((float) volume, (float) volume);
            player.setLooping(releaseMode == ReleaseMode.LOOP);
            player.prepareAsync();
            resourceState = PlayerResourceState.PREPARING;

        }
    }

    @Override
    public void setVolume(double volume) {
        if (this.volume != volume) {
            this.volume = volume;
            if (resourceState != PlayerResourceState.RELEASED) {
                player.setVolume((float) volume, (float) volume);
            }
        }
    }

    @Override
    public void setAwake(Context context, boolean stayAwake) {
        if (this.stayAwake != stayAwake) {
            this.stayAwake = stayAwake;
            if (resourceState != PlayerResourceState.RELEASED && this.stayAwake) {
                player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK);
            }
        }
    }

    @Override
    public void setReleaseMode(ReleaseMode releaseMode) {
        if (this.releaseMode != releaseMode) {
            this.releaseMode = releaseMode;
            if (resourceState != PlayerResourceState.RELEASED) {
               player.setLooping(releaseMode == ReleaseMode.LOOP);
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
        if (player == null || resourceState != PlayerResourceState.PREPARED)
            return 0;
        return player.getDuration();
    }

    @Override
    public int getCurrentPosition() {
        if (player == null || resourceState != PlayerResourceState.PREPARED)
            return 0;
        return player.getCurrentPosition();
    }

    @Override
    public ReleaseMode getReleaseMode() {
        return releaseMode;
    }

    @Override
    public boolean isActuallyPlaying() {
        return playing && resourceState == PlayerResourceState.PREPARED;
    }

    /**
     * Used to check cases when url is null (e.g. flutter hasn't setup it up for
     * some reason)
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
        if (!playing) {
            playing = true;
            if (resourceState == PlayerResourceState.RELEASED) {
                player = createPlayer();
                setSource(appContext, uri);
                player.prepareAsync();
                resourceState = PlayerResourceState.PREPARING;
            } else if (resourceState == PlayerResourceState.PREPARED) {
                player.start();
                PlayerHandler.startPositionUpdates();
            }
        }
    }

    @Override
    public void stop() {
        if (resourceState == PlayerResourceState.RELEASED) {
            return;
        }

        PlayerHandler.stopPositionUpdates();
        if (releaseMode != ReleaseMode.RELEASE) {
            if (playing) {
                playing = false;
                player.pause();
                player.seekTo(0);
            }
        } else {
            release();
        }
    }

    @Override
    public void release() {
        if (resourceState == PlayerResourceState.RELEASED) {
            return;
        }

        if (playing && resourceState != PlayerResourceState.PREPARING) {
            player.stop();
            PlayerHandler.stopPositionUpdates();
        }
        player.reset();
        player.release();
        player = null;

        resourceState = PlayerResourceState.RELEASED;
        playing = false;
    }

    @Override
    public void pause() {
        if (playing) {
            PlayerHandler.stopPositionUpdates();
            playing = false;
            player.pause();
        }
    }

    // Seek operations cannot be called until after
    // the player is ready.
    @Override
    public void seek(int position) {
        if (resourceState == PlayerResourceState.PREPARED)
            player.seekTo(position);
        else
            shouldSeekTo = position;
    }

    /**
     * MediaPlayer callbacks
     */

    @Override
    public void onPrepared(final MediaPlayer mediaPlayer) {
        resourceState = PlayerResourceState.PREPARED;
        PlayerHandler.handleDuration(this);
        if (playing) {
            mediaPlayer.start();
            PlayerHandler.startPositionUpdates();
        }
        if (shouldSeekTo >= 0) {
            mediaPlayer.seekTo(shouldSeekTo);
            shouldSeekTo = -1;
        }
    }

    @Override
    public void onCompletion(final MediaPlayer mediaPlayer) {
        if (releaseMode != ReleaseMode.LOOP) {
            stop();
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
            player.setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build());
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
            player.setDataSource(appContext, uri);
        } catch (IOException e) {
            throw new RuntimeException("Unable to access resource", e);
        }
    }

}
