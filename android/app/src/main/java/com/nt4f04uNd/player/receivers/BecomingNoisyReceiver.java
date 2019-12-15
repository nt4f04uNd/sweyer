/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioManager;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.NativeEventsChannel;

import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;

/** Broadcast receiver for become noisy intent */
public class BecomingNoisyReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) {
            NativeEventsChannel.success(Constants.channels.EVENT_BECOME_NOISY);
        }
    }
}
