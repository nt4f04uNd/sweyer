package com.nt4f04uNd.sweyer.handlers;

import android.content.Context;
import android.os.PowerManager;

import com.nt4f04uNd.sweyer.Constants;

public abstract class WakelockHandler {
    private static PowerManager.WakeLock wl;
    /**
     * Whether wake lock has timeout
     */
    private static boolean timed = false;

    /**
     *  1 minute wake lock timeout
     */
    private static final int TIMEOUT = 60000;

    /**
     * Acquires (or switches) wake lock without timeout
     */
    public static void acquire() {
        if (wl == null) {
            PowerManager powerManager = (PowerManager) GeneralHandler.getAppContext().getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) return;
            wl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":wakeLockTag");
            wl.acquire();

            timed = false;
        } else if (timed) { // Switch to wake lock to not have timeout
            PowerManager powerManager = (PowerManager) GeneralHandler.getAppContext().getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) return;
            PowerManager.WakeLock tempWl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":temp-wakeLockTag");

            tempWl.acquire();
            wl.release();
            wl.acquire();
            tempWl.release();

            timed = false;
        }
    }

    /**
     * Acquires (or switches) wake lock with timeout
     */
    public static void acquireTimed() {
        if (wl == null) {
            PowerManager powerManager = (PowerManager) GeneralHandler.getAppContext().getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) return;
            wl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":wakeLockTag");
            wl.acquire(TIMEOUT);

            timed = true;
        } else if (!timed) { // Switch to wake lock to have timeout
            PowerManager powerManager = (PowerManager) GeneralHandler.getAppContext().getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) return;
            PowerManager.WakeLock tempWl = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.PACKAGE_NAME + ":temp-wakeLockTag");

            tempWl.acquire();
            wl.release();
            wl.acquire(TIMEOUT);
            tempWl.release();

            timed = true;
        }
    }

    public static void release() {
        if (wl != null && wl.isHeld()) {
            wl.release();
            wl = null;
        }
    }
}
