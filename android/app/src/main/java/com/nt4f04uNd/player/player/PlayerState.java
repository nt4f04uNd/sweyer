package com.nt4f04uNd.player.player;

public enum PlayerState {
    PLAYING, PAUSED, STOPPED,
    COMPLETED // Completed is here just for sake of completeness and matching with dart code
    // In practice, calling method set state with completed argument won't set player to COMPLETED state
    // In future completed state may be removed at all
}
