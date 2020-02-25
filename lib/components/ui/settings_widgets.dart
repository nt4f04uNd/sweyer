/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// Creates a setting item with [title], [description] and [content] sections
class SettingItem extends StatelessWidget {
  const SettingItem({
    Key key,
    @required this.title,
    this.description,
    this.content,
  })  : assert(title != null),
        super(key: key);

  /// Text displayed as main title of the settings
  final String title;

  /// Text displayed as the settings description
  final String description;

  /// A place for a custom widget (e.g. slider)
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //******** Title ********
          Text(
            title,
            style: const TextStyle(fontSize: 16.0),
          ),
          //******** Description ********
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.caption.color,
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
