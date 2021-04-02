package com.nt4f04und.sweyer.player;

public enum PlayerResourceState {
    /// State when player doesn't exist or released
    RELEASED,
    /// State when player called the `reset` method or right after player creating (`createPlayer` call)
    IDLE,
    /// State when player is preparing the song
    PREPARING,
    /// State when player is ready for playback
    PREPARED
}
