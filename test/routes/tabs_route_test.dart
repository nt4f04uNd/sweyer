import 'package:flutter/material.dart';

import '../test.dart';

void main() {
  testWidgets('tabs - can switch with swipe', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Songs tab
      expect(find.byType(SongTile), findsOneWidget);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Albums tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsOneWidget);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Playlists tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsOneWidget);
      expect(find.byType(ArtistTile), findsNothing);

      await tester.fling(find.byType(TabBarView), const Offset(-400.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      // Artists tab
      expect(find.byType(SongTile), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsNothing);
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsNothing);
      expect(find.byType(ArtistTile), findsOneWidget);
    });
  });

  testWidgets('tabs - can switch with buttons', (WidgetTester tester) async {
    await tester.runAppTest(() async {
      // Start from songs tab
      expect(find.byType(SongTile), findsOneWidget);

      // Switch to albums tab
      await tester.tap(find.byIcon(ContentType.album.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<PersistentQueueTile<Album>>()), findsOneWidget);

      // Switch to playlists tab
      await tester.tap(find.byIcon(ContentType.playlist.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<PersistentQueueTile<Playlist>>()), findsOneWidget);

      // Switch to artists tab
      await tester.tap(find.byIcon(ContentType.artist.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<ArtistTile>()), findsOneWidget);

      // Switch back to songs tab
      await tester.tap(find.byIcon(ContentType.song.icon));
      await tester.pumpAndSettle();
      expect(find.byType(typeOf<SongTile>()), findsOneWidget);
    });
  });

  testWidgets('sort order button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0, dateModified: 2),
      songWith(id: 1, dateModified: 1),
      songWith(id: 2, dateModified: 0),
    ]);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = songs.toList();
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);

      // Change sort order
      await tester.tap(find.byIcon(Icons.south_rounded));
      await tester.pump();
      tester.expectSongTiles(songs.reversed);
    });
  });

  testWidgets('sort feature button works', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0, dateModified: 2, title: 'c'),
      songWith(id: 1, dateModified: 1, title: 'b'),
      songWith(id: 2, dateModified: 0, title: 'a'),
    ]);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = songs.toList();
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);

      // Change sort feature
      await tester.tap(find.text(l10n.sortFeature(ContentType.song, SongSortFeature.dateModified)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.sortFeature(ContentType.song, SongSortFeature.title)));
      await tester.pump();
      tester.expectSongTiles(songs.reversed);
    });
  });

  testWidgets('displays label scrollbar when sorted by title', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable(
      List.generate(
        100,
        (index) => songWith(
          id: index,
          dateModified: 100 - 1 - index,
          title: String.fromCharCode(65 + index % 26),
        ),
      ),
    );

    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = songs.toList();
    });
    await tester.runAppTest(() async {
      // Change sort feature
      await tester.tap(find.text(l10n.sortFeature(ContentType.song, SongSortFeature.dateModified)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.sortFeature(ContentType.song, SongSortFeature.title)));
      await tester.pumpAndSettle();

      // Drag at the center of the screen should show no labels
      await tester.timedDrag(find.byType(ContentListView), const Offset(0, -100), Durations.medium2);
      expect(find.byType(NFScrollLabel), findsNothing);

      // Drag in the scrollbar area should show a label until the drag is finished
      await tester.timedDragFrom(
        tester.getTopRight(find.byType(ContentListView)) + const Offset(-47, 10),
        const Offset(0, -100),
        Durations.medium2,
      );
      expect(find.byType(NFScrollLabel), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsNothing);

      // Drag on the scrollbar should show a label until the drag is finished
      await tester.fling(
          find.byType(ContentListView), const Offset(0, -100), 1.0); // Fling to make the scrollbar visible
      await tester.timedDragFrom(tester.getTopRight(find.byType(ContentListView)) + const Offset(-2, 10),
          const Offset(-100, -100), Durations.medium2);
      expect(find.byType(NFScrollLabel), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsNothing);

      // Drag in the scrollbar area should show a label until the drag is finished,
      // but label should disappear when the drag goes out of the scrollbar area nd reappear if it goes back in.
      final drag = await tester.startGesture(tester.getTopRight(find.byType(ContentListView)) + const Offset(-47, 10));
      await drag.moveBy(const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsOneWidget);
      await drag.moveBy(const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsNothing);
      await drag.moveBy(const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsOneWidget);
      await drag.up();
      await tester.pumpAndSettle();
      expect(find.byType(NFScrollLabel), findsNothing);
    });
  });

  testWidgets('displays correct songs length', (WidgetTester tester) async {
    final List<Song> songs = List.unmodifiable([
      songWith(id: 0),
      songWith(id: 1),
      songWith(id: 2),
    ]);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = songs.toList();
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);
      expect(find.text(l10n.tracksPlural(3)), findsOneWidget);

      // Change songs length
      ContentControl.instance.state.allSongs.songs.removeLast();
      ContentControl.instance.emitContentChange();
      await tester.pump();

      tester.expectSongTiles(songs.toList()..removeLast());
      expect(find.text(l10n.tracksPlural(2)), findsOneWidget);
    });
  });

  testWidgets('track favourite filter button works', (WidgetTester tester) async {
    final notFavoriteSong1 = songWith(id: 0);
    final notFavoriteSong2 = songWith(id: 1);
    final favoriteSong1 = songWith(id: 2);
    final favoriteSong2 = songWith(id: 3);
    final List<Song> songs = List.unmodifiable([
      notFavoriteSong1,
      notFavoriteSong2,
      favoriteSong1,
      favoriteSong2,
    ]);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = songs.toList();
    });
    await tester.runAppTest(() async {
      tester.expectSongTiles(songs);

      // Filter by favourites
      await tester.tap(find.descendant(of: find.byType(TabsRoute), matching: find.byType(HeartButton)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.nothingHere), findsOneWidget);

      // Add favourites
      await FakeFavoritesControl.instance
          .setFavorite(contentTuple: ContentTuple(songs: [favoriteSong1, favoriteSong2]), value: true);
      await tester.pumpAndSettle();
      tester.expectSongTiles([favoriteSong1, favoriteSong2]);

      await tester.runAsync(() => tester.tap(find.byType(SongTile).first));
      expect(QueueControl.instance.state.type, QueueType.favouriteSongs);
      expect(QueueControl.instance.state.current.songs, [favoriteSong1, favoriteSong2]);
    });
  });

  testWidgets('album favourite filter button works', (WidgetTester tester) async {
    final notFavoriteAlbum1 = albumWith(id: 0);
    final favoriteAlbum2 = albumWith(id: 1);
    final notFavoriteAlbum1Song1 = songWith(id: 0, albumId: notFavoriteAlbum1.id, album: notFavoriteAlbum1.title);
    final notFavoriteAlbum1Song2 = songWith(id: 1, albumId: notFavoriteAlbum1.id, album: notFavoriteAlbum1.title);
    final favoriteAlbum2Song3 = songWith(id: 2, albumId: favoriteAlbum2.id, album: favoriteAlbum2.title);
    final favoriteAlbum2Song4 = songWith(id: 3, albumId: favoriteAlbum2.id, album: favoriteAlbum2.title);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [
        notFavoriteAlbum1Song1,
        notFavoriteAlbum1Song2,
        favoriteAlbum2Song3,
        favoriteAlbum2Song4
      ];
      FakeSweyerPluginPlatform.instance.albums = [notFavoriteAlbum1, favoriteAlbum2];
    });
    await tester.runAppTest(() async {
      // Switch to albums tab
      await tester.tap(find.byIcon(ContentType.album.icon));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<ContentTile>(find.byType(ContentTile)).map((album) => album.content as Album).toList(),
        [notFavoriteAlbum1, favoriteAlbum2],
      );

      // Filter by favourites
      await tester.tap(find.descendant(of: find.byType(TabsRoute), matching: find.byType(HeartButton)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.nothingHere), findsOneWidget);

      // Add favourites
      await FakeFavoritesControl.instance
          .setFavorite(contentTuple: ContentTuple(albums: [favoriteAlbum2]), value: true);
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<ContentTile>(find.byType(ContentTile)).map((album) => album.content as Album).toList(),
        [favoriteAlbum2],
      );

      await tester.runAsync(() => tester.tap(find.byIcon(Icons.play_arrow_rounded)));
      expect(QueueControl.instance.state.type, QueueType.favouriteAlbums);
      expect(QueueControl.instance.state.current.songs, [favoriteAlbum2Song3, favoriteAlbum2Song4]);
    });
  });

  testWidgets('playlist favourite filter button works', (WidgetTester tester) async {
    final notFavoritePlaylist1Song1 = songWith(id: 0);
    final notFavoritePlaylist1Song2 = songWith(id: 1);
    final favoritePlaylist2Song3 = songWith(id: 2);
    final favoritePlaylist2Song4 = songWith(id: 3);
    final notFavoritePlaylist1 =
        playlistWith(id: 0, songIds: [notFavoritePlaylist1Song1.id, notFavoritePlaylist1Song2.id]);
    final favoritePlaylist2 = playlistWith(id: 1, songIds: [favoritePlaylist2Song3.id, favoritePlaylist2Song4.id]);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [
        notFavoritePlaylist1Song1,
        notFavoritePlaylist1Song2,
        favoritePlaylist2Song3,
        favoritePlaylist2Song4
      ];
      FakeSweyerPluginPlatform.instance.playlists = [notFavoritePlaylist1, favoritePlaylist2];
    });
    await tester.runAppTest(() async {
      // Switch to playlists tab
      await tester.tap(find.byIcon(ContentType.playlist.icon));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ContentTile>(find.byType(ContentTile))
            .map((playlist) => playlist.content as Playlist)
            .toList(),
        [notFavoritePlaylist1, favoritePlaylist2],
      );

      // Filter by favourites
      await tester.tap(find.descendant(of: find.byType(TabsRoute), matching: find.byType(HeartButton)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.nothingHere), findsOneWidget);

      // Add favourites
      await FakeFavoritesControl.instance
          .setFavorite(contentTuple: ContentTuple(playlists: [favoritePlaylist2]), value: true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ContentTile>(find.byType(ContentTile))
            .map((playlist) => playlist.content as Playlist)
            .toList(),
        [favoritePlaylist2],
      );

      await tester.runAsync(() => tester.tap(find.byIcon(Icons.play_arrow_rounded)));
      expect(QueueControl.instance.state.type, QueueType.favouritePlaylists);
      expect(QueueControl.instance.state.current.songs, [favoritePlaylist2Song3, favoritePlaylist2Song4]);
    });
  });

  testWidgets('artist favourite filter button works', (WidgetTester tester) async {
    final notFavoriteArtist1 = artistWith(id: 0);
    final favoriteArtist2 = artistWith(id: 1);
    final notFavoriteArtist1Song1 = songWith(id: 0, artistId: notFavoriteArtist1.id, artist: notFavoriteArtist1.title);
    final notFavoriteArtist1Song2 = songWith(id: 1, artistId: notFavoriteArtist1.id, artist: notFavoriteArtist1.title);
    final favoriteArtist2Song3 = songWith(id: 2, artistId: favoriteArtist2.id, artist: favoriteArtist2.title);
    final favoriteArtist2Song4 = songWith(id: 3, artistId: favoriteArtist2.id, artist: favoriteArtist2.title);
    registerAppSetup(() {
      FakeSweyerPluginPlatform.instance.songs = [
        notFavoriteArtist1Song1,
        notFavoriteArtist1Song2,
        favoriteArtist2Song3,
        favoriteArtist2Song4
      ];
      FakeSweyerPluginPlatform.instance.artists = [notFavoriteArtist1, favoriteArtist2];
    });
    await tester.runAppTest(() async {
      // Switch to artists tab
      await tester.tap(find.byIcon(ContentType.artist.icon));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<ContentTile>(find.byType(ContentTile)).map((artist) => artist.content as Artist).toList(),
        [notFavoriteArtist1, favoriteArtist2],
      );

      // Filter by favourites
      await tester.tap(find.descendant(of: find.byType(TabsRoute), matching: find.byType(HeartButton)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.nothingHere), findsOneWidget);

      // Add favourites
      await FakeFavoritesControl.instance
          .setFavorite(contentTuple: ContentTuple(artists: [favoriteArtist2]), value: true);
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<ContentTile>(find.byType(ContentTile)).map((album) => album.content as Artist).toList(),
        [favoriteArtist2],
      );

      await tester.runAsync(() => tester.tap(find.byIcon(Icons.play_arrow_rounded)));
      expect(QueueControl.instance.state.type, QueueType.favouriteArtists);
      expect(QueueControl.instance.state.current.songs, [favoriteArtist2Song3, favoriteArtist2Song4]);
    });
  });
}
