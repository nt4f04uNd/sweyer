/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

import android.content.Context;
import android.net.Uri;

abstract class PlayerAbstract {

    protected static boolean objectEquals(Object o1, Object o2) {
        return o1 == null && o2 == null || o1 != null && o1.equals(o2);
    }

    abstract void play(Context appContext);

    abstract void stop();

    abstract void release();

    abstract void pause();

    abstract void setUri(Uri uri);

    abstract void setVolume(double volume);

    abstract void setAwake(Context context, boolean stayAwake);

    abstract void setReleaseMode(ReleaseMode releaseMode);

    abstract double getVolume();

    abstract int getDuration();

    abstract int getCurrentPosition();

    abstract ReleaseMode getReleaseMode();

    abstract boolean isActuallyPlaying();

    abstract boolean isUriNull();

    /**
     * Seek operations cannot be called until after the player is ready.
     */
    abstract void seek(int position);
}
