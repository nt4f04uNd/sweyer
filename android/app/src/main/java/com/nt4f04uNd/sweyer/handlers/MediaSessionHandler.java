/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.content.Intent;
import android.media.session.MediaSession;
import android.util.Log;
import android.view.KeyEvent;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.channels.NativeEventsChannel;

import java.util.ArrayList;

import androidx.annotation.NonNull;

public class MediaSessionHandler {
    public static void init() {
        if (mediaSession == null) {
            mediaSession = new MediaSession(GeneralHandler.getAppContext(), Constants.PACKAGE_NAME + ":mediaSessionTag");
            mediaSession.setCallback(new MediaSession.Callback() {

                // TODO: implement remaining methods

                @Override
                public void onFastForward() {
                    PlayerHandler.fastForward();
                }

                @Override
                public void onPause() {
                    PlayerHandler.pause();
                }

                @Override
                public void onPlay() {
                    PlayerHandler.resume();
                }

                @Override
                public void onRewind() {
                    PlayerHandler.rewind();
                }

                @Override
                public void onSeekTo(long pos) {
                    PlayerHandler.seek((int) pos);
                }

                @Override
                public void onSkipToNext() {
                    PlayerHandler.playNext();
                }

                @Override
                public void onSkipToPrevious() {
                    PlayerHandler.playPrev();
                }

                @Override
                public void onStop() {
                    PlayerHandler.pause();
                }

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

            mediaSession.setActive(true);

            addListener(new ImplementedOnMediaButtonListener());
        }
    }

    private static MediaSession mediaSession;
    private static ArrayList<OnMediaButtonListener> listeners = new ArrayList<>(0);

    public static void addListener(OnMediaButtonListener listener) {
        listeners.add(listener);
    }

    public static void release() {
        if (mediaSession != null) {
            mediaSession.release();
            mediaSession = null;
            listeners = new ArrayList<>(0);
        }
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

    private static class ImplementedOnMediaButtonListener extends com.nt4f04uNd.sweyer.handlers.OnMediaButtonListener {
        @Override
        protected void onAudioTrack() {
            PlayerHandler.playNext();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_AUDIO_TRACK);
        }

        @Override
        protected void onFastForward() {
            PlayerHandler.fastForward();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_FAST_FORWARD);
        }

        @Override
        protected void onRewind() {
            PlayerHandler.rewind();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_REWIND);
        }

        @Override
        protected void onNext() {
            PlayerHandler.playNext();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_NEXT);
        }

        @Override
        protected void onPrevious() {
            PlayerHandler.playPrev();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_PREVIOUS);
        }

        @Override
        protected void onPlayPause() {
            PlayerHandler.playPause();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_PLAY_PAUSE);
        }

        @Override
        protected void onPlay() {
            try {
                PlayerHandler.resume();
            } catch (IllegalStateException e) {
                Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            }
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_PLAY);
        }

        @Override
        protected void onStop() {
            try {
                PlayerHandler.pause();
            } catch (IllegalStateException e) {
                Log.e(Constants.LogTag, String.valueOf(e.getMessage()));
            }
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_STOP);
        }

        @Override
        protected void onHook() {
            PlayerHandler.handleHookButton();
            NativeEventsChannel.success(Constants.channels.events.MEDIABUTTON_HOOK);
        }

    }
}
