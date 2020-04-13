/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.FetchHandler;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class ContentChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view) {
        if (channel == null) {
            channel = new MethodChannel(view, Constants.channels.content.CHANNEL_NAME);
            channel.setMethodCallHandler(new ContentChannel());
        }
    }

    public static void kill() {
        channel = null;
    }

    @Nullable
    public static MethodChannel channel;

    @Override
    public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {
        // Note: this method is invoked on the main thread.

        try {
            switch (call.method) {
                case Constants.channels.content.METHOD_RETRIEVE_SONGS: {
                    // Run method on another thread
                    new FetchHandler.TaskSearchSongs(result).execute();
                    break;
                }
                case Constants.channels.content.METHOD_RETRIEVE_ALBUMS: {
                    // Run method on another thread
                    new FetchHandler.TaskSearchAlbums(result).execute();
                    break;
                }
                case Constants.channels.content.METHOD_DELETE_SONGS: {
                    FetchHandler.deleteSongs(call.argument("songDataList"));
                    result.success(null);
                    break;
                }
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("CONTENT_CHANNEL_ERROR", e.getMessage(), e.getStackTrace());
        }
    }

}
