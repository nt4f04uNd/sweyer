/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.channels;

import android.content.IntentFilter;
import android.media.AudioManager;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;
import com.nt4f04uNd.player.handlers.GeneralHandler;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;
import com.nt4f04uNd.player.handlers.NotificationHandler;
import com.nt4f04uNd.player.receivers.BecomingNoisyReceiver;
import com.nt4f04uNd.player.receivers.NotificationReceiver;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.view.FlutterView;

public class NativeEventsChannel implements StreamHandler {
    public static void init(FlutterView view) {
        if(channel == null) {
            channel = new EventChannel(view, Constants.channels.EVENT_CHANNEL_STREAM);
            channel.setStreamHandler(new NativeEventsChannel());
        }
    }

    public static void kill() {
        channel = null;
        events = null;
    }

    @Nullable
    private static EventChannel channel;
    @Nullable
    private static EventChannel.EventSink events;

    public static void success(Object event) {
        Log.w(Constants.LogTag, "SENDING EVENT: " + event.toString());
        if (events != null)
            events.success(event);
    }

    @Override
    public void onListen(Object args, final EventChannel.EventSink events) {
        NativeEventsChannel.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        events = null;
    }
}
