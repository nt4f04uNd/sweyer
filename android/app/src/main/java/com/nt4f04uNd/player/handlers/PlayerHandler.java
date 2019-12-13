package com.nt4f04uNd.player.handlers;

import android.os.Handler;

import com.nt4f04uNd.player.channels.PlayerChannel;
import com.nt4f04uNd.player.player.Player;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class PlayerHandler {

    private static final Map<String, Player> mediaPlayers = new HashMap<>();
    private static final Handler handler = new Handler();
    private static Runnable positionUpdates;

    public static Player getPlayer(String playerId, String mode) {
        if (!mediaPlayers.containsKey(playerId)) {
            Player player = new Player(playerId);
//                  Player player = mode.equalsIgnoreCase("PlayerMode.MEDIA_PLAYER") ?
//                            new WrappedMediaPlayer(this, playerId) :
//                            new WrappedSoundPool(this, playerId);
            mediaPlayers.put(playerId, player);
        }
        return mediaPlayers.get(playerId);
    }

    public static void handleIsPlaying(Player player) {
        startPositionUpdates();
    }

    public static void handleDuration(Player player) {
        PlayerChannel.channel.invokeMethod("audio.onDuration", buildArguments(player.getPlayerId(), player.getDuration()));
    }

    public static void handleCompletion(Player player) {
        PlayerChannel.channel.invokeMethod("audio.onComplete", buildArguments(player.getPlayerId(), true));
    }

    protected static void startPositionUpdates() {
        if (positionUpdates != null) {
            return;
        }
        positionUpdates = new UpdateCallback(mediaPlayers, PlayerChannel.channel, handler);
        handler.post(positionUpdates);
    }

    public static void stopPositionUpdates() {
        positionUpdates = null;
        handler.removeCallbacksAndMessages(null);
    }

    private static Map<String, Object> buildArguments(String playerId, Object value) {
        Map<String, Object> result = new HashMap<>();
        result.put("playerId", playerId);
        result.put("value", value);
        return result;
    }

    private static final class UpdateCallback implements Runnable {

        private final WeakReference<Map<String, Player>> mediaPlayers;
        private final WeakReference<MethodChannel> channel;
        private final WeakReference<Handler> handler;

        private UpdateCallback(final Map<String, Player> mediaPlayers,
                               final MethodChannel channel,
                               final Handler handler) {
            this.mediaPlayers = new WeakReference<>(mediaPlayers);
            this.channel = new WeakReference<>(channel);
            this.handler = new WeakReference<>(handler);
        }

        @Override
        public void run() {
            final Map<String, Player> mediaPlayers = this.mediaPlayers.get();
            final MethodChannel channel = this.channel.get();
            final Handler handler = this.handler.get();

            if (mediaPlayers == null || channel == null || handler == null) {
                stopPositionUpdates();
                return;
            }

            boolean nonePlaying = true;
            for (Player player : mediaPlayers.values()) {
                if (!player.isActuallyPlaying()) {
                    continue;
                }
                try {
                    nonePlaying = false;
                    final String key = player.getPlayerId();
                    final int duration = player.getDuration();
                    final int time = player.getCurrentPosition();
                    channel.invokeMethod("audio.onDuration", buildArguments(key, duration));
                    channel.invokeMethod("audio.onCurrentPosition", buildArguments(key, time));
                } catch (UnsupportedOperationException e) {
                    // TODO: wtf???
                }
            }

            if (nonePlaying) {
                stopPositionUpdates();
            } else {
                handler.postDelayed(this, 200);
            }
        }
    }
}
