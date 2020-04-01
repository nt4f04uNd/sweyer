/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.FetchHandler;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.util.HashMap;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class SongChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view) {
        if (channel == null) {
            channel = new MethodChannel(view, Constants.channels.songs.CHANNEL_NAME);
            channel.setMethodCallHandler(new SongChannel());
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
        switch (call.method) {
            case Constants.channels.songs.METHOD_RETRIEVE_SONGS: {
                // Run method on another thread
                new FetchHandler.TaskSearchSongs(channel).execute();
                result.success("");
                break;
            }
            case Constants.channels.songs.METHOD_DELETE_SONGS: {
                FetchHandler.deleteSongs(call.argument("songDataList"));
                break;
            }
            default:
                Log.e(Constants.LogTag, "songsChannel: Invalid method name call from Dart code");
        }
    }

}
