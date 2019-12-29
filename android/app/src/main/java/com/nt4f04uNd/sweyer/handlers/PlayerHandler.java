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
import com.nt4f04uNd.sweyer.channels.NativeEventsChannel;
import com.nt4f04uNd.sweyer.channels.PlayerChannel;
import com.nt4f04uNd.sweyer.player.Player;
import com.nt4f04uNd.sweyer.player.PlayerState;
import com.nt4f04uNd.sweyer.player.ReleaseMode;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel;

/**
 * NOTE Every time you use this class, don't forget to try...catch its method calls
 */
public abstract class PlayerHandler { // TODO: add error handling and logging

    public static Player player;
    /**
     * For position updates
     */
    private static final Handler positionHandler = new Handler();
    private static Runnable positionUpdates;
    /**
     * For hook button handling
     */
    private static final Handler hookButtonHandler = new Handler();
    private static int hookButtonPressCount = 0;


    public static void init() {
        if (player == null) {
            player = new Player();
            if (PrefsHandler.getLoopMode()) { // I don't call handleLoopModeSwitch(true) 'cause a the moment of execution of this code dart code hasn't been initiated yet
                setReleaseMode(ReleaseMode.LOOP);
            } else {
                setReleaseMode(ReleaseMode.STOP);
            }
        }
    }

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
        Map<String, Object> arguments = new HashMap<>();
        Map<String, Object> exception = new HashMap<>();

        exception.put("message", e.getMessage());
        arguments.put("value", exception);

