import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

class DevRoute extends ConsumerStatefulWidget {
  const DevRoute({super.key});

  @override
  ConsumerState<DevRoute> createState() => _DevRouteState();
}

class _DevRouteState extends ConsumerState<DevRoute> {
  void _testToast() {
    ShowFunctions.instance.showToast(
      msg: 'Test',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _showDebugOverlay() {
    ref.watch(debugManagerProvider).showOverlay();
  }

  Future<void> _quitDevMode() async {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final res = await ShowFunctions.instance.showDialog(
      context,
      title: Text(l10n.areYouSure),
      content: Text(l10n.quitDevModeDescription),
      buttonSplashColor: theme.appThemeExtension.glowSplashColor,
      acceptButton: AppButton.pop(
        text: l10n.accept,
        popResult: true,
        splashColor: theme.appThemeExtension.glowSplashColor,
        textColor: constants.AppColors.red,
      ),
    );
    if (res != null && res as bool) {
      Prefs.devMode.set(false);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debug),
        leading: const NFBackButton(),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                NFListTile(
                  title: Text(l10n.devTestToast),
                  onTap: _testToast,
                ),
                NFListTile(
                  title: Text(l10n.debugShowDebugOverlay),
                  onTap: _showDebugOverlay,
                ),
                const MaterialAppSwitchesWidget(),
                const _TimeDilationSlider(),
              ],
            ),
          ),
          NFListTile(
            title: Text(l10n.quitDevMode),
            splashColor: theme.colorScheme.error,
            onTap: _quitDevMode,
          ),
        ],
      ),
    );
  }
}

class _TimeDilationSlider extends StatefulWidget {
  const _TimeDilationSlider();

  @override
  _TimeDilationSliderState createState() => _TimeDilationSliderState();
}

class _TimeDilationSliderState extends State<_TimeDilationSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = timeDilation;
  }

  void _handleChange(double newValue) {
    setState(() {
      _value = newValue;
    });
  }

  void _handleChangeEnd(double newValue) {
    setState(() {
      timeDilation = newValue;
      _value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    return SettingItem(
      title: l10n.devAnimationsSlowMo,
      trailing: ChangedSwitcher(
        changed: _value != 1.0,
        child: ButtonTheme(
          height: 36.0,
          child: AppButton(
            text: l10n.reset,
            onPressed: () {
              _handleChangeEnd(1.0);
            },
          ),
        ),
      ),
      content: LabelledSlider(
        inactiveColor: theme.appThemeExtension.sliderInactiveColor,
        min: 0.001,
        max: 10,
        divisions: 100,
        value: _value,
        onChanged: _handleChange,
        onChangeEnd: _handleChangeEnd,
        label: 'x${_value.toStringAsFixed(3)}',
        minLabel: 'x0',
        maxLabel: 'x10',
        themeData: SliderThemeData(
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
      ),
    );
  }
}
