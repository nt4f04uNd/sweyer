/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.channels.NativeEventsChannel;

public abstract class AudioFocusHandler {

    public static void init() {
        if (audioManager == null) {
            audioManager = (AudioManager) GeneralHandler.getAppContext().getSystemService(Context.AUDIO_SERVICE);

            if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
                AudioAttributes attributes = new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build();
                focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener(new ImplementedOnAudioFocusListener())
                        .setAudioAttributes(attributes)
                        .build();
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

    public static int focusState = AudioManager.AUDIOFOCUS_LOSS;


    /**
     * Request audio manager focus for app
     */
    public static void requestFocus() {
        if (audioManager != null) {
            int res;
            if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
                res = audioManager.requestAudioFocus(focusRequest);
            } else {
                // NOTE This causes message "uses or overrides a deprecated API."
                res = audioManager.requestAudioFocus(afChangeListener,
                        // Use the music stream.
                        AudioManager.STREAM_MUSIC,
                        // Request permanent focus.
                        AudioManager.AUDIOFOCUS_GAIN
                );
            }

            Log.w(Constants.LogTag, "REQUEST FOCUS " + res);

            if (res == AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
                focusState = AudioManager.AUDIOFOCUS_LOSS;
            } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                focusState = AudioManager.AUDIOFOCUS_GAIN;
            } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
                focusState = AudioManager.AUDIOFOCUS_LOSS;
            }
        }
    }

    /**
     * Abandon audio manager focus for app
     */
    public static void abandonFocus() {
        if (audioManager != null) {
            int res;
            if (Build.VERSION.SDK_INT >= 26) { // Higher or equal than android 8.0
                res = audioManager.abandonAudioFocusRequest(focusRequest);
            } else {
                res = audioManager.abandonAudioFocus(afChangeListener);
            }

            Log.w(Constants.LogTag, "ABANDON FOCUS " + res);

            focusState = AudioManager.AUDIOFOCUS_LOSS;
        }
    }

    static public class ImplementedOnAudioFocusListener implements AudioManager.OnAudioFocusChangeListener {
        @Override
        final public void onAudioFocusChange(int focusChange) {
            Log.w(Constants.LogTag, "ONFOCUSCHANGE: " + focusChange);

            focusState = focusChange;

            try {
                switch (focusChange) {
                    // NOTE THAT WE CALL HERE BARE PLAYER FUNCTIONS
                    // THIS IS BECAUSE IN PLAYER HANDLER `pause` AND `resume` FUNCTIONS CALL request AND abandon FOCUS METHODS
                    case AudioManager.AUDIOFOCUS_GAIN: {
                        io.flutter.Log.w(Constants.LogTag, Constants.channels.events.AUDIOFOCUS_GAIN);


                        PlayerHandler.bareResume();

                        NativeEventsChannel.success(Constants.channels.events.AUDIOFOCUS_GAIN);
                        break;
                    }
                    case AudioManager.AUDIOFOCUS_LOSS: {
                        io.flutter.Log.w(Constants.LogTag, Constants.channels.events.AUDIOFOCUS_LOSS);

                        PlayerHandler.barePause();

                        NativeEventsChannel.success(Constants.channels.events.AUDIOFOCUS_LOSS);
                        break;
                    }
                    case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT: {
                        io.flutter.Log.w(Constants.LogTag, Constants.channels.events.AUDIOFOCUS_LOSS_TRANSIENT);

                        PlayerHandler.barePause();

                        NativeEventsChannel.success(Constants.channels.events.AUDIOFOCUS_LOSS_TRANSIENT);
                        break;
                    }
                    case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK: {
                        io.flutter.Log.w(Constants.LogTag, Constants.channels.events.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
                        // TODO: implement volume change

                        PlayerHandler.barePause();

                        NativeEventsChannel.success(Constants.channels.events.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
                        break;
                    }
                }
            } catch (IllegalStateException e) {
                io.flutter.Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            }
        }


    }
}