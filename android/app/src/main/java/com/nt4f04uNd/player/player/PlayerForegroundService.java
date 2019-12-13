package com.nt4f04uNd.player.player;

import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Binder;
import android.os.IBinder;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.handlers.AudioFocusHandler;
import com.nt4f04uNd.player.handlers.MediaButtonHandler;
import com.nt4f04uNd.player.handlers.NotificationHandler;

import androidx.annotation.Nullable;
import io.flutter.Log;

public class PlayerForegroundService extends Service {

    @Override
    public void onCreate() {
        super.onCreate();
        //AudioFocusHandler.init(); // TODO: this
        MediaButtonHandler.init(getApplicationContext());
        NotificationHandler.init(getApplicationContext());

        startForeground(100, NotificationHandler.getForegroundNotification("Test", "Test", new byte[0], false));
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public class LocalBinder extends Binder {
        public PlayerForegroundService getService() {
            // Return this instance of LocalService so clients can call public methods
            return PlayerForegroundService.this;
        }
    }
}
