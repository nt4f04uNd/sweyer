/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Creates a setting item with [title], [description] and [content] sections
class SettingItem extends StatelessWidget {
  const SettingItem({
    Key? key,
    required this.title,
    required this.content,
    this.description,
    this.trailing,
  }) : super(key: key);

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
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //******** Title ********
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
              if (trailing != null)
                trailing!
            ],
          ),
          //******** Description ********
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                description!,
                style: TextStyle(
                  color: ThemeControl.theme.textTheme.caption!.color,
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
  ChangedSwitcher({
    Key? key,
    this.child,
    this.changed = false,
  }) : super(key: key);

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
          padding: widget.changed
              ? EdgeInsets.zero
              : const EdgeInsets.only(right: 3.0),
          child: widget.child,
        ),
      ),
    );
  }
}
