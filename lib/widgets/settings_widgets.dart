import 'package:flutter/material.dart';

/// Creates a setting item with [title], [description] and [content] sections
class SettingItem extends StatelessWidget {
  const SettingItem({
    super.key,
    required this.title,
    required this.content,
    this.description,
    this.trailing,
  });

  /// Text displayed as main title of the settings
  final String title;

  /// A place for a custom widget (e.g. slider)
  final Widget content;

  /// Text displayed as the settings description
  final String? description;

  /// A place for widget to display at the end of title line
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //******** Title ********
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16.0),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          //******** Description ********
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                description!,
                style: TextStyle(
                  color: theme.textTheme.bodySmall!.color,
                ),
              ),
            ),
          //******** Content ********
          content
        ],
      ),
    );
  }
}

/// A widget that shows or hides a [child] performing an animation.
/// Can be used to make 'save' buttons, for example.
///
/// The [child] is untouchable in the animation.
class ChangedSwitcher extends StatefulWidget {
  const ChangedSwitcher({
    super.key,
    this.child,
    this.changed = false,
  });

  final Widget? child;

  /// When true, the [child] is shown and clickable.
  /// When false, the [child] is hidden and untouchable, but occupies the same space.
  ///
  /// Represents that some setting has been changed.
  final bool changed;

  @override
  _ChangedSwitcherState createState() => _ChangedSwitcherState();
}

class _ChangedSwitcherState extends State<ChangedSwitcher> {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.changed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        opacity: widget.changed ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: widget.changed ? EdgeInsets.zero : const EdgeInsets.only(right: 3.0),
          child: widget.child,
        ),
      ),
    );
  }
}
