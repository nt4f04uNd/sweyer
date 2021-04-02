/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.channels;

import android.app.Activity;
import android.util.Log;

import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.nt4f04und.sweyer.handlers.QueueHandler;
import com.nt4f04und.sweyer.services.MusicService;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public enum GeneralChannel {
    instance;
    public void init(BinaryMessenger messenger, FlutterActivity activity) {
        if (channel == null) {
            this.activity = activity;
            channel = new MethodChannel(messenger, "general_channel");
            channel.setMethodCallHandler(this::onMethodCall);
        }
    }

    public void kill() {
        channel = null;
        activity = null;
    }

    @Nullable
    public MethodChannel channel;
    public Activity activity;

    public void onMethodCall(@NotNull MethodCall call, @NotNull MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        try {
            switch (call.method) {
                case "isIntentActionView":
                    result.success(GeneralHandler.isIntentActionView(activity));
                    break;
                case "stopService":
                    MusicService.stopService();
                    break;
                case "reloadArtPlaceholder":
                    QueueHandler.reloadArtPlaceholder(((Long) call.arguments).intValue());
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("GENERAL_CHANNEL_ERROR", e.getMessage(), Log.getStackTraceString(e));
        }
    }

}