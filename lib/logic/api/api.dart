/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// This module contains "pure" interaction handlers with native java code
/// "Not pure" channels mean that they are highly concatenated with some specific logic, e.g. player playback
/// 
/// Classes that use "pure" channels have name convention `...Handler` 
/// Whereas others can be called with any name
/// 
/// You should import this module `as API`

export 'general.dart';
export 'events.dart';
export 'service.dart';