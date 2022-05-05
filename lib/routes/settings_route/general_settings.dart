import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';

class GeneralSettingsRoute extends StatefulWidget {
  const GeneralSettingsRoute({Key? key}) : super(key: key);
  @override
  _GeneralSettingsRouteState createState() => _GeneralSettingsRouteState();
}

class _GeneralSettingsRouteState extends State<GeneralSettingsRoute> {
  /// Needed as init value and also to check whether setting
  /// value has been increased or decreased.
  int minFileDuration = 30;
  /// Whether to show a confirmation toast before exiting the app
  late bool confirmOnExitEnabled;

  @override
  void initState() {
    super.initState();
    confirmOnExitEnabled = Prefs.confirmOnExit.get();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.general),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SwitchListTile(
            title: Text(l10n.confirmBeforeExitingSetting),
            value: confirmOnExitEnabled,
            onChanged: _handleConfirmOnExitSwitch,
          ),
          // _MinFileDurationSlider(
          //   initValue: minFileDuration,
          // ),
        ],
      ),
    );
  }
  
  /// Handle a change of the exit confirmation setting
  /// and update the preference and the screen. 
  void _handleConfirmOnExitSwitch(bool newValue) {
    Prefs.confirmOnExit.set(newValue);
    setState(() {
      confirmOnExitEnabled = newValue;
    });
  }
}

// class _MinFileDurationSlider extends StatefulWidget {
//   final Function onChangeEnd;
//   final int initValue;
//   _MinFileDurationSlider(
//       {Key key, @required this.initValue, @required this.onChangeEnd})
//       : assert(initValue != null),
//         assert(onChangeEnd != null),
//         super(key: key);

//   _MinFileDurationSliderState createState() => _MinFileDurationSliderState();
// }

// class _MinFileDurationSliderState extends State<_MinFileDurationSlider> {
//   double _value;

//   @override
//   void initState() {
//     super.initState();
//     _value = widget.initValue.toDouble();
//   }

//   String _calcLabel() {
//     String seconds = (_value % 60).round().toString();
//     if (seconds.length < 2) seconds = '0$seconds';
//     return '${_value ~/ 60}:$seconds';
//   }

//   void _handleChange(double newValue) {
//     setState(() {
//       _value = newValue;
//     });
//   }

//   void _handleChangeEnd(double newValue) {
//     widget.onChangeEnd(_value.toInt());
//     setState(() {
//       _value = newValue;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = getl10n(context);
//     return SettingItem(
//       title: l10n.settingMinFileDuration,
//       description: l10n.settingHideFilesShorterThan + _calcLabel(),
//       content: LabelledSlider(
//         inactiveColor: Constants.Theme.sliderInactive.auto,
//         min: 0,
//         max: 60 * 5.0,
//         divisions: 60,
//         value: _value,
//         onChanged: _handleChange,
//         onChangeEnd: _handleChangeEnd,
//         label: _calcLabel(),
//         minLabel: '0 ' + l10n.secondsShorthand,
//         maxLabel: '5 ' + l10n.minutesShorthand,
//       ),
//     );
//   }
// }
