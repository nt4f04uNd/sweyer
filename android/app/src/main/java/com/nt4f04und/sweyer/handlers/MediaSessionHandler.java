/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.support.v4.media.session.MediaSessionCompat;

import androidx.annotation.Nullable;

import com.nt4f04und.sweyer.Constants;

public class MediaSessionHandler {
   private static MediaSession mediaSession;
   private static PlaybackState.Builder playbackState;

   public static void init() {
      if (mediaSession == null) {
         playbackState = new PlaybackState.Builder();
         mediaSession = new MediaSession(GeneralHandler.getAppContext(), Constants.PACKAGE_NAME + ":mediaSessionTag");
         mediaSession.setCallback(new MediaSession.Callback() {
            @Override
            public void onFastForward() {
               PlayerHandler.fastForward();
            }

            @Override
            public void onPause() {
               PlayerHandler.pause();
            }

            @Override
            public void onPlay() {
               PlayerHandler.resume();
            }

            @Override
            public void onRewind() {
               PlayerHandler.rewind();
            }

            @Override
            public void onSeekTo(long pos) {
               PlayerHandler.seek((int) pos);
            }

            @Override
            public void onSkipToNext() {
               PlayerHandler.playNext();
            }

            @Override
            public void onSkipToPrevious() {
               PlayerHandler.playPrev();
            }

            @Override
            public void onStop() {
               PlayerHandler.stop();
            }
         });
         mediaSession.setFlags(MediaSession.FLAG_HANDLES_MEDIA_BUTTONS | MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS);
         updatePlaybackState();
         mediaSession.setActive(true);
      }
   }

   @Nullable
   public static MediaSessionCompat.Token getToken() {
      if (mediaSession == null) return null;
      return MediaSessionCompat.Token.fromToken(mediaSession.getSessionToken());
   }

   public static void setMetadata(MediaMetadata metaData) {
      if (mediaSession != null) {
         mediaSession.setMetadata(metaData);
      }
   }

   public static void updatePlaybackState() {
      init();
      playbackState.setActions(getActions())
              .setState(PlayerHandler.isPlaying() ? PlaybackState.STATE_PLAYING : PlaybackState.STATE_PAUSED,
                      PlayerHandler.getPosition(),
                      PlayerHandler.isPlaying() ? 1.0f : 0.0f);
      mediaSession.setPlaybackState(playbackState.build());
   }

   public static long getActions() {
      long actions = PlaybackState.ACTION_FAST_FORWARD
              | PlaybackState.ACTION_PLAY_PAUSE
              | PlaybackState.ACTION_REWIND
              | PlaybackState.ACTION_SEEK_TO
              | PlaybackState.ACTION_SKIP_TO_NEXT
              | PlaybackState.ACTION_SKIP_TO_PREVIOUS
              | PlaybackState.ACTION_STOP;

      if (PlayerHandler.isPlaying()) {
         actions |= PlaybackState.ACTION_PAUSE;
      } else {
         actions |= PlaybackState.ACTION_PLAY;
      }
      // todo: these actions
//               |PlaybackState.ACTION_PLAY_FROM_MEDIA_ID
//              | PlaybackState.ACTION_PLAY_FROM_SEARCH
//              | PlaybackState.ACTION_PLAY_FROM_URI
//
//              | PlaybackState.ACTION_PREPARE
//              | PlaybackState.ACTION_PREPARE_FROM_MEDIA_ID
//              | PlaybackState.ACTION_PREPARE_FROM_SEARCH
//              | PlaybackState.ACTION_PREPARE_FROM_URI
//              | PlaybackState.ACTION_SET_RATING
//              | PlaybackState.ACTION_SKIP_TO_QUEUE_ITEM;
      return actions;
   }

   public static void release() {
      mediaSession.release();
      mediaSession = null;
   }
}
