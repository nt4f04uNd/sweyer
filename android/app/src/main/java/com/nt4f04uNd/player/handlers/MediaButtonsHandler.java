package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.content.Intent;
import android.media.session.MediaSession;
import android.util.Log;
import android.view.KeyEvent;

import com.nt4f04uNd.player.Constants;

import androidx.annotation.NonNull;
import io.flutter.plugin.common.MethodChannel;

public class MediaButtonsHandler {
    /** @param appContext should be from `getApplicationContext()`
     * @param methodChannel is methodChannel to call event methods (should be sort of playerChannel)
     *  */
    public MediaButtonsHandler(Context appContext, MethodChannel methodChannel) {
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
                        switch (event.getKeyCode()) {
                            case KeyEvent.KEYCODE_MEDIA_AUDIO_TRACK:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_AUDIO_TRACK);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_FAST_FORWARD);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_REWIND:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_REWIND);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_NEXT:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_NEXT);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_PREVIOUS:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_PREVIOUS);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_PLAY_PAUSE);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_PLAY:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_PLAY);
                                break;
                            case KeyEvent.KEYCODE_MEDIA_STOP:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_STOP);
                                break;
                            case KeyEvent.KEYCODE_HEADSETHOOK:
                                methodChannel.invokeMethod(Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK,
                                        Constants.PLAYER_METHOD_MEDIA_BUTTON_CLICK_ARG_HOOK);
                                break;
                        }
                    }
                }
                return true;
            }
        });
    }

    private final MediaSession audioSession;

    public void turnActive(){
        audioSession.setActive(true);
    }

    public void release(){
        audioSession.release();
    }
}
