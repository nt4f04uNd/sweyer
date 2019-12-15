/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.NativeEventsChannel;

import io.flutter.plugin.common.EventChannel;

/** Broadcast receiver for notifications intents */
public class NotificationReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        if (Constants.channels.EVENT_NOTIFICATION_INTENT_PLAY.equals(intent.getAction())) {
            NativeEventsChannel.success(Constants.channels.EVENT_NOTIFICATION_INTENT_PLAY);
        } else if (Constants.channels.EVENT_NOTIFICATION_INTENT_PAUSE.equals(intent.getAction())) {
            NativeEventsChannel.success(Constants.channels.EVENT_NOTIFICATION_INTENT_PAUSE);
        } else if (Constants.channels.EVENT_NOTIFICATION_INTENT_NEXT.equals(intent.getAction())) {
            NativeEventsChannel.success(Constants.channels.EVENT_NOTIFICATION_INTENT_NEXT);
        } else if (Constants.channels.EVENT_NOTIFICATION_INTENT_PREV.equals(intent.getAction())) {
            NativeEventsChannel.success(Constants.channels.EVENT_NOTIFICATION_INTENT_PREV);
        }
    }
}
