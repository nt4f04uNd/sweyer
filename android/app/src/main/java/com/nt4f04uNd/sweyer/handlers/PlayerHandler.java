/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.media.AudioManager;
import android.os.Handler;

import com.nt4f04und.sweyer.Constants;
import com.nt4f04und.sweyer.channels.NativeEventsChannel;
import com.nt4f04und.sweyer.channels.PlayerChannel;
import com.nt4f04und.sweyer.player.Player;
import com.nt4f04und.sweyer.services.MusicService;
import com.nt4f04und.sweyer.player.PlayerState;
import com.nt4f04und.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import android.util.Log;

/** Every time you use this class, don't forget to try...catch its method calls */
public abstract class PlayerHandler {

    private static Player player;
    /** For position updates */
    private static final Handler positionHandler = new Handler();
    private static Runnable positionUpdates;
    /** To kill the service with timeout the service when player is paused */
    private static final Handler timeoutHandler = new Handler();

    public static void init() {
        if (player == null) {
            player = new Player();
            if (PrefsHandler.getLoopMode()) {
                // I don't call handleLoopModeSwitch(true) 'cause a the moment of execution of this code dart code hasn't been initiated yet
                player.setLooping(true);
            } else {
                player.setLooping(false);
            }
        }
    }

    // HANDLERS /////////////////

