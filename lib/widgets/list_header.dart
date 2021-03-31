/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class ListHeader extends StatelessWidget {
  const ListHeader({
    Key key,
    this.leading,
    this.trailing,
    this.color,
    this.margin = const EdgeInsets.only(
      top: 10.0,
      bottom: 2.0,
      left: 13.0,
      right: 7.0,
    ),
  }) : super(key: key);

  final Widget leading;
  final Widget trailing;
  final Color color;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(
        fontSize: 16.0,
        color: ThemeControl.theme.hintColor,
        fontWeight: FontWeight.w700,
      ),
      child: Container(
        color: color,
        padding: margin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            if (leading != null) leading,
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

abstract class SortListHeader<T extends Content> extends StatelessWidget {
  const SortListHeader({
    Key key,
    @required this.count,
    @required this.selectionController,
  })  : assert(count != null),
        super(key: key);

  final int count;

  /// This needed to ignore the header sort buttons when the controller is in selection.
  /// This parameter can be `null`.
  final SelectionController<SelectionEntry<T>> selectionController;

  Sort<T> getSort() => ContentControl.state.sorts.getValue<T>();

  String getContentCountText(AppLocalizations l10n) {
    final plural = contentPick<T, String Function(int)>(
      song: l10n.tracksPlural,
      album: l10n.albumsPlural,
    )(count).toLowerCase();
    return '$count $plural';
  }

  void _handleTap() {
    final context = HomeRouter.instance.navigatorKey.currentContext;
    final l10n = getl10n(context);
    final sort = getSort();
    Widget buildItem(SortFeature feature) {
      return Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NFListTileInkRipple.splashFactory,
        ),
        child: Builder( // i need the proper context to pop the dialog
          builder: (context) => _RadioListTile<SortFeature>(
            title: Text(
              l10n.sortFeature<T>(feature).toLowerCase(),
              style: ThemeControl.theme.textTheme.subtitle1,
            ),
            value: feature,
            groupValue: sort.feature,
            onChanged: (_) {
              ContentControl.sort(
                sort: sort.copyWith(feature: feature).withDefaultOrder,
              );
              Navigator.pop(context);
            },
          ),
        ),
      );
    }

    ShowFunctions.instance.showAlert(
      context,
      ui: Constants.UiTheme.modalOverGrey.auto,
      title: Text(l10n.sort),
      titlePadding: defaultAlertTitlePadding.copyWith(top: 20.0),
      contentPadding: EdgeInsets.only(top: 5.0, bottom: 10.0),
      acceptButton: SizedBox.shrink(),
      content: Column(
        children: contentPick<T, List<SortFeature> Function()>(
          song: () => SongSortFeature.values,
          album: () => AlbumSortFeature.values,
        )().map((el) => buildItem(el)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final textStyle = TextStyle(
      color: ThemeControl.theme.colorScheme.onBackground,
      fontSize: 14.0,
      fontWeight: FontWeight.w800,
    );
    final sort = getSort();
    Widget child = ListHeader(
      margin: const EdgeInsets.only(
        top: 10.0,
        bottom: 4.0,
        left: 10.0,
        right: 7.0,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Text(
          getContentCountText(l10n),
          style: textStyle,
        ),
      ),
      leading: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NFListTileInkRipple.splashFactory,
        ),
        child: Row(
          children: [
            NFIconButton(
              icon: _OrderSwitcher(
                ascending: sort.orderAscending,
              ),
              size: 28.0,
              iconSize: 20.0,
              onPressed: () {
                ContentControl.sort(
                  sort: sort.copyWith(orderAscending: !sort.orderAscending),
                );
              },
            ),
            InkResponse(
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 2.0,
                ),
                child: Text(
                  l10n.sortFeature<T>(sort.feature),
                  style: textStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (selectionController == null)
      return child;
    return AnimatedBuilder(
      animation: selectionController.animationController,
      builder: (context, child) => IgnorePointer(
        ignoring: const IgnoringStrategy(
          forward: true,
          completed: true,
        ).evaluate(selectionController.animationController),
        child: child,
      ),
      child: child,
    );
  }
}

class _RadioListTile<T> extends StatelessWidget {
  const _RadioListTile({
    Key key,
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.title,
  }) : super(key: key);
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Widget title;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 14.0),
        child: Row(
          children: [
            Radio<T>(
              activeColor: ThemeControl.isDark
                  ? ThemeControl.theme.colorScheme.onBackground
                  : ThemeControl.theme.colorScheme.primary,
              value: value,
              splashRadius: 0.0,
              groupValue: groupValue,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: title,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSwitcher extends StatelessWidget {
  const _OrderSwitcher({Key key, this.ascending}) : super(key: key);
  final bool ascending;
  @override
  Widget build(BuildContext context) {
    return Icon(ascending ? Icons.north_rounded : Icons.south_rounded);
  }
}

class SongSortListHeader extends SortListHeader<Song> {
  const SongSortListHeader({
    Key key,
    @required int count,
    @required SelectionController selectionController,
  }) : super(key: key, count: count, selectionController: selectionController);
}

class AlbumSortListHeader extends SortListHeader<Album> {
  const AlbumSortListHeader({
    Key key,
    @required int count,
    @required SelectionController selectionController,
  }) : super(key: key, count: count, selectionController: selectionController);
}
