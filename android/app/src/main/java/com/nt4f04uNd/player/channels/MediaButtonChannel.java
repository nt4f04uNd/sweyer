package com.nt4f04uNd.player.channels;

import android.content.Context;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;

/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.view.FlutterView;

public class MediaButtonChannel implements MethodCallHandler {
    public static void init(FlutterView view) {
        channel = new MethodChannel(view, Constants.MEDIABUTTON_CHANNEL_STREAM);
        channel.setMethodCallHandler(new MediaButtonChannel());
        MediaButtonHandler.addListener(new ImplementedOnMediaButtonListener());
    }
    public static void kill(){
        MediaButtonHandler.release();
    }

    private static MethodChannel channel;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        result.notImplemented();
    }

    private static class ImplementedOnMediaButtonListener extends com.nt4f04uNd.player.handlers.OnMediaButtonListener {

        @Override
        protected void onAudioTrack() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_AUDIO_TRACK);
        }

        @Override
        protected void onFastForward() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_FAST_FORWARD);
        }

        @Override
        protected void onRewind() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_REWIND);
        }

        @Override
        protected void onNext() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_NEXT);
        }

        @Override
        protected void onPrevious() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PREVIOUS);
        }

        @Override
        protected void onPlayPause() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PLAY_PAUSE);
        }

        @Override
        protected void onPlay() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_PLAY);
        }

        @Override
        protected void onStop() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_STOP);
        }

        @Override
        protected void onHook() {
            channel.invokeMethod(Constants.MEDIABUTTON_METHOD_CLICK,
                    Constants.MEDIABUTTON_METHOD_CLICK_ARG_HOOK);
        }
    }
}