    /** Builds arguments to send them to PlayerChannel */
    private static Map<String, Object> buildArguments(Object value) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("value", value);
        return arguments;
    }

    public static void handleCompletion() {
        callSetState(PlayerState.COMPLETED);
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

        PlayerChannel.instance.invokeMethod("audio.onError", arguments);
    }

    /** Notifies channel about loop mode switch */
    public static void handleLoopModeSwitch(boolean value) {
        PlayerChannel.instance.invokeMethod("audio.onLoopModeSwitch", buildArguments(value));
    }

    public static void callSetState(PlayerState state) {
        switch (state) {
            case PLAYING:
                PlayerChannel.instance.invokeMethod("audio.state.set", buildArguments("PLAYING"));
                break;
            case PAUSED:
                PlayerChannel.instance.invokeMethod("audio.state.set", buildArguments("PAUSED"));
                break;
            case COMPLETED:
                PlayerChannel.instance.invokeMethod("audio.state.set", buildArguments("COMPLETED"));
                break;
            default:
                break;
        }

    }

    /** Removes callbacks and messages from all handlers
     * Needed to safely destroy the service */
    public static void stopAllHandlers() {
        positionHandler.removeCallbacksAndMessages(null);
        timeoutHandler.removeCallbacksAndMessages(null);
    }
    // END OF HANDLERS /////////////////

    // COMPOSED METHODS (wrappers over default player methods) /////////////////
    public static void play(@NotNull Song song, Boolean duplicate) {
        WakelockHandler.acquire();
        MusicService.startService();
        QueueHandler.handleDuplicate(song, duplicate);
        QueueHandler.setCurrentSong(song);
        PrefsHandler.setSongId(song.id);
        NotificationHandler.updateNotification(true, PlayerHandler.isLooping());

        player.setAwake(GeneralHandler.getAppContext(), true);
        setUri(song.id);

        if (AudioFocusHandler.focusState != AudioManager.AUDIOFOCUS_GAIN)
            AudioFocusHandler.requestFocus();
        if (AudioFocusHandler.focusState == AudioManager.AUDIOFOCUS_GAIN) {
            boolean success = true;
            try {
                player.play(GeneralHandler.getAppContext());
            } catch (Exception e) {
                success = false;
                throw e;
            } finally {
                if (success) {
                    callSetState(PlayerState.PLAYING);
                }
            }
        }
    }

    public static void resume() {
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
        player.seek(position);
    }

    public static void setVolume(double volume) {
        player.setVolume(volume);
    }

    public static void setUri(int songId) {
        player.setUri(FetchHandler.getSongUri(songId));
    }

    public static double getVolume() {
        return player.getVolume();
    }

    public static int getDuration() {
        return player.getDuration();
    }

    public static int getPosition() {
        return player.getPosition();
    }

    public static boolean isPlaying() {
        return player.isPlaying();
    }

    public static boolean isLooping() {
        return player.isLooping();
    }

    public static void setLooping(boolean value) {
        if (value) {
            player.setLooping(true);
            PrefsHandler.setLoopMode(true);
            handleLoopModeSwitch(true);
            NotificationHandler.updateNotification(isPlaying(), true);
        } else {
            player.setLooping(false);
            PrefsHandler.setLoopMode(false);
            handleLoopModeSwitch(false);
            NotificationHandler.updateNotification(isPlaying(), false);
        }
    }
    // END OF COMPOSED METHODS ///////////////////////////////////////////////////////////////////////////////////

    /// BARE METHODS (they do all stuff, just do not care about audio focus) ///////////////////////////////////
    /** Normal resume function, it just doesn't care about handling audio focus */
    public static void bareResume() {
        WakelockHandler.acquire();
        timeoutHandler.removeCallbacksAndMessages(null);
        player.play(GeneralHandler.getAppContext());
        MusicService.startService();
        MediaSessionHandler.updatePlaybackState();
        PrefsHandler.setSongIsPlaying(true);
        callSetState(PlayerState.PLAYING);
        NotificationHandler.updateNotification(isPlaying(), isLooping());
        player.setAwake(GeneralHandler.getAppContext(), true);
    }

    public static void barePause() {
        WakelockHandler.acquireTimed();
        timeoutHandler.postDelayed(MusicService::stopService, 2 * 60 * 1000);
        player.pause();
        MusicService.stopForeground();
        MediaSessionHandler.updatePlaybackState();
        PrefsHandler.setSongIsPlaying(false);
        callSetState(PlayerState.PAUSED);
    }

    public static void bareStop() {
        WakelockHandler.acquireTimed();
        MusicService.stopService();
        timeoutHandler.removeCallbacksAndMessages(null);
        player.pause();
        MediaSessionHandler.updatePlaybackState();
        PrefsHandler.setSongIsPlaying(false);
        callSetState(PlayerState.PAUSED);
        NotificationHandler.updateNotification(false, isLooping());
    }

    public static void bareRelease() {
        MusicService.stopService();
        timeoutHandler.removeCallbacksAndMessages(null);
        player.release();
        MediaSessionHandler.updatePlaybackState();
        PrefsHandler.setSongIsPlaying(false);
        callSetState(PlayerState.PAUSED);
        NotificationHandler.updateNotification(false, isLooping());
        WakelockHandler.release();
    }
    /// END OF BARE METHODS ///////////////


    // ONLY NATIVE PART METHODS (add more extended playback handling and are called only on native part) ///////////////
    public static void playPause() {
        try {
            if (player.isUriNull())
                if (GeneralHandler.activityExists()) {
                    // Do nothing if activity exists, but url is null
                    return;
                } else {
                    // Fetch current song if activity does not exists
                    QueueHandler.initCurrentSong();
                }

            if (isPlaying())
                pause();
            else resume();

        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void playNext() {
        try {
            if (GeneralHandler.activityExists()) {
                NativeEventsChannel.instance.success(Constants.eventsChannel.GENERALIZED_PLAY_NEXT);
            } else {
                QueueHandler.restoreQueue();
                seek(0);
                play(QueueHandler.getNextSong(),null);
            }
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void playPrev() {
        try {
            if (GeneralHandler.activityExists()) {
                NativeEventsChannel.instance.success(Constants.eventsChannel.GENERALIZED_PLAY_PREV);
            } else {
                QueueHandler.restoreQueue();
                seek(0);
                play(QueueHandler.getPrevSong(), null);
            }
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void rewind() {
        try {
           player.seek(getPosition() - 3000);
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void fastForward() {
        try {
           player.seek(getPosition() + 3000);
        } catch (IllegalStateException e) {
            Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
        }
    }

    public static void switchLooping() {
        setLooping(!player.isLooping());
    }
    // END OF NATIVE PART METHODS ///////////////

    // HANDLER METHODS ///////////////
    public static void notifyPositions() {
        final int position = player.getPosition();
        MediaSessionHandler.updatePlaybackState();
        // Convert to seconds
        PrefsHandler.setSongPosition(position / 1000);
        PlayerChannel.instance.invokeMethod("audio.onPosition", buildArguments(position));
    }

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
                notifyPositions();
            } catch (UnsupportedOperationException e) {
                handleError(e);
            } finally {
                handler.postDelayed(this, Constants.player.POSITION_UPDATE_PERIOD_MS);
            }
        }
    }
    // END OF HANDLER METHODS //////////////////////////////////////////////////////////////////////////////////////////////////
}
