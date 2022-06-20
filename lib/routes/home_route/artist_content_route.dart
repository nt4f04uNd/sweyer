import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class ArtistContentRoute<T extends Content> extends StatefulWidget {
  const ArtistContentRoute({
    Key? key,
    required this.contentType,
    required this.arguments,
  }) : super(key: key);

  final ContentType contentType;
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
    _contentChangeSubscription = ContentControl.instance.onContentChange.listen((event) {
      setState(() {
        // Update contents
        switch (widget.contentType) {
          case ContentType.song:
            list = widget.arguments.artist.songs as List<T>;
            break;
          case ContentType.album:
            list = widget.arguments.artist.albums as List<T>;
            break;
          case ContentType.playlist:
          case ContentType.artist:
            throw UnimplementedError();
        }
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
      contentType: widget.contentType,
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
          stream: PlaybackControl.instance.onSongChange,
          builder: (context, snapshot) => ContentListView(
            contentType: widget.contentType,
            list: list,
            selectionController: selectionController,
            leading: selectionRoute
                ? ContentListHeader<T>.onlyCount(contentType: widget.contentType, count: list.length)
                : ContentListHeader<T>(
                    contentType: widget.contentType,
                    count: list.length,
                    selectionController: selectionController,
                    trailing: Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: Row(
                        children: [
                          ContentListHeaderAction(
                            icon: const Icon(Icons.shuffle_rounded),
                            onPressed: () {
                              switch (widget.contentType) {
                                case ContentType.song:
                                  QueueControl.instance.setOriginQueue(
                                    origin: artist,
                                    shuffled: true,
                                    songs: list as List<Song>,
                                  );
                                  break;
                                case ContentType.album:
                                  final shuffleResult = ContentUtils.shuffleSongOrigins(list as List<Album>);
                                  QueueControl.instance.setOriginQueue(
                                    origin: artist,
                                    shuffled: true,
                                    songs: shuffleResult.songs,
                                    shuffledSongs: shuffleResult.shuffledSongs,
                                  );
                                  break;
                                case ContentType.playlist:
                                case ContentType.artist:
                                  throw UnimplementedError();
                              }
                              MusicPlayer.instance.setSong(QueueControl.instance.state.current.songs[0]);
                              MusicPlayer.instance.play();
                              playerRouteController.open();
                            },
                          ),
                          ContentListHeaderAction(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () {
                              switch (widget.contentType) {
                                case ContentType.song:
                                  QueueControl.instance.setOriginQueue(
                                    origin: artist,
                                    songs: list as List<Song>,
                                  );
                                  break;
                                case ContentType.album:
                                  QueueControl.instance.setOriginQueue(
                                    origin: artist,
                                    songs: ContentUtils.joinSongOrigins(list as List<Album>),
                                  );
                                  break;
                                case ContentType.playlist:
                                case ContentType.artist:
                                  throw UnimplementedError();
                              }
                              MusicPlayer.instance.setSong(QueueControl.instance.state.current.songs[0]);
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
