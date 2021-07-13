/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class ArtistContentRoute<T extends Content> extends StatefulWidget {
  const ArtistContentRoute({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  final ArtistContentArguments<T> arguments;

  @override
  State<ArtistContentRoute<T>> createState() => _ArtistContentRouteState();
}

class _ArtistContentRouteState<T extends Content> extends State<ArtistContentRoute<T>> {
  late StreamSubscription<void> _contentChangeSubscription;
  late List<T> list;
  
  @override
  void initState() { 
    super.initState();
    list = widget.arguments.list;
    _contentChangeSubscription = ContentControl.state.onContentChange.listen((event) {
      setState(() {
        // Update contents
        list = contentPick<T, ValueGetter<List<T>>>(
          song: () => widget.arguments.artist.songs as List<T>,
          album: () => widget.arguments.artist.albums as List<T>,
          playlist: () => throw UnimplementedError(),
          artist: () => throw UnimplementedError(),
        )();
      });
    });
  }

  @override
  void dispose() { 
    _contentChangeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final artist = widget.arguments.artist;
    final selectionRoute = selectionRouteOf(context);
    return ContentSelectionControllerCreator<T>(
      builder: (context, selectionController, child) => Scaffold(
        appBar: AppBar(
          title: AnimationSwitcher(
            animation: CurvedAnimation(
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
              parent: selectionController.animation,
            ),
            child1: Text(ContentUtils.localizedArtist(artist.artist, l10n)),
            child2: SelectionCounter(controller: selectionController),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: AnimationSwitcher(
                animation: CurvedAnimation(
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                  parent: selectionController.animation,
                ),
                builder2: SelectionAppBar.defaultSelectionActionsBuilder,
                child1: const SizedBox.shrink(),
                child2: Row(children: [
                  SelectAllSelectionAction<T>(
                    controller: selectionController,
                    entryFactory: (content, index) => SelectionEntry<T>.fromContent(
                      content: content,
                      index: index,
                      context: context,
                    ),
                    getAll: () => list,
                  ),
                ]),
              ),
            ),
          ],
          leading: const NFBackButton(),
        ),
        body: StreamBuilder(
          stream: ContentControl.state.onSongChange,
          builder: (context, snapshot) => ContentListView<T>(
            list: list,
            selectionController: selectionController,
            leading: selectionRoute
              ? ContentListHeader<T>.onlyCount(count: list.length)
              : ContentListHeader<T>(
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
