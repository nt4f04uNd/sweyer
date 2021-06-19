/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class ArtistContentRoute<T extends Content> extends StatelessWidget {
  const ArtistContentRoute({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  final ArtistContentArguments<T> arguments;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final artist = arguments.artist;
    final list = arguments.list;
    return Scaffold(
      appBar: AppBar(
        title: Text(ContentUtils.localizedArtist(artist.artist, l10n)),
        leading: const NFBackButton(),
      ),
      body: ContentSelectionControllerCreator<T>(
        builder: (context, selectionController, child) => StreamBuilder(
          stream: ContentControl.state.onSongChange,
          builder: (context, snapshot) => ContentListView<T>(
            list: list,
            selectionController: selectionController,
            leading: ContentListHeader<T>(
              count: list.length,
              selectionController: selectionController,
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: Row(
                  children: [
                    ContentListHeaderAction(
                      icon: const Icon(Icons.shuffle_rounded),
                      onPressed: () {
                        contentPick<T, VoidCallback>(
                          song: () {
                            ContentControl.setOriginQueue(
                              origin: artist,
                              shuffled: true,
                              songs: list as List<Song>,
                            );
                          },
                          album: () {
                            final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Album>);
                            ContentControl.setOriginQueue(
                              origin: artist,
                              shuffled: true,
                              songs: shuffleResult.songs,
                              shuffledSongs: shuffleResult.shuffledSongs,
                            );
                          },
                          playlist: () => throw UnimplementedError(),
                          artist: () => throw UnimplementedError(),
                        )();
                        MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                        MusicPlayer.instance.play();
                        playerRouteController.open();
                      },
                    ),
                    ContentListHeaderAction(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        contentPick<T, VoidCallback>(
                          song: () {
                            ContentControl.setOriginQueue(
                              origin: artist,
                              songs: list as List<Song>,
                            );
                          },
                          album: () {
                            ContentControl.setOriginQueue(
                              origin: artist,
                              songs: ContentUtils.joinSongOrigins(list as List<Album>),
                            );
                          },
                          playlist: () => throw UnimplementedError(),
                          artist: () => throw UnimplementedError(),
                        )();
                        MusicPlayer.instance.setSong(ContentControl.state.queues.current.songs[0]);
                        MusicPlayer.instance.play();
                        playerRouteController.open();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
