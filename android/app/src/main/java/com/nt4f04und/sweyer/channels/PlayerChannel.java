/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.channels;

import android.util.Log;

import com.google.gson.Gson;
import com.nt4f04und.sweyer.handlers.NotificationHandler;
import com.nt4f04und.sweyer.handlers.PlayerHandler;
import com.nt4f04und.sweyer.handlers.QueueHandler;
import com.nt4f04und.sweyer.player.Song;
import com.nt4f04und.sweyer.services.MusicService;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public enum PlayerChannel {
   instance;

   public void init(BinaryMessenger messenger) {
      if (channel == null) {
         channel = new MethodChannel(messenger, "player_channel");
         channel.setMethodCallHandler(this::onMethodCall);
      }
   }

   public void kill() {
      channel = null;
   }

   @Nullable
   public MethodChannel channel;

   /**
    * This might be called when flutter view is detached
    * Normally, `kill` method will set channel to null
    * But `onDestroy` method is not guaranteed to be called, so sometimes it won't happen
    * AFAIK this isn't something bad and not an error, but warning
    */
   public void invokeMethod(String method, Object arguments) {
      if (channel != null) {
         channel.invokeMethod(method, arguments);
      }
   }

   public void onMethodCall(@NotNull final MethodCall call, @NotNull final MethodChannel.Result response) {
      try {
         handleMethodCall(call, response);
      } catch (Exception e) {
         PlayerHandler.handleError(e);
         response.error("NATIVE_PLAYER_ERROR", e.getMessage(), Log.getStackTraceString(e));
      }
   }

   private void handleMethodCall(final MethodCall call, final MethodChannel.Result result) {
      switch (call.method) {
         case "clearIdMap": {
            QueueHandler.initIdMap();
            QueueHandler.idMap.clear();
            break;
         }
         case "play": {
            PlayerHandler.play(
                    new Gson().fromJson((String) call.argument("song"), Song.class),
                    call.argument("duplicate")
            );
            break;
         }
         case "setUri": {
            Song song = new Gson().fromJson((String) call.argument("song"), Song.class);
            Boolean duplicate = call.argument("duplicate");
            if (duplicate) {
               QueueHandler.handleDuplicate(song, duplicate);
            }
            QueueHandler.setCurrentSong(song);
            if (MusicService.isRunning) {
               NotificationHandler.updateNotification(PlayerHandler.isPlaying(), PlayerHandler.isLooping());
            }
            PlayerHandler.setUri(song.id);
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
         case "setLooping": {
            final boolean looping = call.argument("looping");
            PlayerHandler.setLooping(looping);
            break;
         }
         case "isPlaying": {
            result.success(PlayerHandler.isPlaying());
            return;
         }
         case "isLooping": {
            result.success(PlayerHandler.isLooping());
            return;
         }
         case "getVolume": {
            result.success(PlayerHandler.getVolume());
            return;
         }
         case "getPosition": {
            result.success(PlayerHandler.getPosition());
            return;
         }
         case "getDuration": {
            result.success(PlayerHandler.getDuration());
            return;
         }
         default: {
            result.notImplemented();
            return;
         }
      }
      result.success(1);
   }


}
