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
      public static final long POSITION_UPDATE_PERIOD_MS = 200;

      public static final String NOTIFICATION_CHANNEL_ID = DOTTED_PACKAGE_NAME + "NOTIFICATION_CHANNEL";
      public static final String NOTIFICATION_INTENT_PLAY = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_PLAY";
      public static final String NOTIFICATION_INTENT_PAUSE = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_PAUSE";
      public static final String NOTIFICATION_INTENT_NEXT = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_NEXT";
      public static final String NOTIFICATION_INTENT_PREV = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_PREV";
      public static final String NOTIFICATION_INTENT_KILL_SERVICE = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_KILL_SERVICE";
      public static final String NOTIFICATION_INTENT_LOOP = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_LOOP";
      public static final String NOTIFICATION_INTENT_LOOP_ON = DOTTED_PACKAGE_NAME + "NOTIFICATION_INTENT_LOOP_ON";
   }

   public static final class intents {
      public static final int PERMANENT_DELETION_REQUEST = 0;
   }

   public static final class eventsChannel {
      // Generalized events - these are e.g. next, prev.
      // They are needed because I can call them from different places, i.e. notification or media session events
      // Though events for notification and media session still exist to have access to them directly in dart side
      public static final String GENERALIZED_PLAY_NEXT = "generalizedPlayNext";
      public static final String GENERALIZED_PLAY_PREV = "generalizedPlayPrev";
   }
}