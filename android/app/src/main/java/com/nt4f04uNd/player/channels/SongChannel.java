package com.nt4f04uNd.player.channels;

import android.content.Context;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.SongHandler;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class SongChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view, Context appContext) {
        SongChannel.appContext = appContext;
        channel = new MethodChannel(view, Constants.SONGS_CHANNEL_STREAM);
        channel.setMethodCallHandler(new SongChannel());
    }

    public static MethodChannel channel;
    private static Context appContext;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // Note: this method is invoked on the main thread.
        final String method = call.method;
        if (method.equals(Constants.SONGS_METHOD_METHOD_RETRIEVE_SONGS)) {
            // Run method on another thread
            new SongHandler.TaskSearchSongs(appContext).execute();
            result.success("");
        } else {
            Log.e(Constants.LogTag, "songsChannel: Invalid method name call from Dart code");
        }
    }
}
