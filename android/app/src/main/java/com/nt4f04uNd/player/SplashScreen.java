/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.player;

import android.content.Context;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.android.DrawableSplashScreen.DrawableSplashScreenView;

public class SplashScreen implements io.flutter.embedding.android.SplashScreen {
    @Override
    @Nullable
    public View createSplashView(
            @NonNull Context context,
            @Nullable Bundle savedInstanceState
    ) {

        Log.w(Constants.LogTag, "frwqfwqfqwfFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
        // Return a new MySplashView without saving a reference, because it
        // has no state that needs to be tracked or controlled.
        DrawableSplashScreenView view = new DrawableSplashScreenView(context);
        view.setSplashDrawable(context.getResources().getDrawable(R.drawable.screen_dark));
        return view;
    }

    @Override
    public void transitionToFlutter(@NonNull Runnable onTransitionComplete) {
        // Immediately invoke onTransitionComplete because this SplashScreen
        // doesn't display a transition animation.
        //
        // Every SplashScreen *MUST* invoke onTransitionComplete at some point
        // for the splash system to work correctly.
        onTransitionComplete.run();
    }
}