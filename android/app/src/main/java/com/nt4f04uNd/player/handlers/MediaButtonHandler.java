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
import com.nt4f04uNd.player.channels.NativeEventsChannel;

import java.util.ArrayList;

import androidx.annotation.NonNull;

public class MediaButtonHandler {
    public static void init() {
        if (audioSession == null) {
            // TODO: change tag maybe and move it to Constants
            audioSession = new MediaSession(GeneralHandler.getAppContext(), "TAG");
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

            audioSession.setActive(true);
        }

        MediaButtonHandler.addListener(new ImplementedOnMediaButtonListener());
    }

    private static MediaSession audioSession;
    private static ArrayList<OnMediaButtonListener> listeners = new ArrayList<>(0);

    public static void addListener(OnMediaButtonListener listener) {
        listeners.add(listener);
    }

    public static void release() {
        audioSession.release();
        audioSession = null;
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

    private static class ImplementedOnMediaButtonListener extends com.nt4f04uNd.player.handlers.OnMediaButtonListener {
        @Override
        protected void onAudioTrack() {
            PlayerHandler.play(PlaylistHandler.getNextSong().trackUri, PlayerHandler.getVolume(), 0, false, true, true);
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_AUDIO_TRACK);
        }

        @Override
        protected void onFastForward() {
            PlayerHandler.seek(PlayerHandler.getCurrentPosition() + 3000);
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_FAST_FORWARD);
        }

        @Override
        protected void onRewind() {
            PlayerHandler.seek(PlayerHandler.getCurrentPosition() - 3000);
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_REWIND);
        }

        @Override
        protected void onNext() {
            PlayerHandler.play(PlaylistHandler.getNextSong().trackUri, PlayerHandler.getVolume(), 0, false, true, true);
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_NEXT);
        }

        @Override
        protected void onPrevious() {
            PlayerHandler.play(PlaylistHandler.getPrevSong().trackUri, PlayerHandler.getVolume(), 0, false, true, true);
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_PREVIOUS);
        }

        @Override
        protected void onPlayPause() {
            if (PlayerHandler.player.isActuallyPlaying())
                PlayerHandler.pause();
            else PlayerHandler.resume();
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_PLAY_PAUSE);
        }

        @Override
        protected void onPlay() {
            PlayerHandler.resume();
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_PLAY);
        }

        @Override
        protected void onStop() {
            PlayerHandler.pause();
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_STOP);
        }

        @Override
        protected void onHook() {
            // TODO: implement
            io.flutter.Log.w(Constants.LogTag, "HOOK PRESS");
            NativeEventsChannel.success(Constants.channels.EVENT_MEDIABUTTON_HOOK);
        }

    }
}
