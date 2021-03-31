/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

/// Indicates that reached code path that is invalid.
/// 
/// In difference with [UnimplementedError], this exception used to mark that
/// given code path should never be reached.
class InvalidCodePathError extends Error { }