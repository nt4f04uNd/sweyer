/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player.handlers;

import android.app.Activity;
import android.content.Intent;

public abstract class GeneralHandler {

   /**
    * Check for if Intent action is VIEW
    */
   static public boolean isIntentActionView(Activity activity) {
      Intent intent = activity.getIntent();
      return Intent.ACTION_VIEW.equals(intent.getAction());
   }

}