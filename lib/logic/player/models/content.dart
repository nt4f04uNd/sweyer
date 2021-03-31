/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:equatable/equatable.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

/// Represents some content in the app (songs, album, etc).
/// 
/// See also:
/// * [ContentType], a list of all content types.
abstract class Content { }

/// Main content types in the application.
///
/// Each of them have an approprate [Sort]s implemented.
class ContentType extends Enum<Type> with EquatableMixin {
  const ContentType(Type value) : super(value);

  static List<ContentType> get values {
    return [song, album];
  }

  static const song = ContentType(Song);
  static const album = ContentType(Album);

  @override
  List<Object> get props => [value];
}

