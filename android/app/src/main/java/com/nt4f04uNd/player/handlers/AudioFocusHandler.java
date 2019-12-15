/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.AudioFocusChannel;

public abstract class AudioFocusHandler {

    /**
     * @param appContext should be from `getApplicationContext()`
     */
    public static void init(Context appContext) {
        if(audioManager == null) {
            audioManager = (AudioManager) appContext.getSystemService(Context.AUDIO_SERVICE);

            if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
                focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener(new ImplementedOnAudioFocusListener()).build();
            } else {
                afChangeListener = new ImplementedOnAudioFocusListener();
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

    public static int focusState;


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

    static public class ImplementedOnAudioFocusListener implements AudioManager.OnAudioFocusChangeListener {
        @Override
        final public void onAudioFocusChange(int focusChange) {
            Log.w(Constants.LogTag, "ONFOCUSCHANGE: " + focusChange);

            focusState = focusChange;

            switch (focusChange) {
                case AudioManager.AUDIOFOCUS_GAIN:
                    io.flutter.Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN);
                    AudioFocusChannel.invokeMethod(
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN
                    );
                    break;
                case AudioManager.AUDIOFOCUS_LOSS:
                    io.flutter.Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS);
                    AudioFocusChannel.invokeMethod(
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS
                    );
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
                    io.flutter.Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT);
                    AudioFocusChannel.invokeMethod(
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT
                    );
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                    io.flutter.Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
                    AudioFocusChannel.invokeMethod(
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                            Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK
                    );
                    break;
            }
        }

    }
}