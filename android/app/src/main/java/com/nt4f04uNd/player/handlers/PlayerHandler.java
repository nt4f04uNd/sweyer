/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.os.Handler;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.MediaButtonChannel;
import com.nt4f04uNd.player.channels.PlayerChannel;
import com.nt4f04uNd.player.player.Player;
import com.nt4f04uNd.player.player.ReleaseMode;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public abstract class PlayerHandler {

    public static void init(Context appContext) {
        if (player == null) {
            player = new Player();
            PlayerHandler.appContext = appContext;
        }
    }

    public static Player player;
    private static final Handler handler = new Handler();
    private static Runnable positionUpdates;
    private static Context appContext;

    // HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static void handleIsPlaying() {
        startPositionUpdates();
    }

    public static void handleDuration(Player player) {
        PlayerChannel.channel.invokeMethod("audio.onDuration", buildArguments(player.getDuration()));
    }

    public static void handleCompletion(Player player) {
        PlayerChannel.channel.invokeMethod("audio.onComplete", buildArguments(true));
    }
    // END OF HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////


    // COMPOSED METHODS //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static void play(String url, double volume, Integer position, boolean respectSilence, boolean isLocal, boolean stayAwake) {
        player.configAttributes(respectSilence, stayAwake, appContext);
        player.setVolume(volume);
        player.setUrl(url, isLocal);
        if (position != null)
            PlayerHandler.player.seek(position);
        player.play();
    }

    public static void resume() {
        player.play();
    }

    public static void pause() {
        player.pause();
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

    public static boolean isPlaying() {
        return player.isActuallyPlaying();
    }
    // END OF COMPOSED METHODS ///////////////////////////////////////////////////////////////////////////////////



    // MESSED METHODS /////////////////////////////////////////////////////////////////////////////////////////////
    private static Map<String, Object> buildArguments(Object value) {
        Map<String, Object> result = new HashMap<>();
        result.put("playerId", "0");
        result.put("value", value);
        return result;
    }

    private static void startPositionUpdates() {
        if (positionUpdates != null)
            return;
        positionUpdates = new UpdateCallback(PlayerChannel.channel, handler);
        handler.post(positionUpdates);
    }

    private static void stopPositionUpdates() {
        positionUpdates = null;
        handler.removeCallbacksAndMessages(null);
    }

    // TODO: refactor
    private static final class UpdateCallback implements Runnable {

        private final WeakReference<MethodChannel> channel;
        private final WeakReference<Handler> handler;

        private UpdateCallback(
                final MethodChannel channel,
                final Handler handler) {
            this.channel = new WeakReference<>(channel);
            this.handler = new WeakReference<>(handler);
        }

        @Override
        public void run() {
            final MethodChannel channel = this.channel.get();
            final Handler handler = this.handler.get();

            if (channel == null || handler == null) {
                stopPositionUpdates();
                return;
            }

            try {
                final int duration = player.getDuration();
                final int time = player.getCurrentPosition();
                channel.invokeMethod("audio.onDuration", buildArguments(duration));
                channel.invokeMethod("audio.onCurrentPosition", buildArguments(time));
            } catch (UnsupportedOperationException e) {
                // TODO: add error handling
            }

            stopPositionUpdates();
        }
    }
    // END OF MESSED METHODS //////////////////////////////////////////////////////////////////////////////////////////////////
}
