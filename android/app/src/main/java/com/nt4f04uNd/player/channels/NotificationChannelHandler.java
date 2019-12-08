package com.nt4f04uNd.player.channels;

import android.content.Context;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.NotificationHandler;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

public class NotificationChannelHandler implements MethodCallHandler {
    public NotificationChannelHandler(Context appContext) {
        this.appContext = appContext;
    }

    private Context appContext;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        final String method = call.method;
        if (method.equals(Constants.NOTIFICATION_METHOD_SHOW)) {
            NotificationHandler.buildNotification(appContext,
                    call.argument(Constants.NOTIFICATION_METHOD_SHOW_ARG_TITLE),
                    call.argument(Constants.NOTIFICATION_METHOD_SHOW_ARG_ARTIST),
                    call.argument(Constants.NOTIFICATION_METHOD_SHOW_ARG_ALBUM_ART_BYTES),
                    call.argument(Constants.NOTIFICATION_METHOD_SHOW_ARG_IS_PLAYING));
            result.success("");
        } else if (method.equals(Constants.NOTIFICATION_METHOD_CLOSE)) {
            NotificationHandler.closeNotification();
            result.success("");
        } else {
            result.notImplemented();
            Log.e(Constants.LogTag, "notificationChannel: Invalid method name call from Dart code");
        }
    }
}
