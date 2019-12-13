package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;

import com.nt4f04uNd.player.Constants;

public abstract class AudioFocusHandler {

    /**
     * @param appContext should be from `getApplicationContext()`
     * @param listener   instance of implemented listener
     */
    public static void init(Context appContext, OnAudioFocusChangeListener listener) {
        if(audioManager == null) {
            audioManager = (AudioManager) appContext.getSystemService(Context.AUDIO_SERVICE);

            if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
                focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener(listener).build();
            } else {
                afChangeListener = listener;
            }
        }
    }

    private static AudioManager audioManager;
    /**
     * Listener for lower than 8.0 android version
     */
    private static AudioManager.OnAudioFocusChangeListener afChangeListener;
    /**
     * Focus request for audio manager
     */
    private static AudioFocusRequest focusRequest;


    /**
     * Request audio manager focus for app
     */
    public static String requestFocus() {
        int res;
        if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
            res = audioManager.requestAudioFocus(focusRequest);
        } else {
            // NOTE This causes message "uses or overrides a deprecated API."
            res = audioManager.requestAudioFocus(afChangeListener,
                    // Use the music stream.
                    AudioManager.STREAM_MUSIC,
                    // Request permanent focus.
                    AudioManager.AUDIOFOCUS_GAIN);
        }

        Log.w(Constants.LogTag, "REQUEST FOCUS " + res);
        if (res == AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
            return Constants.AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_FAILED;
        } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            return Constants.AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_GRANTED;
        } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
            return Constants.AUDIOFOCUS_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_DELAYED;
        }
        Log.w(Constants.LogTag, "WRONG_EVENT");
        return "WRONG_EVENT";
    }

    /**
     * Abandon audio manager focus for app
     */
    public static int abandonFocus() {
        int res;

        if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
            res = audioManager.abandonAudioFocusRequest(focusRequest);
        } else {
            res = audioManager.abandonAudioFocus(afChangeListener);
        }

        Log.w(Constants.LogTag, "ABANDON FOCUS " + res);
        return res;
    }
}