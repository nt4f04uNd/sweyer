/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.app.ActivityManager;
import android.app.Service;
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


    /**
     * Handler is a workaround to run this code on UI thread, or whatever, idk exactly
     * But if just call `startService` from `ServiceChannel` handler - it will give strange error that startForeground hasn't called
     */
    public static void startService(boolean sticky) {
        new Handler().post(() -> {
            Intent startIntent = intentForService;
            if (sticky) // TODO: move to consts
                startIntent.putExtra("STICKINESS", Service.START_STICKY);
            else
                startIntent.putExtra("STICKINESS", Service.START_NOT_STICKY);

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
        new Handler().post(() -> GeneralHandler.getAppContext().stopService(intentForService));
    }

}
