/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer;

public class Constants {
    public static final String PACKAGE_NAME = "com.nt4f04und.sweyer.";
    public static final String LogTag = PACKAGE_NAME;

    public static final class player {
        public static final long POSITION_UPDATE_PERIOD_MS = 1000;

    }

    public static final class channels {

        //****************PLAYER***************************************************************************************
        public static final class player {
            public static final String CHANNEL_NAME = PACKAGE_NAME + "PLAYER_CHANNEL";
        }


        //****************EVENTS***************************************************************************************
        public static final class events {
            public static final String CHANNEL_NAME = PACKAGE_NAME + "EVENT_CHANNEL";

            public static final String BECOME_NOISY = PACKAGE_NAME + "EVENT_BECAME_NOISY";

            // Notification
            public static final String NOTIFICATION_CHANNEL_ID = PACKAGE_NAME + "EVENT_NOTIFICATION_CHANNEL";
            public static final String NOTIFICATION_INTENT_PLAY = PACKAGE_NAME + "EVENT_NOTIFICATION_PLAY";
            public static final String NOTIFICATION_INTENT_PAUSE = PACKAGE_NAME + "EVENT_NOTIFICATION_PAUSE";
            public static final String NOTIFICATION_INTENT_NEXT = PACKAGE_NAME + "EVENT_NOTIFICATION_NEXT";
            public static final String NOTIFICATION_INTENT_PREV = PACKAGE_NAME + "EVENT_NOTIFICATION_PREV";


            // Audio focus
            public static final String AUDIOFOCUS_GAIN = PACKAGE_NAME + "EVENT_AUDIOFOCUS_GAIN";
            public static final String AUDIOFOCUS_LOSS = PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS";
            public static final String AUDIOFOCUS_LOSS_TRANSIENT = PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
            public static final String AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

            // Media button events
            // see
            // https://developer.android.com/reference/android/view/KeyEvent.html#KEYCODE_MEDIA_AUDIO_TRACK
            // for key codes docs
            public static final String MEDIABUTTON_AUDIO_TRACK = PACKAGE_NAME + "EVENT_MEDIABUTTON_AUDIO_TRACK";
            public static final String MEDIABUTTON_FAST_FORWARD = PACKAGE_NAME + "EVENT_MEDIABUTTON_FAST_FORWARD";
            public static final String MEDIABUTTON_REWIND = PACKAGE_NAME + "EVENT_MEDIABUTTON_REWIND";
            public static final String MEDIABUTTON_NEXT = PACKAGE_NAME + "EVENT_MEDIABUTTON_NEXT";
            public static final String MEDIABUTTON_PREVIOUS = PACKAGE_NAME + "EVENT_MEDIABUTTON_PREVIOUS";
            public static final String MEDIABUTTON_PLAY_PAUSE = PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY_PAUSE";
            public static final String MEDIABUTTON_PLAY = PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY";
            public static final String MEDIABUTTON_STOP = PACKAGE_NAME + "EVENT_MEDIABUTTON_STOP";
            public static final String MEDIABUTTON_HOOK = PACKAGE_NAME + "EVENT_MEDIABUTTON_HOOK";
        }


        //****************GENERAL***************************************************************************************
        public static final class general {
            public static final String CHANNEL_NAME = PACKAGE_NAME + "GENERAL_CHANNEL";

            public static final String METHOD_INTENT_ACTION_VIEW = PACKAGE_NAME + "GENERAL_METHOD_INTENT_ACTION_VIEW";
        }

        //****************SERVICE***************************************************************************************
        public static final class service {
            public static final String CHANNEL_NAME = PACKAGE_NAME + "SERVICE_CHANNEL";

            public static final String METHOD_STOP_SERVICE = PACKAGE_NAME + "SERVICE_METHOD_STOP_SERVICE";
            public static final String METHOD_SEND_SONG = PACKAGE_NAME + "SERVICE_METHOD_SEND_SONG";

        }

        //****************SONGS***************************************************************************************
        public static final class songs {
            public static final String CHANNEL_NAME = PACKAGE_NAME + "SONGS_CHANNEL";

            public static final String METHOD_RETRIEVE_SONGS = PACKAGE_NAME + "SONGS_METHOD_RETRIEVE_SONGS";
            public static final String METHOD_SEND_SONGS = PACKAGE_NAME + "SONGS_METHOD_SEND_SONGS";
        }
    }
}