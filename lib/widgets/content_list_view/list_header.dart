/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class ListHeader extends StatelessWidget {
  const ListHeader({
    Key? key,
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

  final Widget? leading;
  final Widget? trailing;
  final Color? color;
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
          children: [
            if (leading != null) Expanded(child: leading!),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Displays content controls to sort content and content [count] at the trailing.
class ContentListHeader<T extends Content> extends StatelessWidget {
  /// Creats a default header with sort controls, count and slots widgets
  /// for other widgets.
  const ContentListHeader({
    Key? key,
    this.contentType,
    required this.count,
    this.selectionController,
    this.leading,
    this.trailing,
  }) : _onlyCount = false, super(key: key);

  /// Creates a header that shows only count.
  const ContentListHeader.onlyCount({
    Key? key,
    this.contentType,
    required this.count,
  }) : _onlyCount = true,
       selectionController = null,
       leading = null,
       trailing = null,
       super(key: key);

  final Type? contentType;

  final bool _onlyCount;

  /// Content count, will be displayed at the trailing.
  final int count;

  /// This needed to ignore the header sort buttons when the controller is in selection.
  /// This parameter can be `null`.
  final ContentSelectionController? selectionController;

  /// Additional widget to place after sorting controls.
  final Widget? leading;

  /// Additional widget to place before [count].
  final Widget? trailing;

  Sort<T> getSort() => ContentControl.state.sorts.getValue<T>(contentType) as Sort<T>;

  void _handleTap(BuildContext context) {
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
              l10n.utils.sortFeature<T>(feature as SortFeature<T>, contentType).toLowerCase(),
              style: ThemeControl.theme.textTheme.subtitle1,
            ),
            value: feature,
            groupValue: sort.feature,
            onChanged: (_) {
              ContentControl.sort(
                contentType: contentType,
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
      contentPadding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      acceptButton: const SizedBox.shrink(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: SortFeature
          .getValuesForContent<T>(contentType)
          .map((el) => buildItem(el))
          .toList(),
      ),
    );
  }

  Widget _buildCount(AppLocalizations l10n, TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 10.0),
      child: Text(
        l10n.utils.contentsPluralWithCount<T>(count, contentType),
        softWrap: false,
        overflow: TextOverflow.fade,
        style: textStyle,
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
    final child = ListHeader(
      margin: const EdgeInsets.only(
        top: 10.0,
        bottom: 4.0,
        left: 10.0,
        right: 7.0,
      ),
      trailing: _onlyCount
        ? null
        : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (trailing != null)
              trailing!,
            Flexible(
              child: _buildCount(l10n, textStyle),
            ),
          ],
        ),
      leading: _onlyCount ? _buildCount(l10n, textStyle) : Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NFListTileInkRipple.splashFactory,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ContentListHeaderAction(
              icon: Icon(sort.orderAscending 
                ? Icons.north_rounded
                : Icons.south_rounded),
              onPressed: () {
                ContentControl.sort(
                  contentType: contentType,
                  sort: sort.copyWith(orderAscending: !sort.orderAscending),
                );
              },
            ),
            Flexible(
              child: InkResponse(
                onTap: () => _handleTap(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Text(
                    l10n.utils.sortFeature<T>(sort.feature, contentType),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: textStyle,
                  ),
                ),
              ),
            ),
            if (leading != null)
              leading!
          ],
        ),
      ),
    );
    if (selectionController == null)
      return child;
    return IgnoreInSelection(
      controller: selectionController!,
      child: child,
    );
  }
}

class _RadioListTile<T> extends StatelessWidget {
  const _RadioListTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
  }) : super(key: key);

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Widget? title;

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
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
            if (title != null)
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

/// A small button to be placed into [ContentListSortHeader].
class ContentListHeaderAction extends StatelessWidget {
  const ContentListHeaderAction({
    Key? key,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback? onPressed;

  static const size = 28.0;

  @override
  Widget build(BuildContext context) {
    return NFIconButton(
      icon: icon,
      size: size,
      iconSize: 20.0,
      onPressed: onPressed,
    );
  }
}

/// A small button to be placed into [ContentListSortHeader] with animation.
class AnimatedContentListHeaderAction extends StatelessWidget {
  const AnimatedContentListHeaderAction({
    Key? key,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedIconButton(
      icon: icon,
      size: ContentListHeaderAction.size,
      iconSize: 20.0,
      onPressed: onPressed,
    );
  }
}
