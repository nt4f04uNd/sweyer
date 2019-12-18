/*---------------------------------------------------------------------------------------------
*  Copyright (c) The Fuchsia Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/foundation.dart';

import 'item_positions_listener.dart';

/// Internal implementation of [ItemPositionsListener].
class ItemPositionsNotifier implements ItemPositionsListener {
  @override
  final ValueNotifier<Iterable<ItemPosition>> itemPositions = ValueNotifier([]);
}