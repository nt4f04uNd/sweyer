package com.nt4f04uNd.player.handlers;

import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.channels.SongChannel;
import com.nt4f04uNd.player.player.PlayerForegroundService;

import java.lang.ref.WeakReference;
import java.util.List;

import io.flutter.Log;


/**
 * Handler for all the interaction between service and dart code
 */
public abstract class ServiceHandler {

    private static Intent intentForService;

    public static void init() {
        if (intentForService == null)
            ServiceHandler.intentForService = new Intent(GeneralHandler.getAppContext(), PlayerForegroundService.class);
    }

    /**
     * Handler is a workaround to run this code on UI thread, or whatever, idk exactly
     * But if just call `startService` from `ServiceChannel` handler - it will give strange error that startForeground hasn't called
     */
    public static void startService() {
        new Handler().post(() -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                GeneralHandler.getAppContext().startForegroundService(intentForService);
            else
                GeneralHandler.getAppContext().startService(intentForService);
        });
    }

    /** Same as startService */
    public static void stopService() {
        new Handler().post(() -> GeneralHandler.getAppContext().stopService(intentForService));
    }

}
