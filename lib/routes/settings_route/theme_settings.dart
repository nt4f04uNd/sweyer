import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

const double _colorItemSize = 36.0;
const double _colorItemActiveBorderWidth = 2.5;

class ThemeSettingsRoute extends StatefulWidget {
  const ThemeSettingsRoute({super.key});
  @override
  _ThemeSettingsRouteState createState() => _ThemeSettingsRouteState();
}

class _ThemeSettingsRouteState extends State<ThemeSettingsRoute> with SingleTickerProviderStateMixin {
  late Color prevPrimaryColor;
  late Color primaryColor;
  bool firstRender = true;
  bool get switched => ThemeControl.instance.isLight;
  bool get canPop => !ThemeControl.instance.themeChanging.valueWrapper!.value;
  late AnimationController controller;

  static const List<Color> colors = [
    constants.AppColors.deepPurpleAccent,
    constants.AppColors.yellow,
    constants.AppColors.blue,
    constants.AppColors.red,
    constants.AppColors.orange,
    constants.AppColors.pink,
    constants.AppColors.androidGreen,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (firstRender) {
      firstRender = false;
      prevPrimaryColor = theme.colorScheme.primary;
      primaryColor = theme.colorScheme.primary;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleThemeSwitch(bool value) {
    ThemeControl.instance.switchTheme();
  }

  void _handleColorTap(Color color) {
    if (color != primaryColor) {
      setState(() {
        prevPrimaryColor = ColorTween(
          begin: prevPrimaryColor,
          end: primaryColor,
        ).evaluate(controller)!;
      });
      primaryColor = color;
      ThemeControl.instance.changePrimaryColor(color);
      controller.reset();
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final animation = ColorTween(
      begin: prevPrimaryColor,
      end: primaryColor,
    ).animate(controller);
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitleMarquee(text: l10n.theme),
          leading: IgnorePointer(
            ignoring: !canPop,
            child: const NFBackButton(),
          ),
        ),
        body: ScrollConfiguration(
          behavior: const GlowlessScrollBehavior(),
          child: AnimatedBuilder(
            animation: animation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              height: 53.0,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, idx) => ColorItem(
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
              children: [
                const PlayerInterfaceColorStyleSettingWidget(),
                Theme(
                  data: theme.copyWith(
                    splashFactory: NFListTileInkRipple.splashFactory,
                  ),
                  child: SwitchListTile(
                    title: Text(l10n.settingLightMode),
                    activeColor: animation.value,
                    value: switched,
                    onChanged: _handleThemeSwitch,
                  ),
                ),
                child!,
                Image.asset(
                  constants.Assets.assetLogoMask,
                  color: ContentArt.getColorToBlendInDefaultArt(animation.value!),
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

@visibleForTesting
class ColorItem extends StatefulWidget {
  const ColorItem({
    super.key,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  final Color color;
  final bool active;
  final VoidCallback? onTap;

  @override
  _ColorItemState createState() => _ColorItemState();
}

class _ColorItemState extends State<ColorItem> with SingleTickerProviderStateMixin {
  late AnimationController controller;

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
  void didUpdateWidget(covariant ColorItem oldWidget) {
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
          animation: animation,
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
            final borderContainerSize = _colorItemSize + _colorItemActiveBorderWidth * 2 - margin;
            return Stack(
              alignment: Alignment.center,
              children: [
                child!,
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
