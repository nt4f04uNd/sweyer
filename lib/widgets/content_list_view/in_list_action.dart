/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Action to be displayed directly in the content list.
class InListContentAction extends StatefulWidget {
  /// Creats action with paddings for song list.
  const InListContentAction.song({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : horizontalPadding = kSongTileHorizontalPadding,
       super(key: key);

  /// Creats action with paddings for persistent queue list.
  const InListContentAction.persistentQueue({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : horizontalPadding = kPersistentQueueTileHorizontalPadding,
       super(key: key);

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final double horizontalPadding;

  @override
  State<InListContentAction> createState() => _InListContentActionState();
}

class _InListContentActionState extends State<InListContentAction> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final fadeAnimation = Tween(
    begin: 0.2,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  bool get enabled => widget.onTap != null;

  @override
  void initState() { 
    super.initState();
    if (enabled) {
      controller.forward();
    } 
  }
  
  @override
  void didUpdateWidget(covariant InListContentAction oldWidget) {
    if (oldWidget.onTap != widget.onTap) {
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
    return FadeTransition(
      opacity: fadeAnimation,
      child: NFInkWell(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          height: kSongTileHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: kSongTileArtSize,
                width: kSongTileArtSize,
                decoration: BoxDecoration(
                  color: Constants.Theme.glowSplashColor.auto,
                  borderRadius: const BorderRadius.all(Radius.circular(kArtBorderRadius)),
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 36.0),
              ),
              Expanded(
                child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    widget.text,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeControl.theme.textTheme.headline6,
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
