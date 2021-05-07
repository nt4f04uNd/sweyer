/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:collection/collection.dart';
import 'package:sweyer/sweyer.dart';

/// Creates a content section, which a few content tiles and a header with name
/// of content type.
///
/// For example the search results are split into such sections.
class ContentSection<T extends Content> extends StatelessWidget {
  const ContentSection({
    Key? key,
    this.contentType,
    required this.list,
    this.onHeaderTap,
    this.maxPreviewCount = 5,
    this.selectionController,
    this.contentTileTapHandler,
  }) : child = null,
       super(key: key);

  const ContentSection.custom({
    Key? key,
    this.contentType,
    required this.list,
    required this.child,
    this.onHeaderTap,
  }) : selectionController = null,
       contentTileTapHandler = null,
       maxPreviewCount = 0,
       super(key: key);

  final Type? contentType;
  final List<T> list;

  final Widget? child;

  /// If specified, header will become tappable and near content name there will
  /// be chevron icon, idicating that it's tappable.
  final VoidCallback? onHeaderTap;

  /// Max amount of items shown in section.
  ///
  /// This does not affect the amount of items displayed on page opened
  /// by tapping header.
  final int maxPreviewCount;

  final ContentSelectionController? selectionController;

  /// Receives a type of tapped content tile and can be used to fire
  /// additional callbacks.
  final void Function<K extends Content>(Type)? contentTileTapHandler;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);

    Widget Function(int) forPersistentQueue<Q extends PersistentQueue>() => (int index) {
      final item = list[index] as Q;
      return PersistentQueueTile<Q>.selectable(
        index: index,
        selected: selectionController?.data
          .firstWhereOrNull((el) => el.data == item) != null,
        queue: list[index] as Q,
        selectionController: selectionController,
        small: false,
        horizontalPadding: 12.0,
        onTap: () => contentTileTapHandler?.call<Q>(Q),
      );
    };

    Widget Function(int)? builder;
    if (child == null) {
      builder = contentPick<T, Widget Function(int)>(
        contentType: contentType,
        song: (index) {
          final item = list[index] as Song;
          return SongTile.selectable(
            index: index,
            selected: selectionController?.data
              .firstWhereOrNull((el) => el.data == item) != null,
            song: item,
            selectionController: selectionController,
            horizontalPadding: 12.0,
            onTap: () => contentTileTapHandler?.call<Song>(Song),
          );
        },
        album: forPersistentQueue<Album>(),
        playlist: forPersistentQueue<Playlist>(),
        artist: (index) {
          final item = list[index] as Artist;
          return ArtistTile.selectable(
            index: index,
            selected: selectionController?.data
              .firstWhereOrNull((el) => el.data == item) != null,
            artist: item,
            selectionController: selectionController,
            horizontalPadding: 12.0,
            onTap: () => contentTileTapHandler?.call<Artist>(Artist),
          );
        },
      );
    }
  
    final count = list.length;

    return Column(
      children: [
        NFInkWell(
          onTap: onHeaderTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  l10n.contents<T>(contentType),
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: onHeaderTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ), 
          ),
        ),
        if (child != null)
          child!
        else
          Column(
            children: [
              for (int index = 0; index < math.min(maxPreviewCount, count); index ++)
                builder!(index),
            ],
          )
      ],
    );
  }
}