/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.media.AudioManager;
import android.os.Handler;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.PlayerChannel;
import com.nt4f04uNd.player.player.Player;
import com.nt4f04uNd.player.player.PlayerState;
import com.nt4f04uNd.player.player.ReleaseMode;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public abstract class PlayerHandler {

    public static void init() {
        if (player == null)
            player = new Player();

    }

    public static Player player;
    private static final Handler handler = new Handler();
    private static Runnable positionUpdates;

    // HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Builds arguments to send them to PlayerChannel
     */
    private static Map<String, Object> buildArguments(Object value) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("value", value);
        return arguments;
    }

    public static void handleDuration(Player player) {
        PlayerChannel.invokeMethod("audio.onDuration", buildArguments(player.getDuration()));
    }

    public static void handleCompletion() {
        PlayerChannel.invokeMethod("audio.onComplete", buildArguments(true));
    }

    public static void handleError(Exception e) {
        PlayerChannel.invokeMethod("audio.onError", buildArguments(e));
    }

    public static void callSetState(PlayerState state) {
        switch (state) {
            case PLAYING:
                PlayerChannel.invokeMethod("audio.state.set", buildArguments("PLAYING"));
                break;
            case PAUSED:
                PlayerChannel.invokeMethod("audio.state.set", buildArguments("PAUSED"));
                break;
            case STOPPED:
                PlayerChannel.invokeMethod("audio.state.set", buildArguments("STOPPED"));
                break;
            default:
                break;
        }

    }

    /**
     * Called from music player instance whenever music starts
     */
    public static void handleStartPlaying() {
        startPositionUpdates();
    }

    /**
     * Called from music player instance whenever music stops
     */
    public static void handleStopPlaying() {
        stopPositionUpdates();
    }
    // END OF HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////


    // COMPOSED METHODS //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static void play(String url, double volume, Integer position, boolean respectSilence, boolean isLocal, boolean stayAwake) {
        player.configAttributes(respectSilence, stayAwake, GeneralHandler.getAppContext());
        player.setVolume(volume);
        player.setUrl(url, isLocal);
        if (position != null)
            PlayerHandler.player.seek(position);

        resume();
    }

    public static void resume() {
        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN)
            player.play();
    }

    public static void pause() {
        player.pause();
        AudioFocusHandler.abandonFocus();
    }

    public static void stop() {
        player.stop();
    }

    public static void release() {
        player.release();
    }

    public static void seek(Integer position) {
        PlayerHandler.player.seek(position);
    }

    public static void setVolume(double volume) {
        player.setVolume(volume);
    }

    public static void setUrl(String url, boolean isLocal) {
        player.setUrl(url, isLocal);
    }

    public static double getVolume() {
        return player.getVolume();
    }

    public static int getDuration() {
        return player.getDuration();
    }

    public static int getCurrentPosition() {
        return player.getCurrentPosition();
    }

    public static void setReleaseMode(ReleaseMode releaseMode) {
        player.setReleaseMode(releaseMode);
    }

    public static boolean isLooping() {
        return player.getReleaseMode().equals(ReleaseMode.LOOP);
    }
    // END OF COMPOSED METHODS ///////////////////////////////////////////////////////////////////////////////////

    // HANDLER METHODS /////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Starts handler
     */
    private static void startPositionUpdates() {
        if (positionUpdates != null)
            return;
        positionUpdates = new UpdateCallback(PlayerChannel.channel, handler);
        handler.post(positionUpdates);
    }

    /**
     * Stops handler
     */
    private static void stopPositionUpdates() {
        positionUpdates = null;
        handler.removeCallbacksAndMessages(null);
    }

    private static final class UpdateCallback implements Runnable {

        private final WeakReference<MethodChannel> channel;
        private final WeakReference<Handler> handler;

        private UpdateCallback(final MethodChannel channel, final Handler handler) {
            this.channel = new WeakReference<>(channel);
            this.handler = new WeakReference<>(handler);
        }

        @Override
        public void run() {
            final MethodChannel channel = this.channel.get();

            if (channel == null || this.handler.get() == null) {
                stopPositionUpdates();
                return;
            }

            try {
                final int time = player.getCurrentPosition();
                channel.invokeMethod("audio.onCurrentPosition", buildArguments(time));
            } catch (UnsupportedOperationException e) {
                handleError(e);
            } finally {
                handler.get().postDelayed(this, Constants.player.POSITION_UPDATE_PERIOD_MS);
            }
        }
    }
    // END OF HANDLER METHODS //////////////////////////////////////////////////////////////////////////////////////////////////
}
