/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer;

public class Constants {
    public static final String PACKAGE_NAME = "com.nt4f04und.sweyer";
    public static final String DOTTED_PACKAGE_NAME = "com.nt4f04und.sweyer.";
    public static final String LogTag = PACKAGE_NAME;

    public static final class player {
        public static final long POSITION_UPDATE_PERIOD_MS = 1000;

    }

    public static final class channels {

        //****************PLAYER***************************************************************************************
        public static final class player {
            public static final String CHANNEL_NAME = DOTTED_PACKAGE_NAME + "PLAYER_CHANNEL";
        }


        //****************EVENTS***************************************************************************************
        public static final class events {
            public static final String CHANNEL_NAME = DOTTED_PACKAGE_NAME + "EVENT_CHANNEL";

            public static final String BECOME_NOISY = DOTTED_PACKAGE_NAME + "EVENT_BECAME_NOISY";

            // Notification
            public static final String NOTIFICATION_CHANNEL_ID = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_CHANNEL";
            public static final String NOTIFICATION_INTENT_PLAY = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_PLAY";
            public static final String NOTIFICATION_INTENT_PAUSE = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_PAUSE";
            public static final String NOTIFICATION_INTENT_NEXT = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_NEXT";
            public static final String NOTIFICATION_INTENT_PREV = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_PREV";
            public static final String NOTIFICATION_INTENT_KILL_SERVICE = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_KILL_SERVICE";
            public static final String NOTIFICATION_INTENT_LOOP = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_LOOP";
            public static final String NOTIFICATION_INTENT_LOOP_ON = DOTTED_PACKAGE_NAME + "EVENT_NOTIFICATION_LOOP_ON";


            // Audio focus
            public static final String AUDIOFOCUS_GAIN = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_GAIN";
            public static final String AUDIOFOCUS_LOSS = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS";
            public static final String AUDIOFOCUS_LOSS_TRANSIENT = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT";
            public static final String AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = DOTTED_PACKAGE_NAME + "EVENT_AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK";

            // Media button events
            // see
            // https://developer.android.com/reference/android/view/KeyEvent.html#KEYCODE_MEDIA_AUDIO_TRACK
            // for key codes docs
            public static final String MEDIABUTTON_AUDIO_TRACK  = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_AUDIO_TRACK";
            public static final String MEDIABUTTON_FAST_FORWARD = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_FAST_FORWARD";
            public static final String MEDIABUTTON_REWIND       = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_REWIND";
            public static final String MEDIABUTTON_NEXT         = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_NEXT";
            public static final String MEDIABUTTON_PREVIOUS     = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PREVIOUS";
            public static final String MEDIABUTTON_PLAY         = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY";
            public static final String MEDIABUTTON_PAUSE        = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PAUSE";
            public static final String MEDIABUTTON_PLAY_PAUSE   = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_PLAY_PAUSE";
            public static final String MEDIABUTTON_STOP         = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_STOP";
            // Bare hook event
            public static final String MEDIABUTTON_HOOK = DOTTED_PACKAGE_NAME + "EVENT_MEDIABUTTON_HOOK";

            // Composed hook events
            /** When pressed hook once */
            public static final String HOOK_PLAY_PAUSE = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_PAUSE";
            /** When pressed hook twice */
            public static final String HOOK_PLAY_NEXT = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_NEXT";
            /** When pressed hook thrice */
            public static final String HOOK_PLAY_PREV = DOTTED_PACKAGE_NAME + "EVENT_HOOK_PLAY_PREV";

            // Generalized events - these are e.g. next, prev.
            // They are needed because I can call them from different places, i.e. notification or media session events
            // Though events for notification and media session still exist to have access to them directly in dart side
            public static final String GENERALIZED_PLAY_NEXT = DOTTED_PACKAGE_NAME + "EVENT_GENERALIZED_PLAY_NEXT";
            public static final String GENERALIZED_PLAY_PREV = DOTTED_PACKAGE_NAME + "EVENT_GENERALIZED_PLAY_PREV";
        }


        //****************GENERAL***************************************************************************************
        public static final class general {
            public static final String CHANNEL_NAME = DOTTED_PACKAGE_NAME + "GENERAL_CHANNEL";

            public static final String METHOD_INTENT_ACTION_VIEW = DOTTED_PACKAGE_NAME + "GENERAL_METHOD_INTENT_ACTION_VIEW";
        }

        //****************SERVICE***************************************************************************************
        public static final class service {
            public static final String CHANNEL_NAME = DOTTED_PACKAGE_NAME + "SERVICE_CHANNEL";

            public static final String METHOD_STOP_SERVICE = DOTTED_PACKAGE_NAME + "SERVICE_METHOD_STOP_SERVICE";
            public static final String METHOD_SEND_CURRENT_SONG = DOTTED_PACKAGE_NAME + "SERVICE_METHOD_SEND_CURRENT_SONG";

        }

        //****************SONGS***************************************************************************************
        public static final class content {
            public static final String CHANNEL_NAME = DOTTED_PACKAGE_NAME + "CONTENT_CHANNEL";

            public static final String METHOD_RETRIEVE_SONGS = DOTTED_PACKAGE_NAME + "CONTENT_METHOD_RETRIEVE_SONGS";
            public static final String METHOD_RETRIEVE_ALBUMS = DOTTED_PACKAGE_NAME + "CONTENT_METHOD_RETRIEVE_ALBUMS";
            public static final String METHOD_SEND_SONGS = DOTTED_PACKAGE_NAME + "CONTENT_METHOD_SEND_SONGS";
            public static final String METHOD_DELETE_SONGS = DOTTED_PACKAGE_NAME + "CONTENT_METHOD_DELETE_SONGS";
    }
    }
}