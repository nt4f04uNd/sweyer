/*---------------------------------------------------------------------------------------------
 *  Copyright (c) nt4f04und. All rights reserved.
 *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
 *
 *  Copyright (c) Luan Nico.
 *  See ThirdPartyNotices.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

package com.nt4f04uNd.sweyer.player;

public enum PlayerState {
    PLAYING, PAUSED, STOPPED,
    COMPLETED // Completed is here just for sake of completeness and matching with dart code
    // In practice, calling method set state with completed argument won't set player to COMPLETED state
    // In future completed state may be removed at all
}
