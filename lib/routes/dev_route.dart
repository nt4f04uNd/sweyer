/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

class DevRoute extends StatelessWidget {
  const DevRoute({Key? key}) : super(key: key);

  void _testToast() {
    ShowFunctions.instance.showToast(
      msg: 'Test',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  Future<void> _quitDevMode(BuildContext context, AppLocalizations l10n) async {
    final nfl10n = NFLocalizations.of(context);
    final res = await ShowFunctions.instance.showDialog(
      context,
      title: Text(l10n.areYouSure),
      content: Text(l10n.quitDevModeDescription),
      buttonSplashColor: Constants.Theme.glowSplashColor.auto,
      acceptButton: NFButton.accept(
        text: nfl10n.accept,
        splashColor: Constants.Theme.glowSplashColor.auto,
        textStyle: const TextStyle(color: Constants.AppColors.red),
      ),
    );
    if (res != null && res as bool) {
      Prefs.devMode.set(false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debug),
        leading: const NFBackButton(),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                NFListTile(
                  title: Text(l10n.devTestToast),
                  onTap: _testToast,
                ),
                const _TimeDilationSlider(),
              ],
            ),
          ),
          NFListTile(
            title: Text(l10n.quitDevMode),
            splashColor: ThemeControl.theme.colorScheme.error,
            onTap: () => _quitDevMode(context, l10n),
          ),
        ],
      ),
    );
  }
}

class _TimeDilationSlider extends StatefulWidget {
  const _TimeDilationSlider({Key? key}) : super(key: key);

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
    return SettingItem(
      title: l10n.devAnimationsSlowMo,
      trailing: ChangedSwitcher(
        changed: _value != 1.0,
        child: ButtonTheme(
          height: 36.0,
          child: NFButton(
            variant: NFButtonVariant.raised,
            text: l10n.reset,
            onPressed: () {
              _handleChangeEnd(1.0);
            },
          ),
        ),
      ),
      content: LabelledSlider(
        inactiveColor: Constants.Theme.sliderInactiveColor.auto,
        min: 0.001,
        max: 10,
        divisions: 100,
        value: _value,
        onChanged: _handleChange,
        onChangeEnd: _handleChangeEnd,
        label: 'x' + _value.toStringAsFixed(3),
        minLabel: 'x0',
        maxLabel: 'x10',
        themeData: SliderThemeData(
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
      ),
    );
  }
}
