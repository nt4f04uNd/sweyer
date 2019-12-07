package com.nt4f04uNd.player;

import android.media.MediaPlayer;

public abstract class Player {
    private MediaPlayer mediaPlayer;
//
//    private void init() {
//        if (mediaPlayer == null) {
//            mediaPlayer = new MediaPlayer();
//            mediaPlayer.liste
//            mediaPlayer.setOnCompletionListener(mediaPlayer -> {
//                stopUpdatingCallbackWithPosition(true);
//                logToUI("MediaPlayer playback completed");
//                if (mPlaybackInfoListener != null) {
//                    mPlaybackInfoListener.onStateChanged(PlaybackInfoListener.State.COMPLETED);
//                    mPlaybackInfoListener.onPlaybackCompleted();
//                }
//            });
//        }
//    }
//
//
//    public void play() {
//        if (mediaPlayer != null && !mediaPlayer.isPlaying()) {
//            logToUI(String.format("playbackStart() %s",
//                    mContext.getResources().getResourceEntryName(mResourceId)));
//            mediaPlayer.start();
//            if (mPlaybackInfoListener != null) {
//                mPlaybackInfoListener.onStateChanged(PlaybackInfoListener.State.PLAYING);
//            }
//            startUpdatingCallbackWithPosition();
//        }
//    }
//
//
//    public void pause() {
//        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
//            mediaPlayer.pause();
//            if (mPlaybackInfoListener != null) {
//                mPlaybackInfoListener.onStateChanged(PlaybackInfoListener.State.PAUSED);
//            }
//        }
//    }
//
//
//    public void reset() {
//        if (mediaPlayer != null) {
//            logToUI("playbackReset()");
//            mediaPlayer.reset();
//            loadMedia(mResourceId);
//            if (mPlaybackInfoListener != null) {
//                mPlaybackInfoListener.onStateChanged(PlaybackInfoListener.State.RESET);
//            }
//            stopUpdatingCallbackWithPosition(true);
//        }
//    }
//
//    public void loadMedia(int resourceId) {
//        mResourceId = resourceId;
//
//        initializeMediaPlayer();
//
//        AssetFileDescriptor assetFileDescriptor =
//                mContext.getResources().openRawResourceFd(mResourceId);
//        try {
//            mediaPlayer.setDataSource(assetFileDescriptor);
//        } catch (Exception e) {
//            logToUI(e.toString());
//        }
//
//        try {
//            mediaPlayer.prepare();
//        } catch (Exception e) {
//            logToUI(e.toString());
//        }
//
//        initializeProgressCallback();
//    }
}
