/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.player;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;

import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.nt4f04und.sweyer.handlers.PlayerHandler;

import java.io.IOException;
import android.util.Log;

/** Very wrapper over media player, quite raw */
public class Player implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

    private boolean looping = false;
    private Uri uri;
    private double volume = 1.0;
    private boolean stayAwake;
    private PlayerResourceState resourceState = PlayerResourceState.RELEASED;
    private boolean playing = false;
    private int shouldSeekTo = -1;

    private MediaPlayer player;

    protected static boolean objectEquals(Object o1, Object o2) {
        return o1 == null && o2 == null || o1 != null && o1.equals(o2);
    }

    public void setAwake(Context context, boolean stayAwake) {
        if (this.stayAwake != stayAwake) {
            this.stayAwake = stayAwake;
            if (resourceState != PlayerResourceState.RELEASED && this.stayAwake) {
                player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK);
            }
        }
    }

    /** Used to check cases when url is null (e.g. flutter hasn't setup it up for
     * some reason) */
    public boolean isUriNull() {
        return uri == null;
    }

    /** Playback handling methods*/

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
                player.setOnCompletionListener(this);
                PlayerHandler.startPositionUpdates();
            }
        }
    }

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
                release();
                setUri(uri);
                return;
            }

            resourceState = PlayerResourceState.PREPARING;
            setSource(GeneralHandler.getAppContext(), uri);
            player.setVolume((float) volume, (float) volume);
            player.setLooping(looping);
            player.prepareAsync();
        }
    }

    public void pause() {
        boolean wasPlaying = playing;
        playing = false;
        PlayerHandler.stopPositionUpdates();
        if (wasPlaying && resourceState == PlayerResourceState.PREPARED) {
            player.pause();
        }
    }

    public void stop() {
        pause();
        seek(0);
    }

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

    public void seek(int position) {
        if (resourceState == PlayerResourceState.PREPARED)
            player.seekTo(position);
        else
            shouldSeekTo = position;
    }


    public void setVolume(double volume) {
        if (this.volume != volume) {
            this.volume = volume;
            if (resourceState != PlayerResourceState.RELEASED) {
                player.setVolume((float) volume, (float) volume);
            }
        }
    }

    public void setLooping(boolean looping) {
        if (resourceState != PlayerResourceState.RELEASED) {
            this.looping = looping;
            player.setLooping(looping);
        }
    }

    public boolean isPlaying() {
        return playing && resourceState == PlayerResourceState.PREPARED;
    }

    public boolean isLooping() {
        return looping;
    }

    public double getVolume() {
        return volume;
    }

    public int getPosition() {
        if (player == null || resourceState != PlayerResourceState.PREPARED)
            return 0;
        return player.getCurrentPosition();
    }

    public int getDuration() {
        if (player == null || resourceState != PlayerResourceState.PREPARED)
            return 0;
        return player.getDuration();
    }


    /** MediaPlayer callbacks */

    @Override
    public void onPrepared(final MediaPlayer player) {
        resourceState = PlayerResourceState.PREPARED;
        if (playing) {
            player.start();
            player.setOnCompletionListener(this);
            PlayerHandler.startPositionUpdates();
        }
        if (shouldSeekTo >= 0) {
            player.seekTo(shouldSeekTo);
            PlayerHandler.notifyPositions();
            shouldSeekTo = -1;
        }
    }

    @Override
    public void onCompletion(final MediaPlayer player) {
        if (!looping) {
            stop();
        }
        PlayerHandler.handleCompletion();
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {
        //Invoked when there has been an error during an asynchronous operation
        switch (what) {
            case MediaPlayer.MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:
                Log.e("MediaPlayer Error", "MEDIA ERROR NOT VALID FOR PROGRESSIVE PLAYBACK " + extra);
                break;
            case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                Log.e("MediaPlayer Error", "MEDIA ERROR SERVER DIED " + extra);
                break;
            case MediaPlayer.MEDIA_ERROR_UNKNOWN:
                Log.e("MediaPlayer Error", "MEDIA ERROR UNKNOWN " + extra);
                break;
        }
        PlayerHandler.handleError(new Exception("" + what));
        return true;
    }

    /** Internal logic, private methods */

    private MediaPlayer createPlayer() {
        MediaPlayer player = new MediaPlayer();
        player.setOnPreparedListener(this);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            player.setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build());
        } else {
            // This method is deprecated but must be used on older devices
            player.setAudioStreamType(AudioManager.STREAM_MUSIC);
        }

        player.setVolume((float) volume, (float) volume);
        player.setLooping(looping);
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
