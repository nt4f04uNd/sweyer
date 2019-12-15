package com.nt4f04uNd.player.channels;

import android.app.Activity;
import android.os.Handler;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.ServiceHandler;

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
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        final String method = call.method;
        switch (method) {
            case Constants.channels.SERVICE_METHOD_START_SERVICE:
                ServiceHandler.startService();
                break;
            case Constants.channels.SERVICE_METHOD_STOP_SERVICE:
                ServiceHandler.stopService();
                break;
            default:
                result.notImplemented();
                Log.e(Constants.LogTag, "generalChannel: Invalid method name call from Dart code");
        }
    }

}
