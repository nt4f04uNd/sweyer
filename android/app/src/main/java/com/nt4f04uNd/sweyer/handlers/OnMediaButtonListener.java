/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

/**
 * Class similar to an `OnAudioFocusChangeListener`
 * Needed to use in `MediaSessionHandler` and call implemented callbacks
 *
 * Key codes from docs https://developer.android.com/reference/android/view/KeyEvent :
 *
 *      Key code                            What should be done     Int
 *
 *      KEYCODE_MEDIA_AUDIO_TRACK           NEXT             	    222
 *      KEYCODE_MEDIA_FAST_FORWARD          FAST FORWARD 	        90
 *      KEYCODE_MEDIA_REWIND	            REWIND		            89
 *      KEYCODE_MEDIA_NEXT	                NEXT 		            87
 *      KEYCODE_MEDIA_PREVIOUS	            PREV		            88
 *      KEYCODE_MEDIA_PLAY	                RESUME 	 	            126
 *      KEYCODE_MEDIA_PAUSE	                PAUSE		            127
 *      KEYCODE_MEDIA_PLAY_PAUSE            PLAY/PAUSE		        85
 *      KEYCODE_MEDIA_STOP	                PAUSE ???		        86
 *      KEYCODE_HEADSETHOOK	                HOOK		            79
 *
 */
public abstract class OnMediaButtonListener {
    public OnMediaButtonListener() {
    }

    /**
     * From docs: "Switches the audio tracks."
     */
    protected void onAudioTrack() {
    }

    protected void onFastForward() {
    }

    protected void onRewind() {
    }

    protected void onNext() {
    }

    protected void onPrevious() {
    }

    protected void onPlay() {
    }

    protected void onPause() {
    }

    protected void onPlayPause() {
    }


    protected void onStop() {
    }

    /**
     * Single button on headphones
     */
    protected void onHook() {
    }
}
