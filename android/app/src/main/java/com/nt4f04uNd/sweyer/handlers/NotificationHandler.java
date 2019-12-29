/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.handlers;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.util.Log;

import com.nt4f04uNd.sweyer.Constants;
import com.nt4f04uNd.sweyer.MainActivity;
import com.nt4f04uNd.sweyer.R;
import com.nt4f04uNd.sweyer.player.PlayerForegroundService;
import com.nt4f04uNd.sweyer.player.Song;

import org.jetbrains.annotations.NotNull;

import java.io.ByteArrayOutputStream;
import java.io.File;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

/**
 * Handler for notifications
 */
public class NotificationHandler {

    public static final int NOTIFICATION_ID = 100;

    public static void init() {
        if (NotificationHandler.pendingNotificationIntent == null) {

            // Create notifications channel
            createNotificationChannel();

            // Init intent filters
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_PLAY);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_PAUSE);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_PREV);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_NEXT);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_LOOP);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_LOOP_ON);
            intentFilter.addAction(Constants.channels.events.NOTIFICATION_INTENT_KILL_SERVICE);

            // Intent for switching to activity instead of opening a new one
            final Intent notificationIntent = new Intent(GeneralHandler.getAppContext(), MainActivity.class);
            notificationIntent.setAction(Intent.ACTION_MAIN);
            notificationIntent.addCategory(Intent.CATEGORY_LAUNCHER);
            notificationIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            pendingNotificationIntent = PendingIntent.getActivity(GeneralHandler.getAppContext(), 0, notificationIntent, 0);

            // Init intents
            Intent playIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_PLAY);
            Intent pauseIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_PAUSE);
            Intent prevIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_PREV);
            Intent nextIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_NEXT);
            Intent loopIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_LOOP);
            Intent loopOnIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_LOOP_ON);
            Intent killServiceIntent = new Intent().setAction(Constants.channels.events.NOTIFICATION_INTENT_KILL_SERVICE);


            // Make them pending
            playPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 1, playIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            pausePendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 2, pauseIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            prevPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 3, prevIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            nextPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 4, nextIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            loopPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 5, loopIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            loopOnPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 6, loopOnIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            killServicePendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 7, killServiceIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        }
    }

    /**
     * A notification intent filter
     */
    public static IntentFilter intentFilter = new IntentFilter();
    private static PendingIntent playPendingIntent;
    private static PendingIntent pausePendingIntent;
    private static PendingIntent prevPendingIntent;
    private static PendingIntent nextPendingIntent;
    private static PendingIntent loopPendingIntent;
    private static PendingIntent loopOnPendingIntent;
    private static PendingIntent killServicePendingIntent;
    /**
     * Intent that will fire when the user taps the notification
     * Will open application
     */
    private static PendingIntent pendingNotificationIntent;

    public static void createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "Управление музыкой";
            String description = "Канал уведомлений для управления фоновым воспроизведением музыки";
            int importance = NotificationManager.IMPORTANCE_LOW;

            NotificationChannel channel = new NotificationChannel(Constants.channels.events.NOTIFICATION_CHANNEL_ID, name, importance);
            channel.setDescription(description);

            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = GeneralHandler.getAppContext().getSystemService(NotificationManager.class);
            if (notificationManager != null)
                notificationManager.createNotificationChannel(channel);
            else Log.e(Constants.LogTag, "Notification manager is not created");

        }
    }


    /**
     * Creates media notification with buttons
     * Displays current song
     * When notification is clicked, the app will be opened
     */
    public static Notification getNotification(boolean isPlaying, boolean loopMode) {

        Song song = PlaylistHandler.getCurrentSong();

        byte[] artBytes = PlaylistHandler.getArt();
        if (artBytes == null) artBytes = PlaylistHandler.getArtPlaceholder();

        String artist = song.artist;

        // Artist check
        if (artist.equals("<unknown>"))
            artist = "Неизвестный исполнитель";

        int icon_loop;
        int icon_prev;
        int icon_play_pause;
        int icon_next;
        int icon_kill;

        if (GeneralHandler.isSystemThemeDark()) {
            icon_loop = loopMode ? R.drawable.round_loop_on_white_24 : R.drawable.round_loop_white_24;
            icon_prev = R.drawable.round_skip_previous_white_36;
            icon_play_pause = isPlaying ? R.drawable.round_pause_white_36 : R.drawable.round_play_arrow_white_36;
            icon_next = R.drawable.round_skip_next_white_36;
            icon_kill = R.drawable.round_close_white_24;
        } else {
            icon_loop = loopMode ? R.drawable.round_loop_on_black_24 : R.drawable.round_loop_black_24;
            icon_prev = R.drawable.round_skip_previous_black_36;
            icon_play_pause = isPlaying ? R.drawable.round_pause_black_36 : R.drawable.round_play_arrow_black_36;
            icon_next = R.drawable.round_skip_next_black_36;
            icon_kill = R.drawable.round_close_black_24;
        }

        NotificationCompat.Builder builder = new NotificationCompat.Builder(GeneralHandler.getAppContext(),
                Constants.channels.events.NOTIFICATION_CHANNEL_ID)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setSmallIcon(R.drawable.round_music_note_white_48)
                .setLargeIcon(BitmapFactory.decodeByteArray(artBytes, 0, artBytes.length))
                .setContentIntent(pendingNotificationIntent) // Set the intent that will fire when the user taps the notification
                .setContentTitle(song.title).setContentText(artist)
                .addAction(
                        icon_loop,
                        loopMode ? "Loop mode is on" : "Loop mode is off",
                        loopMode ? loopPendingIntent : loopOnPendingIntent
                )
                .addAction(icon_prev, "Previous", prevPendingIntent)
                .addAction(
                        icon_play_pause,
                        isPlaying ? "Pause" : "Play",
                        isPlaying ? pausePendingIntent : playPendingIntent
                )
                .addAction(icon_next, "Next", nextPendingIntent)
                .setStyle(
                        new androidx.media.app.NotificationCompat.MediaStyle()
                                .setShowActionsInCompactView(1, 2, 3)
                )
                .addAction(icon_kill, "Kill service", killServicePendingIntent);


        return builder.build();
    }

    /**
     * This is the method that can be called to update the Notification
     */
    public static void updateNotification(boolean isPlaying, boolean loopMode) {
        // Update notification only when service is running, 'cause otherwise fake notification will be created
        if (PlayerForegroundService.isRunning) {
            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(GeneralHandler.getAppContext());
            notificationManager.notify(NOTIFICATION_ID, getNotification(isPlaying, loopMode));
        }
    }
}
