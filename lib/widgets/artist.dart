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
    this.overflow = TextOverflow.ellipsis,
    this.textStyle,
  }) : super(key: key);

  final String artist;
  final TextOverflow overflow;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Text(
      ContentUtils.localizedArtist(artist, l10n),
      overflow: overflow,
      style: ThemeControl.theme.textTheme.subtitle2!.merge(textStyle),
    );
  }
}
