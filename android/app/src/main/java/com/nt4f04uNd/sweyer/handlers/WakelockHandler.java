package com.nt4f04uNd.sweyer.handlers;

import android.content.Context;
import android.os.PowerManager;

import com.nt4f04uNd.sweyer.Constants;

public abstract class WakelockHandler {
    private static PowerManager.WakeLock wl;

    public static void acquire() {
        if (wl == null) {
            PowerManager powerManager = (PowerManager) GeneralHandler.getAppContext().getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) return;
            wl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":wakeLockTag");
            wl.acquire();

        }
    }

    public static void release() {
        if (wl != null && wl.isHeld()) {
            wl.release();
            wl = null;
        }
    }
}
