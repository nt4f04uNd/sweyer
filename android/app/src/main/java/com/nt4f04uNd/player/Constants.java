/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player;

public class Constants {
    public static final String LogTag = "com.nt4f04und.player";

    public static final class player {
        public static final long POSITION_UPDATE_PERIOD_MS = 200;

    }

    public static final class channels {

        public static final String PLAYER_CHANNEL_STREAM = "PLAYER_CHANNEL_STREAM";
        public static final String EVENT_CHANNEL_STREAM = "EVENT_CHANNEL_STREAM";
        public static final String GENERAL_CHANNEL_STREAM = "GENERAL_CHANNEL_STREAM";
        public static final String SERVICE_CHANNEL_STREAM = "SERVICE_CHANNEL_STREAM";
        public static final String SONGS_CHANNEL_STREAM = "SONGS_CHANNEL_STREAM";


        // Events
        public static final String EVENT_BECOME_NOISY = "com.nt4f04uNd.player.EVENT_BECAME_NOISY";

        public static final String EVENT_NOTIFICATION_CHANNEL_ID = "com.nt4f04uNd.player.EVENT_NOTIFICATION_CHANNEL";
        public static final String EVENT_NOTIFICATION_INTENT_PLAY = "com.nt4f04uNd.player.EVENT_NOTIFICATION_PLAY";
        public static final String EVENT_NOTIFICATION_INTENT_PAUSE = "com.nt4f04uNd.player.EVENT_NOTIFICATION_PAUSE";
        public static final String EVENT_NOTIFICATION_INTENT_NEXT = "com.nt4f04uNd.player.EVENT_NOTIFICATION_NEXT";
        public static final String EVENT_NOTIFICATION_INTENT_PREV = "com.nt4f04uNd.player.EVENT_NOTIFICATION_PREV";

        public static final String EVENT_AUDIOFOCUS_GAIN = "EVENT_AUDIOFOCUS_GAIN";
        public static final String EVENT_AUDIOFOCUS_LOSS = "EVENT_AUDIOFOCUS_LOSS";
        public static final String EVENT_AUDIOFOCUS_LOSS_TRANSIENT = "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
        public static final String EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

        // Media button events
        // see
        // https://developer.android.com/reference/android/view/KeyEvent.html#KEYCODE_MEDIA_AUDIO_TRACK
        // for key codes docs
        public static final String EVENT_MEDIABUTTON_AUDIO_TRACK = "EVENT_MEDIABUTTON_AUDIO_TRACK";
        public static final String EVENT_MEDIABUTTON_FAST_FORWARD = "EVENT_MEDIABUTTON_FAST_FORWARD";
        public static final String EVENT_MEDIABUTTON_REWIND = "EVENT_MEDIABUTTON_REWIND";
        public static final String EVENT_MEDIABUTTON_NEXT = "EVENT_MEDIABUTTON_NEXT";
        public static final String EVENT_MEDIABUTTON_PREVIOUS = "EVENT_MEDIABUTTON_PREVIOUS";
        public static final String EVENT_MEDIABUTTON_PLAY_PAUSE = "EVENT_MEDIABUTTON_PLAY_PAUSE";
        public static final String EVENT_MEDIABUTTON_PLAY = "EVENT_MEDIABUTTON_PLAY";
        public static final String EVENT_MEDIABUTTON_STOP = "EVENT_MEDIABUTTON_STOP";
        public static final String EVENT_MEDIABUTTON_HOOK = "EVENT_MEDIABUTTON_HOOK";

        // General methods
        public static final String GENERAL_METHOD_INTENT_ACTION_VIEW = "GENERAL_METHOD_INTENT_ACTION_VIEW";
        public static final String GENERAL_METHOD_KILL_ACTIVITY = "GENERAL_METHOD_KILL_ACTIVITY";


        // Service methods
        public static final String SERVICE_METHOD_START_SERVICE = "SERVICE_METHOD_START_SERVICE";
        public static final String SERVICE_METHOD_STOP_SERVICE = "SERVICE_METHOD_STOP_SERVICE";
        public static final String SERVICE_METHOD_IS_SERVICE_RUNNING = "SERVICE_METHOD_IS_SERVICE_RUNNING";


        // Songs methods
        public static final String SONGS_METHOD_RETRIEVE_SONGS = "SONGS_METHOD_RETRIEVE_SONGS";
        public static final String SONGS_METHOD_SEND_SONGS = "SONGS_METHOD_SEND_SONGS";
    }
}