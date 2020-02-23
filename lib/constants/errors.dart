/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


abstract class Errors {
   /// Thrown when [play] gets called in wrong state
  static const String NATIVE_PLAYER_ILLEGAL_STATE = "Unsupported value: java.lang.IllegalStateException";

   /// Thrown when resource can't be played
  static const String UNABLE_ACCESS_RESOURCE = "Unsupported value: java.lang.RuntimeException: Unable to access resource";
}