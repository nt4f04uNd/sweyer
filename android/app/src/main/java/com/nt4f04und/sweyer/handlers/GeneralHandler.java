package com.nt4f04und.sweyer.handlers;

import android.content.Context;
import android.util.Log;

import com.nt4f04und.sweyer.Constants;

public abstract class GeneralHandler {
    public static void init(Context appContext) {
        GeneralHandler.appContext = appContext;
    }
    private static Context appContext;
    public static Context getAppContext() {
        if (appContext == null) {
            Log.e(Constants.LogTag, "GeneralHandler is not initialized! Can't get app context!");
        }
        return appContext;
    }
    public static Long getLong(Object rawValue) {
        if (rawValue instanceof Long) {
            return (Long) rawValue;
        } else if (rawValue instanceof Integer) {
            return Long.valueOf((Integer) rawValue);
        } else {
            throw new IllegalArgumentException();
        }
    }
}