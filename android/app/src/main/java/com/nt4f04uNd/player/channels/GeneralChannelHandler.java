package com.nt4f04uNd.player.channels;

import android.app.Activity;
import android.content.Intent;

import com.nt4f04uNd.player.Constants;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class GeneralChannelHandler implements MethodChannel.MethodCallHandler {
    public GeneralChannelHandler(Activity activity) {
        this.activity = activity;
    }

    private Activity activity;

    /**
     * Check for if Intent action is VIEW
     */
    private boolean isIntentActionView() {
        Intent intent = activity.getIntent();
        return Intent.ACTION_VIEW.equals(intent.getAction());
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        final String method = call.method;
        if (method.equals(Constants.GENERAL_METHOD_INTENT_ACTION_VIEW)) {
            result.success(isIntentActionView());
        } else if (method.equals(Constants.GENERAL_METHOD_KILL_ACTIVITY)) {
            activity.finish();
        } else {
            result.notImplemented();
            Log.e(Constants.LogTag, "generalChannel: Invalid method name call from Dart code");
        }
    }
}