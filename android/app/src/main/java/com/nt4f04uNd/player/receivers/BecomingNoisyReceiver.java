package com.nt4f04uNd.player.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioManager;

import com.nt4f04uNd.player.Constants;

import io.flutter.plugin.common.EventChannel;

/** Broadcast receiver for become noisy intent */
public class BecomingNoisyReceiver extends BroadcastReceiver {
    final EventChannel.EventSink eventSink;

    public BecomingNoisyReceiver(EventChannel.EventSink eventSink) {
        super();
        this.eventSink = eventSink;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) {
            eventSink.success(Constants.EVENT_BECOME_NOISY);
        }
    }
}
