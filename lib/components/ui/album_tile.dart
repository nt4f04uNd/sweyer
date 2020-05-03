/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class AlbumTile extends StatelessWidget {
  const AlbumTile({
    Key key,
    @required this.album,
  })  : assert(album != null),
        super(key: key);

  final Album album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigator.of(context).pushNamed(Constants.Routes.album.value);
      },
      splashFactory: ListTileInkRipple.splashFactory,
      child: Container(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
        child: Row(
          // mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AlbumArtLarge(
                path: album.albumArt,
                size: 70.0,
                placeholderLogoFactor: 0.62,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      album.album,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Artist(
                      artist: album.artist,
                      textStyle: const TextStyle(fontSize: 14, height: 1.0),
                    )
                  ],
                ),
              ),
            ),
            // if (action != null)
            //   Padding(
            //     padding: const EdgeInsets.only(left: 8.0),
            //     child: action,
            //   )
          ],
        ),
      ),
    );
  }
}
