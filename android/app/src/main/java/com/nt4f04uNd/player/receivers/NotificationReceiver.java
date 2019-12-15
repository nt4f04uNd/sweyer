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

import io.flutter.plugin.common.EventChannel;

/** Broadcast receiver for notifications intents */
public class NotificationReceiver extends BroadcastReceiver {
    final EventChannel.EventSink eventSink;

    public NotificationReceiver(EventChannel.EventSink eventSink) {
        super();
        this.eventSink = eventSink;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.w(Constants.LogTag, intent.getAction());
        if (Constants.EVENT_NOTIFICATION_INTENT_PLAY.equals(intent.getAction())) {
            eventSink.success(Constants.EVENT_NOTIFICATION_INTENT_PLAY);
        } else if (Constants.EVENT_NOTIFICATION_INTENT_PAUSE.equals(intent.getAction())) {
            eventSink.success(Constants.EVENT_NOTIFICATION_INTENT_PAUSE);
        } else if (Constants.EVENT_NOTIFICATION_INTENT_NEXT.equals(intent.getAction())) {
            eventSink.success(Constants.EVENT_NOTIFICATION_INTENT_NEXT);
        } else if (Constants.EVENT_NOTIFICATION_INTENT_PREV.equals(intent.getAction())) {
            eventSink.success(Constants.EVENT_NOTIFICATION_INTENT_PREV);
        }
    }
}
