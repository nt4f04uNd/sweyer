/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

/** Class similar to an `OnAudioFocusChangeListener`
 *  Needed to use in `MediaButtonHandler` and call implemented callbacks
 * */
public abstract class OnMediaButtonListener {
    public OnMediaButtonListener(){}
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

    protected void onPlayPause() {
    }

    protected void onPlay() {
    }

    protected void onStop() {
    }

    /**
     * Single button on headphones
     */
    protected void onHook() {
    }
}
