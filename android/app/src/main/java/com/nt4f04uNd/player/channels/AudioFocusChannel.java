package com.nt4f04uNd.player.channels;

import android.content.Context;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.view.FlutterView;

public class AudioFocusChannel implements MethodCallHandler {
    public static void init(FlutterView view, Context appContext) {
        channel = new MethodChannel(view, Constants.AUDIO_FOCUS_CHANNEL);
        channel.setMethodCallHandler(new AudioFocusChannel());
        AudioFocusHandler.init(appContext,new ImplementedOnAudioFocusListener());
    }
    public static void kill(){
        AudioFocusHandler.abandonFocus();
    }

    public static MethodChannel channel;

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

    static private class ImplementedOnAudioFocusListener extends com.nt4f04uNd.player.handlers.OnAudioFocusChangeListener {
        @Override
        protected void onFocusGain() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN);
            channel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_GAIN
            );
        }

        @Override
        protected void onFocusLoss() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS);
            channel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS
            );
        }

        @Override
        protected void onFocusLossTransient() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT);
            channel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT
            );
        }

        @Override
        protected void onFocusLossTransientCanDuck() {
            Log.w(Constants.LogTag, Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK);
            channel.invokeMethod(
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE,
                    Constants.AUDIOFOCUS_METHOD_FOCUS_CHANGE_ARG_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK
            );
        }
    }

}
