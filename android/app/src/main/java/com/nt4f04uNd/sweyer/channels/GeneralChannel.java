/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import android.app.Activity;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.GeneralHandler;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class GeneralChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view, Activity activity) {
        if (channel == null) {
            GeneralChannel.activity = activity;
            channel = new MethodChannel(view, Constants.channels.general.CHANNEL_NAME);
            channel.setMethodCallHandler(new GeneralChannel());
        }
    }

    public static void kill() {
        channel = null;
        activity = null;
    }

    @Nullable
    public static MethodChannel channel;
    public static Activity activity;


    @Override
    public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        try {
            switch (call.method) {
                case Constants.channels.general.METHOD_INTENT_ACTION_VIEW:
                    result.success(GeneralHandler.isIntentActionView(activity));
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("GENERAL_CHANNEL_ERROR", e.getMessage(), e.getStackTrace());
        }
    }
}