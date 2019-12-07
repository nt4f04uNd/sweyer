package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;

import com.nt4f04uNd.player.Constants;

/**
 * Abstract class to create custom focus handlers
 */
public abstract class AudioFocusHandlerAbstraction {

    /**
     * @param appContext should be from `getApplicationContext()`
     */
    public AudioFocusHandlerAbstraction(Context appContext) {
        audioManager = (AudioManager) appContext.getSystemService(Context.AUDIO_SERVICE);

        if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
            focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAcceptsDelayedFocusGain(true)
                    .setOnAudioFocusChangeListener(new OnFocusChangeListener()).build();
        } else {
            afChangeListener = new OnFocusChangeListener();
        }
    }

    final private AudioManager audioManager;
    /**
     * Listener for lower than 8.0 android version
     */
    private AudioManager.OnAudioFocusChangeListener afChangeListener;
    /**
     * Focus request for audio manager
     */
    private AudioFocusRequest focusRequest;

    // Callbacks
    protected abstract void onFocusGain();

    protected abstract void onFocusLoss();

    protected abstract void onFocusLossTransient();

    protected abstract void onFocusLossTransientCanDuck();

    /**
     * Listener for audio manager focus change
     */
    private final class OnFocusChangeListener implements AudioManager.OnAudioFocusChangeListener {
        @Override
        public void onAudioFocusChange(int focusChange) {
            Log.w(Constants.LogTag, "ONFOCUSCHANGE: " + focusChange);
            switch (focusChange) {
                case AudioManager.AUDIOFOCUS_GAIN:
                    onFocusGain();
                    break;
                case AudioManager.AUDIOFOCUS_LOSS:
                    onFocusLoss();
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
                    onFocusLossTransient();
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                    onFocusLossTransientCanDuck();
                    break;
            }
        }
    }


    /**
     * Request audio manager focus for app
     */
    public final String requestFocus() {
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
            return Constants.PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_FAILED;
        } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            return Constants.PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_GRANTED;
        } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
            return Constants.PLAYER_METHOD_REQUEST_FOCUS_RETURN_AUDIOFOCUS_REQUEST_DELAYED;
        }
        Log.w(Constants.LogTag, "WRONG_EVENT");
        return "WRONG_EVENT";
    }

    /**
     * Abandon audio manager focus for app
     */
    public final int abandonFocus() {
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