        PlayerChannel.invokeMethod("audio.onError", arguments);
    }

    public static void handleHookButton() {
        hookButtonPressCount++;
        if (hookButtonPressCount == 1) {
            hookButtonHandler.postDelayed(new HookDelayedRunnable(), 500);
        }
    }

    private static final class HookDelayedRunnable implements Runnable {
        @Override
        public void run() {
            try {
                if (hookButtonPressCount == 1) {
                    NativeEventsChannel.success(Constants.channels.events.HOOK_PLAY_PAUSE);
                    playPause();
                } else if (hookButtonPressCount == 2) {
                    NativeEventsChannel.success(Constants.channels.events.HOOK_PLAY_NEXT);
                    playNext();
                } else {
                    NativeEventsChannel.success(Constants.channels.events.HOOK_PLAY_PREV);
                    playPrev();
                }
            } catch (IllegalStateException e) {
                Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            } finally {
                hookButtonPressCount = 0;
            }
        }
    }

    /// Notifies channel about loop mode switch
    public static void handleLoopModeSwitch(boolean value) {
        PlayerChannel.invokeMethod("audio.onLoopModeSwitch", buildArguments(value));
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


    // COMPOSED METHODS (wrappers over default player methods) ///////////////////////////////////////////////////////////////
    // TODO: remove respect silence, isLocal and stayAwake
    public static void play(@NotNull Song song, double volume, Integer position, boolean respectSilence, boolean isLocal, boolean stayAwake) {
        ServiceHandler.startService(true);
        player.configAttributes(respectSilence, stayAwake, GeneralHandler.getAppContext());
        player.setVolume(volume);
        player.setUrl(song.trackUri, isLocal);
        if (position != null)
            PlayerHandler.player.seek(position);

        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN) {
            boolean success = true;
            try {
                player.play();
            } catch (Exception e) {
                success = false;
                throw e;
            } finally {
                if (success) {
                    PlayerHandler.callSetState(PlayerState.PLAYING);
                    PlaylistHandler.setCurrentSong(song);
                    PrefsHandler.setSongId(song.id);
                    NotificationHandler.updateNotification(true, isLooping());
                }
            }
        }
    }

    public static void resume() {
        ServiceHandler.startService(true);
        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN) {
            bareResume();
        }
    }

    public static void pause() {
        ServiceHandler.startService(false);
        barePause();
        AudioFocusHandler.abandonFocus();
    }

    /**
     * Discouraged to use
     */
    public static void stop() {
        ServiceHandler.stopService();
        bareStop();
        AudioFocusHandler.abandonFocus();
    }

    /**
     * Discouraged to use
     */
    public static void release() {
        ServiceHandler.stopService();
        bareRelease();
        AudioFocusHandler.abandonFocus();
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


    /// BARE METHODS (they do all stuff, just do not care about audio focus) ///////////////////////////////////

    /**
     * Normal resume function, it just doesn't care about handling audio focus
     */
    public static void bareResume() {
        player.play();
        PrefsHandler.setSongIsPlaying(true);
        PlayerHandler.callSetState(PlayerState.PLAYING);
        NotificationHandler.updateNotification(true, isLooping());
    }

    public static void barePause() {
        player.pause();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.PAUSED);
        NotificationHandler.updateNotification(false, isLooping());
    }

    public static void bareStop() {
        player.stop();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.STOPPED);
        // TODO: maybe remove notification at all?
        NotificationHandler.updateNotification(false, isLooping());
    }

    public static void bareRelease() {
        player.release();
        PrefsHandler.setSongIsPlaying(false);
        PlayerHandler.callSetState(PlayerState.STOPPED);
        // TODO: maybe remove notification at all?
        NotificationHandler.updateNotification(false, isLooping());
    }
    /// END OF BARE METHODS ////////////////////////////////////////////////////////////////////////


    // ONLY NATIVE PART METHODS (add more extended playback handling and are called only on native part) //////////////////////////////////////////////

    public static void playPause() {
        try {
            if (player.isUrlNull())
                if (GeneralHandler.activityExists()) {
                    // Do nothing if activity exists, but url is null
                    return;
                } else {
                    // Fetch current song if activity does not exists
                    PlaylistHandler.initCurrentSong();
                }


            if (PlayerHandler.isPlaying())
                PlayerHandler.pause();
            else PlayerHandler.resume();

        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void playNext() {
        try {
            if (!GeneralHandler.activityExists()) {
                PlaylistHandler.getLastPlaylist();
                PlayerHandler.play(PlaylistHandler.getNextSong(), PlayerHandler.getVolume(), 0, false, true, true);
            }
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void playPrev() {
        try {
            if (!GeneralHandler.activityExists()) {
                PlaylistHandler.getLastPlaylist();
                PlayerHandler.play(PlaylistHandler.getPrevSong(), PlayerHandler.getVolume(), 0, false, true, true);
            }
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void rewind() {
        try {
            PlayerHandler.player.seek(PlayerHandler.getCurrentPosition() - 3000);
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void fastForward() {
        try {
            PlayerHandler.player.seek(PlayerHandler.getCurrentPosition() + 3000);
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static boolean isLooping() {
        return player.getReleaseMode().equals(ReleaseMode.LOOP);
    }

    public static void switchLoopMode() {
        if (isLooping()) {
            setReleaseMode(ReleaseMode.STOP);
            PrefsHandler.setLoopMode(false);
            handleLoopModeSwitch(false);
            NotificationHandler.updateNotification(isPlaying(), false);
        } else {
            setReleaseMode(ReleaseMode.LOOP);
            PrefsHandler.setLoopMode(true);
            handleLoopModeSwitch(true);
            NotificationHandler.updateNotification(isPlaying(), true);
        }
    }

    // END OF NATIVE PART METHODS ///////////////////////////////////////////////////////////////////////////////////


    // HANDLER METHODS /////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Starts handler
     * Called from music player instance whenever music starts to start position updates streaming
     */
    public static void startPositionUpdates() {
        if (positionUpdates != null)
            return;
        positionUpdates = new UpdatePositionRunnable(positionHandler);
        positionHandler.post(positionUpdates);
    }


    /**
     * Stops handler
     * Called from music player instance whenever music stops to stop position updates streaming
     */
    public static void stopPositionUpdates() {
        positionUpdates = null;
        positionHandler.removeCallbacksAndMessages(null);
    }

    /**
     * Callback that is passed to handler to have a stream of position updates
     */
    private static final class UpdatePositionRunnable implements Runnable {
        private final WeakReference<Handler> handlerRef;

        private UpdatePositionRunnable(final Handler handler) {
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
