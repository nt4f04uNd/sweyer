/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.nt4f04und.sweyer.Constants;
import android.util.Log;

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

    /**
     * Check for if Intent action is VIEW
     */
    public static boolean isIntentActionView(Activity activity) {
        Intent intent = activity.getIntent();
        return Intent.ACTION_VIEW.equals(intent.getAction());
    }
}