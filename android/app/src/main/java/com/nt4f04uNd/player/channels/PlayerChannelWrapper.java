package com.nt4f04uNd.player.channels;

import android.content.Context;
import android.os.Handler;

import com.nt4f04uNd.player.Constants;
import com.nt4f04uNd.player.player.Player;
import com.nt4f04uNd.player.player.ReleaseMode;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class PlayerChannelWrapper implements MethodChannel.MethodCallHandler {

    public PlayerChannelWrapper(final MethodChannel channel, Context appContext) {
        this.channel = channel;
        this.channel.setMethodCallHandler(this);
        this.appContext = appContext;
    }

    private final MethodChannel channel;
    private final Map<String, Player> mediaPlayers = new HashMap<>();
    private final Handler handler = new Handler();
    private Runnable positionUpdates;
    private Context appContext;

    @Override
    public void onMethodCall(final MethodCall call, final MethodChannel.Result response) {
        try {
            handleMethodCall(call, response);
        } catch (Exception e) {
            Log.e(Constants.LogTag, "Unexpected error!", e);
            response.error("Unexpected error!", e.getMessage(), e);
        }
    }

    private void handleMethodCall(final MethodCall call, final MethodChannel.Result response) {
        final String playerId = call.argument("playerId");
        final String mode = call.argument("mode");
        final Player player = getPlayer(playerId, mode);

        switch (call.method) {
            case "play": {
                final String url = call.argument("url");
                final double volume = call.argument("volume");
                final Integer position = call.argument("position");
                final boolean respectSilence = call.argument("respectSilence");
                final boolean isLocal = call.argument("isLocal");
                final boolean stayAwake = call.argument("stayAwake");
                player.configAttributes(respectSilence, stayAwake, appContext);
                player.setVolume(volume);
                player.setUrl(url, isLocal);
                if (position != null && !mode.equals("PlayerMode.LOW_LATENCY")) {
                    player.seek(position);
                }
                player.play();
                break;
            }
            case "resume": {
                player.play();
                break;
            }
            case "pause": {
                player.pause();
                break;
            }
            case "stop": {
                player.stop();
                break;
            }
            case "release": {
                player.release();
                break;
            }
            case "seek": {
                final Integer position = call.argument("position");
                player.seek(position);
                break;
            }
            case "setVolume": {
                final double volume = call.argument("volume");
                player.setVolume(volume);
                break;
            }
            case "setUrl": {
                final String url = call.argument("url");
                final boolean isLocal = call.argument("isLocal");
                player.setUrl(url, isLocal);
                break;
            }
            case "getDuration": {

                response.success(player.getDuration());
                return;
            }
            case "getCurrentPosition": {
                response.success(player.getCurrentPosition());
                return;
            }
            case "setReleaseMode": {
                final String releaseModeName = call.argument("releaseMode");
                final ReleaseMode releaseMode = ReleaseMode.valueOf(releaseModeName.substring("ReleaseMode.".length()));
                player.setReleaseMode(releaseMode);
                break;
            }
            default: {
                response.notImplemented();
                return;
            }
        }
        response.success(1);
    }


    private Player getPlayer(String playerId, String mode) {
        if (!mediaPlayers.containsKey(playerId)) {
            Player player = new Player(this, playerId);
//                  Player player = mode.equalsIgnoreCase("PlayerMode.MEDIA_PLAYER") ?
//                            new WrappedMediaPlayer(this, playerId) :
//                            new WrappedSoundPool(this, playerId);
            mediaPlayers.put(playerId, player);
        }
        return mediaPlayers.get(playerId);
    }

    public void handleIsPlaying(Player player) {
        startPositionUpdates();
    }

    public void handleDuration(Player player) {
        channel.invokeMethod("audio.onDuration", buildArguments(player.getPlayerId(), player.getDuration()));
    }

    public void handleCompletion(Player player) {
        channel.invokeMethod("audio.onComplete", buildArguments(player.getPlayerId(), true));
    }

    private void startPositionUpdates() {
        if (positionUpdates != null) {
            return;
        }
        positionUpdates = new UpdateCallback(mediaPlayers, channel, handler, this);
        handler.post(positionUpdates);
    }

    private void stopPositionUpdates() {
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
        private final WeakReference<PlayerChannelWrapper> playerChannel;

        private UpdateCallback(final Map<String, Player> mediaPlayers,
                               final MethodChannel channel,
                               final Handler handler,
                               final PlayerChannelWrapper playerChannel) {
            this.mediaPlayers = new WeakReference<>(mediaPlayers);
            this.channel = new WeakReference<>(channel);
            this.handler = new WeakReference<>(handler);
            this.playerChannel = new WeakReference<>(playerChannel);
        }

        @Override
        public void run() {
            final Map<String, Player> mediaPlayers = this.mediaPlayers.get();
            final MethodChannel channel = this.channel.get();
            final Handler handler = this.handler.get();
            final PlayerChannelWrapper audioplayersPlugin = this.playerChannel.get();

            if (mediaPlayers == null || channel == null || handler == null || audioplayersPlugin == null) {
                if (audioplayersPlugin != null) {
                    audioplayersPlugin.stopPositionUpdates();
                }
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

                }
            }

            if (nonePlaying) {
                audioplayersPlugin.stopPositionUpdates();
            } else {
                handler.postDelayed(this, 200);
            }
        }
    }
}
