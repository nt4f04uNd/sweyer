/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

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
      onTap: () {},
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
                placeholderLogoFactor: 0.63,
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
                      style: TextStyle(
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      album.artist,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).textTheme.caption.color,
                      ),
                    ),
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
