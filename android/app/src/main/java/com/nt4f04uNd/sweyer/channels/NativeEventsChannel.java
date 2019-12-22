/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import com.nt4f04uNd.sweyer.Constants;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.view.FlutterView;

public class NativeEventsChannel implements StreamHandler {
    public static void init(FlutterView view) {
        if (channel == null) {
            channel = new EventChannel(view, Constants.channels.events.CHANNEL_NAME);
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


    /** NOTE that this might be called when flutter view is detached
     *  Normally, `kill` method will set channel to null
     *  But `onDestroy` method is not guaranteed to be called, so sometimes it won't happen
     **
     *  AFAIK this isn't something bad and not an error, but warning
     */
    public static void success(Object event) {
        if (events != null) {
            events.success(event);
        }
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
