/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.PlaylistHandler;
import com.nt4f04uNd.sweyer.handlers.ServiceHandler;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.util.HashMap;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class ServiceChannel implements MethodChannel.MethodCallHandler {

    public static void init(FlutterView view) {
        if (channel == null) {
            channel = new MethodChannel(view, Constants.channels.SERVICE_CHANNEL_STREAM);
            channel.setMethodCallHandler(new ServiceChannel());
        }
    }

    public static void kill() {
        channel = null;
    }

    @Nullable
    private static MethodChannel channel;

    @Override
    public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
        final String method = call.method;
        switch (method) {
            case Constants.channels.SERVICE_METHOD_STOP_SERVICE:
                ServiceHandler.stopService();
                break;
            case Constants.channels.SERVICE_METHOD_SEND_SONG:
                PlaylistHandler.playingSong = Song.fromJson(new JSONObject((HashMap) call.argument("song")));
                break;
            default:
                result.notImplemented();
                Log.e(Constants.LogTag, "generalChannel: Invalid method name call from Dart code");
        }
        result.success(1);
    }

}
