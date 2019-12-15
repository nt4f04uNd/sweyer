/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.channels;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.view.FlutterView;

public class AudioFocusChannel implements MethodCallHandler {
    public static void init(FlutterView view) {
        channel = new MethodChannel(view, Constants.AUDIO_FOCUS_CHANNEL);
        channel.setMethodCallHandler(new AudioFocusChannel());
    }

    private static MethodChannel channel;

    public static void invokeMethod(String method, String arg) {
        if (channel != null) channel.invokeMethod(method, arg);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // NOTE: this method is invoked on the main thread.
        final String method = call.method;
        if (method.equals(Constants.AUDIOFOCUS_METHOD_REQUEST_FOCUS)) {
            result.success(AudioFocusHandler.requestFocus());
        } else if (method.equals(Constants.AUDIOFOCUS_METHOD_ABANDON_FOCUS)) {
            result.success(AudioFocusHandler.abandonFocus());
        } else {
            result.notImplemented();
            Log.e(Constants.LogTag, "audioFocusChannel: Invalid method name call from Dart code");
        }
    }


}
