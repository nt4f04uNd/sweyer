/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class AlbumListTab extends StatefulWidget {
  AlbumListTab({Key key}) : super(key: key);

  @override
  _AlbumListTabState createState() => _AlbumListTabState();
}

class _AlbumListTabState extends State<AlbumListTab>
    with AutomaticKeepAliveClientMixin<AlbumListTab> {
  // This mixin doesn't allow widget to redraw
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<RefreshIndicatorState> _albumsRefreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
  }

  /// Performs albums refetch
  Future<void> _handleRefreshAlbums() async {
    await ContentControl.refetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final albums = ContentControl.state.albums;

    return CustomRefreshIndicator(
      color: Constants.AppTheme.refreshIndicatorArrow.auto(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      key: _albumsRefreshIndicatorKey,
      onRefresh: _handleRefreshAlbums,
      child: SingleTouchRecognizerWidget(
        child: SMMDefaultDraggableScrollbar(
          controller: _scrollController,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 34.0, top: 4.0),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              return AlbumTile(
                album: albums[index],
              );
            },
          ),
        ),
      ),
    );
  }
}

//  GridView.builder(
//           padding: const EdgeInsets.only(bottom: 34.0, top: 0),
//           itemCount: ContentControl.state.albums.length,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//           ),
//           itemBuilder: (BuildContext context, int index) {
//             return Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: GridTile(
//                 footer: Padding(
//                   padding:
//                       const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
//                   child: Container(
//                     padding: const EdgeInsets.only(
//                         bottom: 4.0, top: 4.0, right: 8.0),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: const BorderRadius.all(
//                         Radius.circular(10.0),
//                       ),
//                     ),
//                     child: Text(
//                       ContentControl.state.albums[index].album,
//                       textAlign: TextAlign.end,
//                     ),
//                   ),
//                 ),
//                 child: AlbumArtLargeTappable(
//                   onTap: () {},
//                   size: MediaQuery.of(context).size.width / 2,
//                   placeholderLogoFactor: 0.63,
//                   path: ContentControl.state.albums[index].albumArt,
//                 ),
//               ),
//             );
//           },
//         ),
