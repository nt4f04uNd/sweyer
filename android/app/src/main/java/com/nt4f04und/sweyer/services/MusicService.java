/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04und.sweyer.services;

import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;

import com.nt4f04und.sweyer.handlers.AudioFocusHandler;
import com.nt4f04und.sweyer.handlers.GeneralHandler;
import com.nt4f04und.sweyer.handlers.MediaSessionHandler;
import com.nt4f04und.sweyer.handlers.NotificationHandler;
import com.nt4f04und.sweyer.handlers.PlayerHandler;
import com.nt4f04und.sweyer.handlers.QueueHandler;
import com.nt4f04und.sweyer.handlers.WakelockHandler;
import com.nt4f04und.sweyer.receivers.BecomingNoisyReceiver;
import com.nt4f04und.sweyer.receivers.NotificationReceiver;

import androidx.annotation.Nullable;

public class MusicService extends Service {

   public static final String SERVICE_INTENT_EXTRA = "MUSIC_SERVICE_EXTRA";
   public static final int SERVICE_INTENT_EXTRA_START_FOREGROUND = 0;
   public static final int SERVICE_INTENT_EXTRA_STOP_FOREGROUND = 1;
   // This needed for stopping service on notification dismissal
   // https://stackoverflow.com/a/35721582/9710294
   public static final int SERVICE_INTENT_EXTRA_KILL = 2;

   public static boolean isRunning = false;

   private NotificationReceiver notificationReceiver;
   private BecomingNoisyReceiver noisyAudioStreamReceiver;
   private final IntentFilter noisyIntentFilter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);

   @Override
   public void onCreate() {
      super.onCreate();

      isRunning = true;
      QueueHandler.initCurrentSong();

      // Initializing handlers
      GeneralHandler.init(getApplicationContext());
      PlayerHandler.init();
      AudioFocusHandler.init();
      NotificationHandler.init();
      MediaSessionHandler.init();

      // Registering receivers
      notificationReceiver = new NotificationReceiver();
      noisyAudioStreamReceiver = new BecomingNoisyReceiver();
      registerReceiver(notificationReceiver, NotificationHandler.intentFilter);
      registerReceiver(noisyAudioStreamReceiver, noisyIntentFilter);

      if (QueueHandler.getCurrentSong() != null)
         startForeground(
            NotificationHandler.NOTIFICATION_ID,
            NotificationHandler.getNotification(true, PlayerHandler.isLooping())
         );
      else stopSelf();
   }

   @Override
   public int onStartCommand(Intent intent, int flags, int startId) {
      int extra = intent.getIntExtra(SERVICE_INTENT_EXTRA, SERVICE_INTENT_EXTRA_START_FOREGROUND);
      if (extra == SERVICE_INTENT_EXTRA_START_FOREGROUND) {
         startForeground(
                 NotificationHandler.NOTIFICATION_ID,
                 NotificationHandler.getNotification(true, PlayerHandler.isLooping())
         );
      } else if (extra == SERVICE_INTENT_EXTRA_STOP_FOREGROUND) {
         stopForeground(false);
         NotificationHandler.updateNotification(false, PlayerHandler.isLooping());
      } else if (extra == SERVICE_INTENT_EXTRA_KILL) {
         stopSelf();
      }
      return Service.START_NOT_STICKY;
   }

   @Override
   public void onDestroy() {
      isRunning = false;

      // Handlers
      // These may affect user interaction with other apps if I won't destroy them
      // Other handlers seem to be not necessary to clear them
      PlayerHandler.stopAllHandlers();
      WakelockHandler.release();
      AudioFocusHandler.abandonFocus();
      QueueHandler.resetQueue();
      MediaSessionHandler.release();

      // Receivers
      unregisterReceiver(notificationReceiver);
      unregisterReceiver(noisyAudioStreamReceiver);
      super.onDestroy();
   }

   @Override
   public void onTrimMemory(int level) {
      QueueHandler.resetQueue();
   }

   @Nullable
   @Override
   public IBinder onBind(Intent intent) {
      return null;
   }

   public static void startService() {
      Intent intent = new Intent(GeneralHandler.getAppContext(), MusicService.class);
      intent.putExtra(SERVICE_INTENT_EXTRA, SERVICE_INTENT_EXTRA_START_FOREGROUND);
      // Handler is a workaround to run this code on UI thread, or whatever, idk exactly
      // But if just call `startService` from `ServiceChannel` handler - it will give strange error that startForeground hasn't called
      new Handler().post(() -> {
         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            GeneralHandler.getAppContext().startForegroundService(intent);
         } else {
            GeneralHandler.getAppContext().startService(intent);
         }
      });
   }

   public static void stopForeground() {
      Intent intent = new Intent(GeneralHandler.getAppContext(), MusicService.class);
      intent.putExtra(SERVICE_INTENT_EXTRA, SERVICE_INTENT_EXTRA_STOP_FOREGROUND);
      // Same situation as for handler inside the `startService`
      new Handler().post(() -> {
         GeneralHandler.getAppContext().startService(intent);
      });
   }


   public static void stopService() {
      Intent intent = new Intent(GeneralHandler.getAppContext(), MusicService.class);
      // Same situation as for handler inside the `startService`
      new Handler().post(() -> GeneralHandler.getAppContext().stopService(intent));
   }

}
