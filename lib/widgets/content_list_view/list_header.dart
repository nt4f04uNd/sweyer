import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({
    Key? key,
    this.leading,
    this.trailing,
    this.color,
    this.wrap = false,
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
  final bool wrap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: 16.0,
            color: theme.hintColor,
            fontWeight: FontWeight.w700,
          ),
      child: Container(
        color: color,
        padding: margin,
        child: wrap
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (leading != null) leading!,
                      if (trailing != null) trailing!,
                    ],
                  ),
                ],
              )
            : Row(
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
  /// Create a default header with sort controls, count and slots widgets
  /// for other widgets.
  const ContentListHeader({
    Key? key,
    required this.contentType,
    required this.count,
    this.selectionController,
    this.leading,
    this.trailing,
  })  : _onlyCount = false,
        super(key: key);

  /// Creates a header that shows only count.
  const ContentListHeader.onlyCount({
    Key? key,
    required this.contentType,
    required this.count,
  })  : _onlyCount = true,
        selectionController = null,
        leading = null,
        trailing = null,
        super(key: key);

  final ContentType<T> contentType;

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

  Sort<T> getSort() => ContentControl.instance.state.sorts.get(contentType) as Sort<T>;

  void _handleTap(BuildContext context) {
    final l10n = getl10n(context);
    final sort = getSort();
    ShowFunctions.instance.showRadio<SortFeature<T>>(
      context: context,
      title: l10n.sort,
      items: SortFeature.getValuesForContent(contentType),
      itemTitleBuilder: (item) => l10n.sortFeature(contentType, item),
      onItemSelected: (item) => ContentControl.instance.sort(
        contentType: contentType,
        sort: sort.copyWith(feature: item).withDefaultOrder,
      ),
      groupValueGetter: () => sort.feature,
    );
  }

  Widget _buildCount(AppLocalizations l10n, TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 10.0),
      child: Text(
        l10n.contentsPlural(contentType, count),
        softWrap: false,
        overflow: TextOverflow.fade,
        style: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      color: theme.colorScheme.onBackground,
      fontSize: 14.0,
      fontWeight: FontWeight.w800,
    );
    final sort = getSort();
    final child = ListHeader(
      wrap: true,
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
                if (trailing != null) trailing!,
                Flexible(
                  child: _buildCount(l10n, textStyle),
                ),
              ],
            ),
      leading: _onlyCount
          ? _buildCount(l10n, textStyle)
          : Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NFListTileInkRipple.splashFactory,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ContentListHeaderAction(
                    icon: Icon(sort.order == SortOrder.ascending ? Icons.north_rounded : Icons.south_rounded),
                    onPressed: () {
                      ContentControl.instance.sort(
                        contentType: contentType,
                        sort: sort.copyWith(order: sort.order.inverted),
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
                          l10n.sortFeature(contentType, sort.feature),
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: textStyle,
                        ),
                      ),
                    ),
                  ),
                  if (leading != null) leading!
                ],
              ),
            ),
    );
    if (selectionController == null) {
      return child;
    }
    return IgnoreInSelection(
      controller: selectionController!,
      child: child,
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
