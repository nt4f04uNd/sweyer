/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.channels;

import com.nt4f04und.sweyer.Constants;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;

public enum NativeEventsChannel implements StreamHandler {
    instance;
    public void init(BinaryMessenger messenger) {
        if (channel == null) {
            channel = new EventChannel(messenger, "eventsChannel");
            channel.setStreamHandler(this);
        }
    }

    public void kill() {
        channel = null;
        events = null;
    }

    @Nullable
    private EventChannel channel;
    @Nullable
    private EventChannel.EventSink events;


    /** NOTE that this might be called when flutter view is detached
     *  Normally, `kill` method will set channel to null
     *  But `onDestroy` method is not guaranteed to be called, so sometimes it won't happen
     *
     *  AFAIK this isn't something bad and not an error, but warning
     */
    public void success(Object event) {
        if (this.events != null) {
            this.events.success(event);
        }
    }

    @Override
    public void onListen(Object args, final EventChannel.EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        events = null;
    }
}
