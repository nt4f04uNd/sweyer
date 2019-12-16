/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.MainActivity;
import com.nt4f04uNd.player.player.PlayerForegroundService;

import androidx.annotation.Nullable;
import io.flutter.Log;

public abstract class GeneralHandler {

    public static void init(Context appContext, @Nullable Context activityContext) {
        GeneralHandler.appContext = appContext;
    }

    private static Context appContext;

    public static Context getAppContext() {
        if (appContext == null)
            Log.e(Constants.LogTag, "GeneralHandler is not initialized! Can't get app context!");
        return appContext;
    }

    public static boolean activityExists() {
        return new Intent(appContext, MainActivity.class).resolveActivityInfo(appContext.getPackageManager(), 0) != null;
    }

    /**
     * Check for if Intent action is VIEW
     */
    public static boolean isIntentActionView(Activity activity) {
        Intent intent = activity.getIntent();
        return Intent.ACTION_VIEW.equals(intent.getAction());
    }

}