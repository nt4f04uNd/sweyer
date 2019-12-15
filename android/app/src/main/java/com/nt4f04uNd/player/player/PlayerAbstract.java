/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.player;

import android.content.Context;

abstract class PlayerAbstract {

    protected static boolean objectEquals(Object o1, Object o2) {
        return o1 == null && o2 == null || o1 != null && o1.equals(o2);
    }

    abstract void play();

    abstract void stop();

    abstract void release();

    abstract void pause();

    abstract void setUrl(String url, boolean isLocal);

    abstract void setVolume(double volume);

    abstract void configAttributes(boolean respectSilence, boolean stayAwake, Context context);

    abstract void setReleaseMode(ReleaseMode releaseMode);

    abstract double getVolume();

    abstract int getDuration();

    abstract int getCurrentPosition();

    abstract boolean isActuallyPlaying();

    /**
     * Seek operations cannot be called until after the player is ready.
     */
    abstract void seek(int position);
}
