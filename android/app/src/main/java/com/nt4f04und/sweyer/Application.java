package com.nt4f04und.sweyer;

import android.content.res.Configuration;

import androidx.annotation.NonNull;

import com.nt4f04und.sweyer.handlers.NotificationHandler;
import com.nt4f04und.sweyer.handlers.PlayerHandler;

public class Application extends android.app.Application {
   @Override
   public void onConfigurationChanged(@NonNull Configuration newConfig) {
      super.onConfigurationChanged(newConfig);
      NotificationHandler.updateNotification(PlayerHandler.isPlaying(), PlayerHandler.isLooping());
   }
}
