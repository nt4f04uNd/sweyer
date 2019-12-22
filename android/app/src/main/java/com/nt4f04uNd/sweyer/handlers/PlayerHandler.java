/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.media.AudioManager;
import android.os.Handler;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.channels.PlayerChannel;
import com.nt4f04uNd.sweyer.player.Player;
import com.nt4f04uNd.sweyer.player.PlayerState;
import com.nt4f04uNd.sweyer.player.ReleaseMode;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public abstract class PlayerHandler { // TODO: add error handling and logging

    public static Player player = new Player();
    private static final Handler handler = new Handler();
    private static Runnable positionUpdates;
    private static Integer lastSavedPosition;

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
        // Handle completion when activity is killed
        if (!GeneralHandler.activityExists()) {
            if (!isLooping()) {
                playNext();
            }
            // Do nothing if player is looping
        }
    }

    public static void handleError(Exception e) {
        PlayerChannel.invokeMethod("audio.onError", buildArguments(e));
    }

    public static void handleHookButton() {
//        long msTimestamp = System.currentTimeMillis()/1000;
//
        // TODO: implement
        io.flutter.Log.w(Constants.LogTag, "HOOK PRESS");
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
            case COMPLETED: // Deprecated to call is directly
                PlayerChannel.invokeMethod("audio.state.set", buildArguments("COMPLETED"));
                break;
            default:
                break;
        }

    }
    // END OF HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////


    // COMPOSED METHODS (wrappers over default player methods) /////////////////////////////////////////////////////////////// // TODO: remove respect silence islocal and stayawake
    public static void play(@NotNull Song song, double volume, Integer position, boolean respectSilence, boolean isLocal, boolean stayAwake) {
        ServiceHandler.startService();
        player.configAttributes(respectSilence, stayAwake, GeneralHandler.getAppContext());
        player.setVolume(volume);
        player.setUrl(song.trackUri, isLocal);
        if (position != null)
            PlayerHandler.player.seek(position);

        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN) {
            player.play();
            PlayerHandler.callSetState(PlayerState.PLAYING);
            NotificationHandler.updateNotification(song, true);
            PlaylistHandler.playingSong = song;
            PrefsHandler.setSongId(song.id);
            GeneralHandler.print(String.valueOf(PrefsHandler.getSongId()));
        }
    }

    public static void resume() {
        ServiceHandler.startService();
        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN) {
            bareResume();
        }
    }

    public static void pause() {
        barePause();
        AudioFocusHandler.abandonFocus();
    }

    public static void stop() {
        bareStop();
        AudioFocusHandler.abandonFocus();
    }

    public static void release() {
        bareRelease();
        AudioFocusHandler.abandonFocus();
    }

    public static void seek(Integer position) {
        PlayerHandler.player.seek(position);
    }

    public static void rewind() {
        PlayerHandler.player.seek(PlayerHandler.getCurrentPosition() - 3000);
    }

    public static void fastForward() {
        PlayerHandler.player.seek(PlayerHandler.getCurrentPosition() + 3000);
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

    public static boolean isLooping() {
        return player.getReleaseMode().equals(ReleaseMode.LOOP);
    }
    // END OF COMPOSED METHODS ///////////////////////////////////////////////////////////////////////////////////


    /// BARE METHODS (they do all stuff, just do not care about audio focus) ///////////////////////////////////

    /**
     * Normal resume function, it just doesn't care about handling audio focus
     */
    public static void bareResume() {
        player.play();
        PrefsHandler.setSongIsPlaying(true);
        PlayerHandler.callSetState(PlayerState.PLAYING);
        NotificationHandler.updateNotification(PlaylistHandler.playingSong, true);
    }

    public static void barePause() {
        player.pause();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.PAUSED);
        NotificationHandler.updateNotification(PlaylistHandler.playingSong, false);
    }

    public static void bareStop() {
        player.stop();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.STOPPED);
        // TODO: maybe remove notification at all?
        NotificationHandler.updateNotification(PlaylistHandler.playingSong, false);
    }

    public static void bareRelease() {
        player.release();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.STOPPED);
        // TODO: maybe remove notification at all?
        NotificationHandler.updateNotification(PlaylistHandler.playingSong, false);
    }
    /// END OF BARE METHODS ////////////////////////////////////////////////////////////////////////


    // SONG METHODS (add more extended playback handling) //////////////////////////////////////////////

    public static void playPause() {
        if (PlayerHandler.isPlaying())
            PlayerHandler.pause();
        else PlayerHandler.resume();
        PlayerHandler.play(PlaylistHandler.getPrevSong(), PlayerHandler.getVolume(), 0, false, true, true);
    }

    public static void playNext() {
        if (!GeneralHandler.activityExists()) {
            PlaylistHandler.getLastPlaylist();
            PlayerHandler.play(PlaylistHandler.getNextSong(), PlayerHandler.getVolume(), 0, false, true, true);
        }
    }

    public static void playPrev() {
        if (!GeneralHandler.activityExists()) {
            PlaylistHandler.getLastPlaylist();
            PlayerHandler.play(PlaylistHandler.getPrevSong(), PlayerHandler.getVolume(), 0, false, true, true);
        }
    }

    // END OF SONG METHODS ///////////////////////////////////////////////////////////////////////////////////


    // HANDLER METHODS /////////////////////////////////////////////////////////////////////////////////////////////


    /**
     * Starts handler
     * Called from music player instance whenever music starts to start position updates streaming
     */
    public static void startPositionUpdates() {
        if (positionUpdates != null)
            return;
        positionUpdates = new UpdateCallback(PlayerChannel.channel, handler);
        handler.post(positionUpdates);
    }


    /**
     * Stops handler
     * Called from music player instance whenever music stops to stop position updates streaming
     */
    public static void stopPositionUpdates() {
        positionUpdates = null;
        handler.removeCallbacksAndMessages(null);
    }

    /** Callback that is passed to handler to have a stream of position updates */
    private static final class UpdateCallback implements Runnable {
        private final WeakReference<Handler> handlerRef;

        private UpdateCallback(final MethodChannel channel, final Handler handler) {
            this.handlerRef = new WeakReference<>(handler);
        }

        @Override
        public void run() {
            final Handler handler = this.handlerRef.get();

            if (handler == null) {
                stopPositionUpdates();
                return;
            }

            try {
                final int currentPosition = player.getCurrentPosition();
                // convert to seconds
                PrefsHandler.setSongPosition(currentPosition / 1000);
                PlayerChannel.invokeMethod("audio.onCurrentPosition", buildArguments(currentPosition));
            } catch (UnsupportedOperationException e) {
                handleError(e);
            } finally {
                handler.postDelayed(this, Constants.player.POSITION_UPDATE_PERIOD_MS);
            }
        }
    }
    // END OF HANDLER METHODS //////////////////////////////////////////////////////////////////////////////////////////////////
}
