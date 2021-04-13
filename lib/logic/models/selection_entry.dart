/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:sweyer/sweyer.dart';

/// Used for selection of [Content].
class SelectionEntry<T extends Content> extends Equatable {
  const SelectionEntry({
    @required this.index,
    @required this.data,
    this.comapareWithIndex = true,
  });

  /// Used for comparison and for sorting when content is being
  /// inserted into queue.
  final int index;

  /// The content data.
  final T data;

  /// By default entries are compared with respect to their [index], if
  /// this is set to `false`, only [data] will be used.
  /// 
  /// We can't just throw away the [index] because it used for sorting
  /// when content is being inserted to queue.
  final bool comapareWithIndex;

  @override
  List<Object> get props => [data, index];
}
