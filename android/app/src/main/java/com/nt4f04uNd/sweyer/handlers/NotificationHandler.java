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
            intentFilter.addAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PLAY);
            intentFilter.addAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PAUSE);
            intentFilter.addAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PREV);
            intentFilter.addAction(Constants.channels.EVENT_NOTIFICATION_INTENT_NEXT);

            // Intent for switching to activity instead of opening a new one
            final Intent notificationIntent = new Intent(GeneralHandler.getAppContext(), MainActivity.class);
            notificationIntent.setAction(Intent.ACTION_MAIN);
            notificationIntent.addCategory(Intent.CATEGORY_LAUNCHER);
            notificationIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            pendingNotificationIntent = PendingIntent.getActivity(GeneralHandler.getAppContext(), 0, notificationIntent, 0);

            // Init intents
            Intent playIntent = new Intent().setAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PLAY);
            Intent pauseIntent = new Intent().setAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PAUSE);
            Intent prevIntent = new Intent().setAction(Constants.channels.EVENT_NOTIFICATION_INTENT_PREV);
            Intent nextIntent = new Intent().setAction(Constants.channels.EVENT_NOTIFICATION_INTENT_NEXT);

            // Make them pending
            playPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 1, playIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT);
            pausePendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 2, pauseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT);
            prevPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 3, prevIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT);
            nextPendingIntent = PendingIntent.getBroadcast(GeneralHandler.getAppContext(), 4, nextIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT);


            Bitmap bitmap = BitmapFactory.decodeResource(GeneralHandler.getAppContext().getResources(), R.drawable.placeholder_thumb);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            defaultArtBitmapBytes = stream.toByteArray();
        }
    }

    /**
     * A notification intent filter
     */
    public static IntentFilter intentFilter = new IntentFilter();
    private static byte[] defaultArtBitmapBytes;
    private static PendingIntent playPendingIntent;
    private static PendingIntent pausePendingIntent;
    private static PendingIntent prevPendingIntent;
    private static PendingIntent nextPendingIntent;
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

            NotificationChannel channel = new NotificationChannel(Constants.channels.EVENT_NOTIFICATION_CHANNEL_ID, name, importance);
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
     * When notification is clicked, the app will be opened
     */
    public static Notification getNotification(@NotNull Song song, boolean isPlaying) {

        byte[] artBytes = null;
        String artist = song.artist;

        // Album uri check
        if (song.albumArtUri != null) {
            File imgFile = new File(song.albumArtUri);
            if (imgFile.exists()) {
                Bitmap bitmap = BitmapFactory.decodeFile(imgFile.getAbsolutePath());
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                artBytes = stream.toByteArray();
            }
        }
        if (artBytes == null) {
            artBytes = defaultArtBitmapBytes;
        }

        // Artist check
        if(artist == "<unknown>")
            artist = "Неизвестный исполнитель";

        NotificationCompat.Builder builder = new NotificationCompat.Builder(GeneralHandler.getAppContext(),
                Constants.channels.EVENT_NOTIFICATION_CHANNEL_ID)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setStyle(new androidx.media.app.NotificationCompat.MediaStyle())
                .setSmallIcon(R.drawable.round_music_note_white_48)
                .setLargeIcon(BitmapFactory.decodeByteArray(artBytes, 0, artBytes.length))
                .setOngoing(true) // Persistent setting
                .setContentIntent(pendingNotificationIntent) // Set the intent that will fire when the user taps the notification
                .setContentTitle(song.title).setContentText(artist)
                .addAction(R.drawable.round_skip_previous_black_36, "Previous", prevPendingIntent)
                .addAction(
                        isPlaying ? R.drawable.round_pause_black_36 : R.drawable.round_play_arrow_black_36,
                        isPlaying ? "Pause" : "Play", isPlaying ? pausePendingIntent : playPendingIntent
                )
                .addAction(R.drawable.round_skip_next_black_36, "Next", nextPendingIntent);


        return builder.build();
    }

    /**
     * This is the method that can be called to update the Notification
     */
    public static void updateNotification(@NotNull Song song, boolean isPlaying) {
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(GeneralHandler.getAppContext());
        notificationManager.notify(NOTIFICATION_ID, getNotification(song, isPlaying));
    }
}
