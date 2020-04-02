/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'async.dart';
export 'switcher.dart';

import 'package:flutter/scheduler.dart';

/// Function to slow down duration by [timeDilation]
Duration applyDilation(Duration duration) {
  return duration * timeDilation;
}
