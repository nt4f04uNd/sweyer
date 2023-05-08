import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';

/// Themed app scrollbar.
class AppScrollbar extends StatefulWidget {
  /// Creates a scrollbar, draggable by default.
  const AppScrollbar({
    Key? key,
    this.labelBuilder,
    required this.child,
    this.controller,
    this.thumbVisibility,
    this.showTrackOnHover,
    this.hoverThickness,
    this.thickness,
    this.radius,
    this.notificationPredicate,
    this.interactive = true,
  }) : super(key: key);

  /// Creates a scrollbar, draggable by default.
  /// Automatically passes [labelBuilder] dependent on content type `T` and
  /// uses passed content [list] in it.
  ///
  /// It is also possible to disable the label with [showLabel].
  @factory
  static AppScrollbar forContent<T extends Content>({
    Key? key,
    required ContentType<T> contentType,
    required List<T> list,
    required Widget child,
    required ScrollController controller,
    bool showLabel = true,
    bool? thumbVisibility,
    bool? showTrackOnHover,
    double? hoverThickness,
    double? thickness,
    Radius? radius,
    ScrollNotificationPredicate? notificationPredicate,
    bool? interactive,
  }) {
    return AppScrollbar(
      key: key,
      labelBuilder: !showLabel
          ? null
          : (context) {
              final l10n = getl10n(context);
              final item =
                  list[(controller.position.pixels / kSongTileHeight(context) - 1).clamp(0.0, list.length - 1).round()];
              return NFScrollLabel(text: () {
                // TODO: Remove ContentType cast, see https://github.com/dart-lang/language/issues/2315
                // ignore: unnecessary_cast
                switch (contentType as ContentType) {
                  case ContentType.song:
                    return (item as Song).title[0].toUpperCase();
                  case ContentType.album:
                    return (item as Album).album[0].toUpperCase();
                  case ContentType.playlist:
                    return (item as Playlist).name[0].toUpperCase();
                  case ContentType.artist:
                    return ContentUtils.localizedArtist((item as Artist).artist, l10n)[0].toUpperCase();
                }
              }());
            },
      controller: controller,
      thumbVisibility: thumbVisibility,
      showTrackOnHover: showTrackOnHover,
      hoverThickness: hoverThickness,
      thickness: thickness,
      radius: radius,
      notificationPredicate: notificationPredicate,
      interactive: interactive,
      child: child,
    );
  }

  final WidgetBuilder? labelBuilder;
  final Widget child;
  final ScrollController? controller;
  final bool? thumbVisibility;
  final bool? showTrackOnHover;
  final double? hoverThickness;
  final double? thickness;
  final Radius? radius;
  final ScrollNotificationPredicate? notificationPredicate;
  final bool? interactive;

  @override
  _AppScrollbarState createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  /// Whether to show content label indicators while scrolling.
  bool showScrollLabels = false;

  /// The horizontal offset from the scrollbar side of the window in which a drag should show content labels.
  static const scrollLabelDragAreaWidth = 48;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? PrimaryScrollController.of(context);
    final theme = Theme.of(context);
    final highlightColor = theme.highlightColor;
    return Theme(
      data: theme.copyWith(
          highlightColor: ThemeControl.instance.isDark ? const Color(0x40CCCCCC) : const Color(0x66BCBCBC),
          scrollbarTheme: widget.hoverThickness == null
              ? theme.scrollbarTheme
              : theme.scrollbarTheme.copyWith(thickness: MaterialStateProperty.all(widget.hoverThickness))),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (widget.labelBuilder == null) {
              return false;
            }
            final Offset? dragPosition;
            if (notification is ScrollStartNotification) {
              dragPosition = notification.dragDetails?.localPosition;
            } else if (notification is ScrollUpdateNotification) {
              dragPosition = notification.dragDetails?.localPosition;
            } else if (notification is OverscrollNotification) {
              dragPosition = notification.dragDetails?.localPosition;
            } else {
              dragPosition = null;
            }
            final windowSize = context.size;
            final shouldShowScrollLabels = windowSize != null &&
                dragPosition != null &&
                (Directionality.of(context) == TextDirection.rtl
                    ? (dragPosition.dx < scrollLabelDragAreaWidth && dragPosition.dx >= 0)
                    : (dragPosition.dx > windowSize.width - scrollLabelDragAreaWidth &&
                        dragPosition.dx <= windowSize.width));
            if (shouldShowScrollLabels != showScrollLabels) {
              setState(() {
                showScrollLabels = shouldShowScrollLabels;
              });
            }
            return false;
          },
          child: Stack(
            children: [
              Scrollbar(
                controller: controller,
                thumbVisibility: widget.thumbVisibility,
                trackVisibility: widget.showTrackOnHover,
                thickness: widget.thickness,
                radius: widget.radius,
                notificationPredicate: widget.notificationPredicate,
                interactive: widget.interactive,
                child: Theme(
                  data: theme.copyWith(highlightColor: highlightColor),
                  child: widget.child,
                ),
              ),
              if (widget.labelBuilder != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: !showScrollLabels
                      ? null
                      : Center(
                          child: AnimatedBuilder(
                            animation: controller,
                            builder: (context, child) => widget.labelBuilder!(context),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
