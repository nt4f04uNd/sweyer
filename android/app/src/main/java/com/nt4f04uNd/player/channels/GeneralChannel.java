/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.channels;

import android.app.Activity;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.GeneralHandler;
import com.nt4f04uNd.player.handlers.ServiceHandler;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class GeneralChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view, Activity activity) {
        if(channel == null) {
            GeneralChannel.activity = activity;
            channel = new MethodChannel(view, Constants.channels.GENERAL_CHANNEL_STREAM);
            channel.setMethodCallHandler(new GeneralChannel());
        }
    }

    public static void kill() {
        channel = null;
        activity = null;
    }

    @Nullable
    private static MethodChannel channel;
    @Nullable
    private static Activity activity;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        final String method = call.method;
        switch (method) {
            case Constants.channels.GENERAL_METHOD_INTENT_ACTION_VIEW:
                result.success(GeneralHandler.isIntentActionView(activity));
                break;
            case Constants.channels.GENERAL_METHOD_KILL_ACTIVITY:
                activity.finish();
                break;
            default:
                result.notImplemented();
                Log.e(Constants.LogTag, "generalChannel: Invalid method name call from Dart code");
        }
    }
}