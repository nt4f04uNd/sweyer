/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.channels;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.handlers.PlayerHandler;
import com.nt4f04uNd.sweyer.player.ReleaseMode;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.util.HashMap;

import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class PlayerChannel implements MethodChannel.MethodCallHandler {

    public static void init(FlutterView view) {
        if (channel == null) {
            channel = new MethodChannel(view, Constants.channels.PLAYER_CHANNEL_STREAM);
            channel.setMethodCallHandler(new PlayerChannel());
        }
    }

    public static void kill() {
        channel = null;
    }

    @Nullable
    public static MethodChannel channel;


    /** NOTE that this might be called when flutter view is detached
     *  Normally, `kill` method will set channel to null
     *  But `onDestroy` method is not guaranteed to be called, so sometimes it won't happen
     *
     *  AFAIK this isn't something bad and not an error, but warning
     */
    public static void invokeMethod(String method, Object arguments) {
        if (channel != null) {
            channel.invokeMethod(method, arguments);
        }
    }

    @Override
    public void onMethodCall(@NotNull final MethodCall call, @NotNull final MethodChannel.Result response) {
        try {
            handleMethodCall(call, response);
        } catch (Exception e) {
            Log.e(Constants.LogTag, "Unexpected error!", e);
            PlayerHandler.handleError(e);
            response.error("Unexpected error!", e.getMessage(), e);
        }
    }

    private static void handleMethodCall(final MethodCall call, final MethodChannel.Result result) {
        // TODO: add getVolume
        switch (call.method) {
            case "play": {
                PlayerHandler.play(
                        Song.fromJson(new JSONObject((HashMap) call.argument("song"))),
                        call.argument("volume"),
                        call.argument("position"),
                        call.argument("respectSilence"),
                        call.argument("isLocal"),
                        call.argument("stayAwake")
                );
                break;
            }
            case "resume": {
                PlayerHandler.resume();
                break;
            }
            case "pause": {
                PlayerHandler.pause();
                break;
            }
            case "stop": {
                PlayerHandler.stop();
                break;
            }
            case "release": {
                PlayerHandler.release();
                break;
            }
            case "seek": {
                PlayerHandler.seek(call.argument("position"));
                break;
            }
            case "setVolume": {
                PlayerHandler.setVolume(call.argument("volume"));
                break;
            }
            case "setUrl": {
                PlayerHandler.setUrl(call.argument("url"), call.argument("isLocal"));
                break;
            }
            case "isPlaying": {
                result.success(PlayerHandler.isPlaying());
                return;
            }
            case "getDuration": {
                result.success(PlayerHandler.getDuration());
                return;
            }
            case "getCurrentPosition": {
                result.success(PlayerHandler.getCurrentPosition());
                return;
            }
            case "setReleaseMode": {
                final String releaseModeName = call.argument("releaseMode");
                final ReleaseMode releaseMode = ReleaseMode.valueOf(releaseModeName.substring("ReleaseMode.".length()));
                PlayerHandler.setReleaseMode(releaseMode);
                break;
            }
            default: {
                result.notImplemented();
                return;
            }
        }
        result.success(1);
    }


}
