/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';

/// Component to show artist, or automatically show 'Unknown artist' instead of '<unknown>'
class ArtistWidget extends StatelessWidget {
  const ArtistWidget({
    Key? key,
    required this.artist,
    this.trailingText,
    this.overflow = TextOverflow.ellipsis,
    this.textStyle,
  }) : super(key: key);

  final String artist;
  /// If not null, this text will be shown after appended dot.
  final String? trailingText;
  final TextOverflow overflow;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final localizedArtist = ContentUtils.localizedArtist(artist, l10n);
    return Text(
      trailingText == null ? localizedArtist : ContentUtils.joinDot([
        localizedArtist,
        trailingText,
      ]),
      overflow: overflow,
      style: ThemeControl.theme.textTheme.subtitle2!.merge(textStyle),
    );
  }
}
