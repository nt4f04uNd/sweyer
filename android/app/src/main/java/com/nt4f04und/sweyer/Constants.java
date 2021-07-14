/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer;

public class Constants {
   public static final String LogTag = "com.nt4f04und.sweyer";

   public enum intents {
      FAVORITE_REQUEST(0),
      PERMANENT_DELETION_REQUEST(1);

      public final int value;
      intents(int value) {
         this.value = value;
      }
   }
}