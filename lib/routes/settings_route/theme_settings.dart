/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

const double _colorItemSize = 36.0;
const double _colorItemActiveBorderWidth = 2.5;

class ThemeSettingsRoute extends StatefulWidget {
  const ThemeSettingsRoute({Key key}) : super(key: key);
  @override
  _ThemeSettingsRouteState createState() => _ThemeSettingsRouteState();
}

class _ThemeSettingsRouteState extends State<ThemeSettingsRoute>
    with SingleTickerProviderStateMixin {
  Color prevPrimaryColor = ThemeControl.theme.colorScheme.primary;
  Color primaryColor = ThemeControl.theme.colorScheme.primary;
  bool get switched => ThemeControl.isLight;
  bool get canPop => !ThemeControl.themeChaning;
  AnimationController controller;

  static const List<Color> colors = [
    Constants.AppColors.deepPurpleAccent,
    Constants.AppColors.yellow,
    Constants.AppColors.blue,
    Constants.AppColors.red,
    Constants.AppColors.orange,
    Constants.AppColors.pink,
    Constants.AppColors.androidGreen,
  ];

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: ThemeControl.primaryColorChangeDuration,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleThemeSwitch(bool value) {
    ThemeControl.switchTheme();
  }

  void _handleColorTap(Color color) {
    prevPrimaryColor = ColorTween(
      begin: prevPrimaryColor,
      end: primaryColor,
    ).evaluate(controller);
    ThemeControl.changePrimaryColor(color);
    primaryColor = color;
    controller.reset();
    controller.forward();
  }

  Future<bool> _handlePop() {
    return Future.value(canPop);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final animation = ColorTween(
      begin: prevPrimaryColor,
      end: primaryColor,
    ).animate(controller);
    return WillPopScope(
      onWillPop: _handlePop,
      child: NFPageBase(
        name: l10n.theme,
        backButton: IgnorePointer(
          ignoring: !canPop,
          child: const NFBackButton(),
        ),
        child: ScrollConfiguration(
          behavior: const GlowlessScrollBehavior(),
          child: AnimatedBuilder(
            animation: controller,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              height: 53.0,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, idx) => _ColorItem(
                    color: colors[idx],
                    active: colors[idx] == primaryColor,
                    onTap: () {
                      _handleColorTap(colors[idx]);
                    }),
                separatorBuilder: (context, idx) => const SizedBox(
                  width: 20.0,
                ),
              ),
            ),
            builder: (context, child) => ListView(
              children: <Widget>[
                Theme(
                  data: ThemeControl.theme.copyWith(
                    splashFactory: NFListTileInkRipple.splashFactory,
                  ),
                  child: SwitchListTile(
                    title: Text(l10n.settingLightMode),
                    activeColor: animation.value,
                    value: switched,
                    onChanged: _handleThemeSwitch,
                  ),
                ),
                child,
                Image.asset(
                  Constants.Assets.ASSET_LOGO_MASK,
                  color: getColorForBlend(animation.value),
                  colorBlendMode: BlendMode.plus,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorItem extends StatefulWidget {
  const _ColorItem({
    Key key,
    this.color,
    this.active = false,
    this.onTap,
  }) : super(key: key);
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  _ColorItemState createState() => _ColorItemState();
}

class _ColorItemState extends State<_ColorItem> with SingleTickerProviderStateMixin {
  AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.active) {
      controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _ColorItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
      parent: controller,
    );
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: _colorItemSize,
        child: AnimatedBuilder(
          animation: controller,
          child: Container(
            width: _colorItemSize,
            height: _colorItemSize,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: const BorderRadius.all(
                Radius.circular(40.0),
              ),
            ),
          ),
          builder: (context, child) {
            final margin = 12.0 * animation.value;
            final borderContainerSize =
                _colorItemSize + _colorItemActiveBorderWidth * 2 - margin;
            return Stack(
              alignment: Alignment.center,
              children: [
                child,
                FadeTransition(
                  opacity: animation,
                  child: Container(
                    width: borderContainerSize,
                    height: borderContainerSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40.0),
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: _colorItemActiveBorderWidth,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
