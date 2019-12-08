package com.nt4f04uNd.player.handlers;

import android.media.AudioManager;
import android.util.Log;

import com.nt4f04uNd.player.Constants;

/**
 * A class to implement and pass into audio focus handler
 * Listener for audio manager focus change
 */
public abstract class OnAudioFocusChangeListener implements AudioManager.OnAudioFocusChangeListener {
    protected abstract void onFocusGain();

    protected abstract void onFocusLoss();

    protected abstract void onFocusLossTransient();

    protected abstract void onFocusLossTransientCanDuck();

    @Override
    final public void onAudioFocusChange(int focusChange) {
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
