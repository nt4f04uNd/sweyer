/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.content.Intent;
import android.media.session.MediaSession;
import android.util.Log;
import android.view.KeyEvent;

import com.nt4f04uNd.player.Constants;

import java.util.ArrayList;

import androidx.annotation.NonNull;

public class MediaButtonHandler {
    /**
     * @param appContext should be from `getApplicationContext()`
     */
    public static void init(Context appContext) {
        if(audioSession == null) {
            // TODO: change tag maybe and move it to Constants
            audioSession = new MediaSession(appContext, "TAG");
            audioSession.setCallback(new MediaSession.Callback() {
                @Override
                public boolean onMediaButtonEvent(@NonNull final Intent mediaButtonIntent) {
                    String intentAction = mediaButtonIntent.getAction();
                    if (Intent.ACTION_MEDIA_BUTTON.equals(intentAction)) {
                        KeyEvent event = mediaButtonIntent.getParcelableExtra(Intent.EXTRA_KEY_EVENT);

                        if (event == null) {
                            Log.e(Constants.LogTag, "Can't handle button press - MediaButton event is null");
                            return false;
                        }

                        if (event.getAction() == KeyEvent.ACTION_DOWN) {
                            notifyListeners(event);
                        }
                    }
                    return true;
                }
            });
        }
    }

    private static MediaSession audioSession;
    private static ArrayList<OnMediaButtonListener> listeners = new ArrayList<>(0);

    public static void addListener(OnMediaButtonListener listener){
        listeners.add(listener);
    }

    public static void turnActive() {
        audioSession.setActive(true);
    }

    public static void release() {
        audioSession.release();
        listeners = null;
    }
    private static void notifyListeners(KeyEvent event) {
        for (OnMediaButtonListener listener : listeners) {
            switch (event.getKeyCode()) {
                case KeyEvent.KEYCODE_MEDIA_AUDIO_TRACK:
                    listener.onAudioTrack();
                    break;
                case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD:
                    listener.onFastForward();
                    break;
                case KeyEvent.KEYCODE_MEDIA_REWIND:
                    listener.onRewind();
                    break;
                case KeyEvent.KEYCODE_MEDIA_NEXT:
                    listener.onNext();
                    break;
                case KeyEvent.KEYCODE_MEDIA_PREVIOUS:
                    listener.onPrevious();
                    break;
                case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
                    listener.onPlayPause();
                    break;
                case KeyEvent.KEYCODE_MEDIA_PLAY:
                    listener.onPlay();
                    break;
                case KeyEvent.KEYCODE_MEDIA_STOP:
                    listener.onStop();
                    break;
                case KeyEvent.KEYCODE_HEADSETHOOK:
                    listener.onHook();
                    break;
            }
        }
    }


}
