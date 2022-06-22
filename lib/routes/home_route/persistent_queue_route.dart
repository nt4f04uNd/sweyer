import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sweyer/sweyer.dart';

class _ReorderOperation {
  final int oldIndex;
  final int newIndex;
  _ReorderOperation(this.oldIndex, this.newIndex);
}

class PersistentQueueRoute extends StatefulWidget {
  const PersistentQueueRoute({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  final PersistentQueueArguments arguments;

  @override
  _PersistentQueueRouteState createState() => _PersistentQueueRouteState();
}

class _PersistentQueueRouteState extends State<PersistentQueueRoute> with SelectionHandlerMixin {
  final ScrollController scrollController = ScrollController();
  late AnimationController appBarController;
  late PersistentQueue queue;
  late List<Song> queueSongs;
  late StreamSubscription<void> _contentChangeSubscription;

  static const _appBarHeight = NFConstants.toolbarHeight - 8.0;
  static const _artSize = 130.0;
  static const _infoSectionTopPadding = 10.0;
  static const _infoSectionBottomPadding = 24.0;
  static const _infoSectionHeight = _artSize + _infoSectionTopPadding + _infoSectionBottomPadding;

  static const _buttonSectionButtonHeight = 38.0;
  static const _buttonSectionBottomPadding = 12.0;
  static const _buttonSectionHeight = _buttonSectionButtonHeight + _buttonSectionBottomPadding;

  /// Amount of pixels user always can scroll.
  static const _alwaysCanScrollExtent = _infoSectionHeight + _buttonSectionHeight;

  bool get isAlbum => queue is Album;
  bool get isPlaylist => queue is Playlist;
  Album get album => queue as Album;
  Playlist get playlist => queue as Playlist;
  // List<Song> get songs => editing ? editingSongs : queueSongs;
  List<Song> get songs => queueSongs;

  @override
  void initState() {
    super.initState();

    _updateContent(true);
    if (widget.arguments.editing) {
      _startEditing(true);
    }

    appBarController = AnimationController(
      vsync: AppRouter.instance.navigatorKey.currentState!,
      value: 1.0,
    );
    scrollController.addListener(_handleScroll);

    initSelectionController(() => ContentSelectionController.create(
          vsync: AppRouter.instance.navigatorKey.currentState!,
          context: context,
          contentType: ContentType.song,
          closeButton: true,
          ignoreWhen: () => playerRouteController.opened,
        ));

    playerRouteController.addListener(_handlePlayerRouteController);
    _contentChangeSubscription = ContentControl.instance.onContentChange.listen(_handleContentChange);
  }

  @override
  void dispose() {
    playerRouteController.removeListener(_handlePlayerRouteController);
    _contentChangeSubscription.cancel();
    disposeSelectionController();
    appBarController.dispose();
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handlePlayerRouteController() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleScroll() {
    appBarController.value = 1.0 - scrollController.offset / _infoSectionHeight;
  }

  void _handleContentChange(void event) {
    setState(() {
      _updateContent();
    });
  }

  PersistentQueue? _findOriginalQueue() {
    final queue = widget.arguments.queue;
    if (queue is Album) {
      return ContentControl.instance.state.albums[queue.id];
    } else if (queue is Playlist) {
      return ContentControl.instance.state.playlists.firstWhereOrNull((el) => el == queue);
    }
    throw UnimplementedError();
  }

  /// Updates content.
  /// If such playlist no longer exist, will automatically call [_quitBecauseNotFound].
  void _updateContent([bool init = false]) {
    final queue = _findOriginalQueue();
    final queueSongs = queue?.songs;

    if (queue == null || queue is Album && queueSongs!.isEmpty) {
      if (init) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            _quitBecauseNotFound();
          }
        });
      } else {
        _quitBecauseNotFound();
      }
      return;
    }
    this.queue = queue;
    this.queueSongs = queueSongs!;
    if (!init && editing) {
      // If received an update, discard any edits and start editing anew
      _startEditing();
    }
  }

  void _quitBecauseNotFound() {
    ContentControl.instance.refetchAll();
    final l10n = getl10n(context);
    String message = '';
    if (isAlbum) {
      message = l10n.albumNotFound;
    } else if (isPlaylist) {
      message = l10n.playlistDoesNotExistError;
    } else {
      assert(false);
    }
    ShowFunctions.instance.showToast(msg: message);
    Navigator.of(context).pop();
  }

  void _handleAddTracks() {
    // With null it will be considered as "insert to the start"
    Song? selectedSong = songs.lastOrNull;
    bool tapped = false;
    AppRouter.instance.goto(AppRoutes.selection.withArguments(SelectionArguments(
      title: (context) => getl10n(context).addToPlaylist,
      settingsPageBuilder: (context) {
        final l10n = getl10n(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.trackAfterWhichToInsert,
              style: const TextStyle(fontSize: 20.0),
            ),
            leading: const NFBackButton(),
          ),
          body: StreamBuilder(
            stream: ContentControl.instance.onContentChange,
            builder: (context, snapshot) {
              final theme = Theme.of(context);
              final selectedTileColor = theme.colorScheme.primary;
              final selectedSplashColor = theme.appThemeExtension.glowSplashColorOnContrast;
              late StateSetter setListState;
              if (!tapped || selectedSong != null && !songs.contains(selectedSong)) {
                // Set last song on start and when the songs update and selected song was deleted
                selectedSong = songs.lastOrNull;
              }
              return StreamBuilder(
                stream: PlaybackControl.instance.onSongChange,
                builder: (context, snapshot) => StatefulBuilder(builder: (context, setState) {
                  setListState = setState;
                  return ContentListView(
                    contentType: ContentType.song,
                    list: songs,
                    enableDefaultOnTap: false,
                    leading: InListContentAction.song(
                      color: selectedSong == null ? selectedTileColor : null,
                      iconColor: selectedSong == null ? theme.colorScheme.onPrimary : null,
                      textColor: selectedSong == null ? theme.colorScheme.onPrimary : null,
                      splashColor: selectedSong == null ? selectedSplashColor : null,
                      icon: SweyerIcons.play_next,
                      text: l10n.insertAtTheBeginning,
                      onTap: () {
                        setListState(() {
                          tapped = true;
                          selectedSong = null;
                        });
                      },
                    ),
                    backgroundColorBuilder: (index) {
                      if (selectedSong == songs[index]) {
                        return selectedTileColor;
                      }
                      return Colors.transparent;
                    },
                    itemBuilder: (context, index, child) {
                      final selected = selectedSong == songs[index];
                      return Theme(
                        data: theme.copyWith(
                            splashColor: selected ? selectedSplashColor : theme.splashColor,
                            textTheme: theme.textTheme.copyWith(
                              // Title
                              headline6: theme.textTheme.headline6?.copyWith(
                                color: selected ? theme.colorScheme.onPrimary : null,
                              ),
                              // Subtitle
                              subtitle2: theme.textTheme.subtitle2?.copyWith(
                                color: selected ? theme.colorScheme.onPrimary : null,
                              ),
                            )),
                        child: child,
                      );
                    },
                    onItemTap: (index) {
                      setListState(() {
                        tapped = true;
                        selectedSong = songs[index];
                      });
                    },
                  );
                }),
              );
            },
          ),
        );
      },
      onSubmit: (entries) {
        int index;
        if (selectedSong == null) {
          index = 1;
        } else {
          index = songs.indexOf(selectedSong!) + 2;
          if (index <= 0) {
            index = 1;
          }
        }
        ContentControl.instance.insertSongsInPlaylist(
          index: index,
          songs: ContentUtils.flatten(ContentUtils.selectionPackAndSort(entries).merged),
          playlist: playlist,
        );
      },
    )));
  }

  bool editing = false;
  late List<Song> editingSongs;
  late final List<_ReorderOperation> reorderOperations = [];
  late final TextEditingController textEditingController = TextEditingController.fromValue(
    TextEditingValue(text: queue.title),
  );

  bool get _canSubmit => _renamed || _reordered;
  bool get _renamed => textEditingController.text.isNotEmpty && textEditingController.text != queue.title;
  bool get _reordered => reorderOperations.isNotEmpty;

  void _startEditing([bool init = false]) {
    if (isAlbum) {
      assert(false);
      return;
    }
    editing = true;
    editingSongs = List.from(queueSongs);
    textEditingController.text = queue.title;
    reorderOperations.clear();
    if (!init) {
      setState(() {});
    }
  }

  Future<void> _submitEditing() async {
    if (_canSubmit) {
      await Future.wait([
        _commitRename(),
        _commitReorder(),
      ]);
      setState(() {
        editing = false;
        editingSongs.clear();
        reorderOperations.clear();
      });
      await ContentControl.instance.refetchSongsAndPlaylists();
    } else {
      setState(() {
        editing = false;
        editingSongs.clear();
        reorderOperations.clear();
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      editing = false;
      textEditingController.text = queue.title;
      reorderOperations.clear();
    });
  }

  Future<void> _commitRename() async {
    if (!_renamed) {
      return;
    }
    final correctedName = await ContentControl.instance.renamePlaylist(playlist, textEditingController.text);
    if (correctedName == null) {
      _quitBecauseNotFound();
    } else {
      textEditingController.text = correctedName;
    }
  }

  Future<void> _commitReorder() async {
    if (!_reordered) {
      return;
    }
    final songIds = List<int>.from(playlist.songIds);
    for (final operation in reorderOperations) {
      final oldIndex = operation.oldIndex;
      final newIndex = operation.newIndex;
      final id = songIds.removeAt(oldIndex);
      songIds.insert(newIndex, id);
      await ContentControl.instance.moveSongInPlaylist(
        playlist: playlist,
        from: oldIndex,
        to: newIndex,
        emitChangeEvent: false,
      );
    }
    final index = ContentControl.instance.state.playlists.indexOf(playlist);
    ContentControl.instance.state.playlists[index] = playlist.copyWith(songIds: songIds);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final song = songs.removeAt(oldIndex);
      songs.insert(newIndex, song);
      reorderOperations.add(_ReorderOperation(oldIndex, newIndex));
    });
  }

  Widget _buildInfo() {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const titleFontSize = 24.0;
    final title = Text(
      isPlaylist ? textEditingController.text : queue.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        height: 1.0,
        fontSize: titleFontSize,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: 13.0,
        right: 10.0,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: appBarController,
            child: RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.only(
                  top: _infoSectionTopPadding,
                  bottom: _infoSectionBottomPadding,
                ),
                child: Row(
                  children: [
                    ContentArt(
                      size: 130.0,
                      defaultArtIcon: queue.icon,
                      defaultArtIconScale: 2,
                      assetHighRes: true,
                      assetScale: 1.5,
                      source: ContentArtSource.persistentQueue(queue),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isAlbum)
                              title
                            else if (isPlaylist)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: Stack(
                                  alignment: Alignment.bottomLeft,
                                  children: [
                                    AnimatedSwitcher(
                                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                        return Stack(
                                          alignment: Alignment.centerLeft,
                                          children: <Widget>[
                                            ...previousChildren,
                                            if (currentChild != null) currentChild,
                                          ],
                                        );
                                      },
                                      duration: const Duration(milliseconds: 300),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: editing
                                          ? AppTextField(
                                              controller: textEditingController,
                                              isDense: true,
                                              contentPadding: const EdgeInsets.only(top: -9.0, bottom: -6.0),
                                              textStyle: const TextStyle(
                                                fontSize: 24.0,
                                                fontWeight: FontWeight.w800,
                                                decoration: TextDecoration.underline,
                                              ),
                                              hintStyle: const TextStyle(
                                                fontSize: 22.0,
                                                height: 1.1,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            )
                                          : SizedBox(
                                              height: titleFontSize * textScaleFactor,
                                              child: title,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isAlbum)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ArtistWidget(
                                  artist: album.artist,
                                  overflow: TextOverflow.clip,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.0,
                                    color: theme.colorScheme.onBackground,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
                              child: Text(
                                ContentUtils.joinDot([
                                  if (isAlbum) l10n.album else l10n.playlist,
                                  if (isAlbum) album.year else l10n.contentsPlural(ContentType.song, queue.length),
                                  ContentUtils.bulkDuration(songs),
                                ]),
                                style: TextStyle(
                                  color: theme.textTheme.subtitle2!.color,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                            if (isPlaylist && !selectionRoute)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: Row(
                                    key: ValueKey(editing),
                                    children: !editing
                                        ? [
                                            _ActionIconButton(
                                              icon: const Icon(Icons.edit_rounded),
                                              iconSize: 20.0,
                                              onPressed: selectionController.inSelection ? null : _startEditing,
                                            ),
                                            _ActionIconButton(
                                              icon: const Icon(Icons.add_rounded),
                                              iconSize: 25.0,
                                              onPressed: selectionController.inSelection ? null : _handleAddTracks,
                                            ),
                                          ]
                                        : [
                                            _ActionIconButton(
                                              icon: const Icon(Icons.close_rounded),
                                              onPressed: _cancelEditing,
                                            ),
                                            AnimatedBuilder(
                                              animation: textEditingController,
                                              builder: (context, child) => _ActionIconButton(
                                                icon: const Icon(Icons.done_rounded),
                                                onPressed: _canSubmit ? _submitEditing : null,
                                              ),
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: _buttonSectionBottomPadding,
              // Compensate the padding difference up the tree
              right: 3.0,
            ),
            child: SizedBox(
              height: _buttonSectionButtonHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ShuffleQueueButton(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                              QueueControl.instance.setOriginQueue(
                                origin: queue,
                                songs: songs,
                                shuffled: true,
                              );
                              MusicPlayer.instance.setSong(QueueControl.instance.state.current.songs[0]);
                              MusicPlayer.instance.play();
                              if (!selectionController.inSelection) {
                                playerRouteController.open();
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: PlayQueueButton(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                              QueueControl.instance.setOriginQueue(origin: queue, songs: songs);
                              MusicPlayer.instance.setSong(songs[0]);
                              MusicPlayer.instance.play();
                              if (!selectionController.inSelection) {
                                playerRouteController.open();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final showAddSongsAction = isPlaylist && !selectionRoute;

            final songTileHeight = kSongTileHeight(context);

            /// The height to add at the end of the scroll view to make the top info part of the route
            /// always be fully scrollable, even if there's not enough items for that.
            final additionalHeight = constraints.maxHeight -
                _appBarHeight - //
                AppBarBorder.height - //
                mediaQuery.padding.top - //
                songTileHeight * songs.length - //
                (showAddSongsAction ? songTileHeight : 0.0); // InListContentAction

            return ScrollConfiguration(
              behavior: const GlowlessScrollBehavior(),
              child: StreamBuilder(
                stream: PlaybackControl.instance.onSongChange,
                builder: (context, snapshot) => CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  controller: scrollController,
                  slivers: [
                    AnimatedBuilder(
                      animation: appBarController,
                      child: const NFBackButton(),
                      builder: (context, child) => SliverAppBar(
                        pinned: true,
                        elevation: 0.0,
                        automaticallyImplyLeading: false,
                        toolbarHeight: _appBarHeight,
                        leading: child,
                        titleSpacing: 0.0,
                        backgroundColor: appBarController.isDismissed
                            ? theme.colorScheme.background
                            : theme.colorScheme.background.withOpacity(0.0),
                        title: AnimationSwitcher(
                          animation: CurvedAnimation(
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                            parent: selectionController.animation,
                          ),
                          child1: AnimatedOpacity(
                            opacity: 1.0 - appBarController.value > 0.35 ? 1.0 : 0.0,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 400),
                            child: Text(queue.title),
                          ),
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
                                if (isPlaylist && !selectionRoute)
                                  RemoveFromPlaylistSelectionAction(
                                    playlist: playlist,
                                    controller: selectionController,
                                  ),
                                SelectAllSelectionAction<Song>(
                                  controller: selectionController,
                                  entryFactory: (content, index) => SelectionEntry<Song>.fromContent(
                                    content: content,
                                    index: index,
                                    context: context,
                                  ),
                                  getAll: () => songs,
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildInfo(),
                    ),
                    SliverStickyHeader(
                      overlapsContent: false,
                      header: AnimatedBuilder(
                        animation: appBarController,
                        builder: (context, child) => AppBarBorder(
                          shown: scrollController.offset > _alwaysCanScrollExtent,
                        ),
                      ),
                      sliver: MultiSliver(
                        children: [
                          ContentListView.reorderableSliver(
                            contentType: ContentType.song,
                            list: songs,
                            selectionController: selectionController,
                            reorderingEnabled: editing,
                            onReorder: _handleReorder,
                            currentTest: (index) {
                              final song = songs[index];
                              return ContentUtils.originIsCurrent(queue) &&
                                  song.sourceId == PlaybackControl.instance.currentSong.sourceId &&
                                  (!isPlaylist ||
                                      (song.duplicationIndex == PlaybackControl.instance.currentSong.duplicationIndex));
                            },
                            songTileVariant: isAlbum ? SongTileVariant.number : SongTileVariant.albumArt,
                            enableDefaultOnTap: !editing,
                            onItemTap: editing
                                ? null
                                : (index) => QueueControl.instance.setOriginQueue(
                                      origin: queue,
                                      songs: songs,
                                    ),
                          ),
                          if (showAddSongsAction)
                            SliverToBoxAdapter(
                              child: InListContentAction.song(
                                onTap: editing || selectionController.inSelection ? null : _handleAddTracks,
                                icon: Icons.add_rounded,
                                text: l10n.addTracks,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (additionalHeight > 0)
                      SliverToBoxAdapter(
                        child: Container(
                          height: additionalHeight,
                          alignment: Alignment.center,
                          child: songs.isNotEmpty || showAddSongsAction
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: _alwaysCanScrollExtent + 30.0),
                                  child: Text(
                                    l10n.nothingHere,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 21.0,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late Animation<Color?> colorAnimation;

  bool get enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    if (enabled) {
      controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    colorAnimation = ColorTween(
      begin: theme.colorScheme.onSurface.withOpacity(0.12),
      end: theme.iconTheme.color,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
  }

  @override
  void didUpdateWidget(covariant _ActionIconButton oldWidget) {
    if (oldWidget.onPressed != widget.onPressed) {
      if (enabled) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => IgnorePointer(
        ignoring: const IgnoringStrategy(
          reverse: true,
          dismissed: true,
        ).ask(controller),
        child: NFIconButton(
          size: 30.0,
          iconSize: widget.iconSize,
          icon: widget.icon,
          onPressed: () {
            widget.onPressed?.call();
          },
          color: colorAnimation.value,
        ),
      ),
    );
  }
}
