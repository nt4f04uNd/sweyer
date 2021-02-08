/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;

/** Broadcast receiver for media notification button intent */
public class NotificationReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Constants.player.NOTIFICATION_INTENT_PLAY.equals(intent.getAction())) {
            PlayerHandler.resume();
        } else if (Constants.player.NOTIFICATION_INTENT_PAUSE.equals(intent.getAction())) {
            PlayerHandler.pause();
        } else if (Constants.player.NOTIFICATION_INTENT_NEXT.equals(intent.getAction())) {
            // Inside this function, as well as `playPrev` there's a handler for the case when activity is not alive
            PlayerHandler.playNext();
        } else if (Constants.player.NOTIFICATION_INTENT_PREV.equals(intent.getAction())) {
            PlayerHandler.playPrev();
        } else if (Constants.player.NOTIFICATION_INTENT_LOOP.equals(intent.getAction())) {
            PlayerHandler.switchLooping();
        } else if (Constants.player.NOTIFICATION_INTENT_LOOP_ON.equals(intent.getAction())) {
            PlayerHandler.switchLooping();
        } else if (Constants.player.NOTIFICATION_INTENT_KILL_SERVICE.equals(intent.getAction())) {
            PlayerHandler.stop();
        }
    }
}
