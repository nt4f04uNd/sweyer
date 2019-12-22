/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;

import com.nt4f04uNd.sweyer.player.PlayerForegroundService;


/**
 * Handler for all the interaction between service and dart code
 */
public abstract class ServiceHandler {

    private static Intent intentForService;

    public static void init() {
        if (intentForService == null)
            ServiceHandler.intentForService = new Intent(GeneralHandler.getAppContext(), PlayerForegroundService.class);
    }


    private static boolean isServiceRunning() {
        ActivityManager manager = (ActivityManager) GeneralHandler.getAppContext().getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (PlayerForegroundService.class.getName().equals(service.service.getClassName())) {
                return true;
            }
        }
        return false;
    }


    /**
     * Handler is a workaround to run this code on UI thread, or whatever, idk exactly
     * But if just call `startService` from `ServiceChannel` handler - it will give strange error that startForeground hasn't called
     */
    public static void startService() {
        if (!isServiceRunning())
            new Handler().post(() -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    GeneralHandler.getAppContext().startForegroundService(intentForService);
                else
                    GeneralHandler.getAppContext().startService(intentForService);
            });
    }

    /**
     * Same as startService
     */
    public static void stopService() {
        if (isServiceRunning())
            new Handler().post(() -> GeneralHandler.getAppContext().stopService(intentForService));
    }

}
