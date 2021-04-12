/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:equatable/equatable.dart';
import 'package:sweyer/sweyer.dart';

class SelectionEntry<T extends Content> extends Equatable {
  const SelectionEntry({this.index, this.data});

  final int index;
  final T data;

  @override
  List<Object> get props => [data, index];
}
