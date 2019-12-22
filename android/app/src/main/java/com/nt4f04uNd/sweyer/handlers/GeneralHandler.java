/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.channels.PlayerChannel;

import org.jetbrains.annotations.NotNull;

import io.flutter.Log;

/**
 * Just a junk yard of various utils methods
 * Also a container for an application context
 */
public abstract class GeneralHandler {

    public static void init(Context appContext) {
        GeneralHandler.appContext = appContext;
    }

    private static Context appContext;

    public static Context getAppContext() {
        if (appContext == null)
            Log.e(Constants.LogTag, "GeneralHandler is not initialized! Can't get app context!");
        return appContext;
    }

    public static boolean activityExists() {
        return PlayerChannel.channel != null;
    }

    /**
     * Check for if Intent action is VIEW
     */
    public static boolean isIntentActionView(Activity activity) {
        Intent intent = activity.getIntent();
        return Intent.ACTION_VIEW.equals(intent.getAction());
    }

    /**
     * Checks system theme and returns true if it's dark
     */
    public static boolean isSystemThemeDark() {
        int nightModeFlags = appContext.getResources().getConfiguration().uiMode &
                Configuration.UI_MODE_NIGHT_MASK;

        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES;
        // Else `Configuration.UI_MODE_NIGHT_NO` or `Configuration.UI_MODE_NIGHT_UNDEFINED`
    }


    /**
     * A shortcut to a log function with set app log prefix
     */
    public static void print(@NotNull String msg) {
        Log.w(Constants.LogTag, msg);
    }

}