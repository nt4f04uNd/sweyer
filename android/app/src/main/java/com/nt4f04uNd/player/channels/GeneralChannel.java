package com.nt4f04uNd.player.channels;

import android.app.Activity;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.GeneralHandler;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class GeneralChannel implements MethodChannel.MethodCallHandler {
    public static void init(FlutterView view, Activity activity) {
        GeneralChannel.activity = activity;
        channel = new MethodChannel(view, Constants.GENERAL_CHANNEL_STREAM);
        channel.setMethodCallHandler(new GeneralChannel());
    }

    public static MethodChannel channel;
    private static Activity activity;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        final String method = call.method;
        if (method.equals(Constants.GENERAL_METHOD_INTENT_ACTION_VIEW)) {
            result.success(GeneralHandler.isIntentActionView(activity));
        } else if (method.equals(Constants.GENERAL_METHOD_KILL_ACTIVITY)) {
            activity.finish();
        } else {
            result.notImplemented();
            Log.e(Constants.LogTag, "generalChannel: Invalid method name call from Dart code");
        }
    }
}