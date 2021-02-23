/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.handlers;

import static android.content.Context.MODE_PRIVATE;

import android.content.SharedPreferences;

public class PrefsHandler {
    // These are coming from from `shared_preferences` flutter library
    private static String SHARED_PREFERENCES_NAME = "FlutterSharedPreferences";
    private static String PREFIX = "flutter.";

    private static SharedPreferences getPrefs() { // Will get shared preferences from flutter package `shared_preferences`
        return GeneralHandler.getAppContext().getSharedPreferences(SHARED_PREFERENCES_NAME, MODE_PRIVATE);
    }

    /** Position in seconds */
    public static void setSongPosition(long value) {
        getPrefs().edit().putLong(PREFIX + "song_position", value).apply();
    }

    // **************** Song id *************************
    public static void setSongId(long value) {
        getPrefs().edit().putLong(PREFIX + "song_id", value).apply();
    }
    public static long getSongId() {
        return getPrefs().getLong(PREFIX + "song_id", 0);
    }

    // **************** Is playing *************************
    public static void setSongIsPlaying(boolean value) {
        getPrefs().edit().putBoolean(PREFIX + "song_is_playing", value).apply();
    }
    public static boolean getSongIsPlaying() {
        return getPrefs().getBoolean(PREFIX + "song_is_playing", false);
    }

    // **************** Loop mode *************************
    public static void setLoopMode(boolean value) {
        getPrefs().edit().putBoolean(PREFIX + "loop_mode", value).apply();
    }
    public static boolean getLoopMode() {
        return getPrefs().getBoolean(PREFIX + "loop_mode", false);
    }

    // **************** Setting primary color *************************
    public static long getSettingPrimaryColor() {
        return getPrefs().getLong(PREFIX + "setting_primary_color", 0xFF7C4DFF);
    }
}
