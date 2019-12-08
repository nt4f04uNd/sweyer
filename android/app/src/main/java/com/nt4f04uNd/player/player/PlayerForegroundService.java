package com.nt4f04uNd.player.player;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

import com.nt4f04uNd.player.handlers.NotificationHandler;

import androidx.annotation.Nullable;

public class PlayerForegroundService extends Service {

    @Override
    public void onCreate() {
        super.onCreate();

        startForeground(100, NotificationHandler.getForegroundNotification(this.getApplicationContext(), "Test", "Test", new byte[0], false));
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
