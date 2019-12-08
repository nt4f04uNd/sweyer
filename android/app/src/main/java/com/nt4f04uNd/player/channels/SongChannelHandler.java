package com.nt4f04uNd.player.channels;

import android.content.Context;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.MainActivity;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SongChannelHandler implements MethodChannel.MethodCallHandler {
    public SongChannelHandler(Context appContext) {
        this.appContext = appContext;
    }

    private Context appContext;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // Note: this method is invoked on the main thread.
        final String method = call.method;
        if (method.equals(Constants.SONGS_METHOD_METHOD_RETRIEVE_SONGS)) {
            // Run method on another thread
            new MainActivity.TaskSearchSongs(appContext).execute();
            result.success("");
        } else {
            Log.e(Constants.LogTag, "songsChannel: Invalid method name call from Dart code");
        }
    }
}
