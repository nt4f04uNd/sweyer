/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';

class ExtendedSettingsRoute extends StatefulWidget {
  const ExtendedSettingsRoute({Key key}) : super(key: key);

  @override
  _ExtendedSettingsRouteState createState() => _ExtendedSettingsRouteState();
}

class _ExtendedSettingsRouteState extends State<ExtendedSettingsRoute> {
  /// Whether user changed something or not
  bool changed = false;

  /// Value before change
  ///
  /// Needed to check whether setting value has been increased or decreased
  int initSettingMinFileDuration = 30;
  int settingMinFileDuration = 30;

  /// Needed to update slider when setting gets fetched
  UniqueKey sliderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fetchMinFileDuration();
  }

  Future<void> _fetchMinFileDuration() async {
    final res = await Settings.minFileDurationInt.getPref();
    setState(() {
      initSettingMinFileDuration = res;
      settingMinFileDuration = res;
      sliderKey = UniqueKey();
    });
  }

  void _handleSliderChange(int newSettingMinFileDuration) {
    if (initSettingMinFileDuration != newSettingMinFileDuration)
      setState(() {
        changed = true;
        settingMinFileDuration = newSettingMinFileDuration;
      });
    else
      setState(() {
        changed = false;
        settingMinFileDuration = newSettingMinFileDuration;
      });
  }

  Future<void> _handleSave() async {
    Settings.minFileDurationInt.setPref(value: settingMinFileDuration);
    // TODO: rewrite this
    if (initSettingMinFileDuration <= settingMinFileDuration) {
      await ContentControl.filterSongs(emitChangeEvent: false);
      ContentControl.updatePlaylistsWithGlobal();
    } else{
      ContentControl.refetchSongs();
    }
    initSettingMinFileDuration = settingMinFileDuration;
    ShowFunctions.showToast(msg: "Настройки сохранены");
    if (mounted)
      setState(() {
        changed = false;
      });
  }

  Future<bool> _handlePop() async {
    if (!changed) return true;

    bool res = (await ShowFunctions.showDialog(
      context,
      title: Text("Сохранить настройки?"),
      content: Text(
          "Некоторые настройки были изменены, желаете ли вы сохранить их? Нажмите снаружи, чтобы остаться"),
      acceptButton: DialogRaisedButton.accept(text: "Сохранить"),
    ));

    if (res == null) {
      // Dismiss
      return false;
    } else if (res) {
      // Save confirmed
      _handleSave();
      return true;
    } else {
      // Save cancelled
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handlePop,
      child: PageBase(
        name: "Расширенные",
        backButton: SMMBackButton(
          onPressed: () async {
            if (await _handlePop()) Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          ChangedSwitcher(
            changed: changed,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 10.0, bottom: 10.0, right: 10.0),
              child: PrimaryRaisedButton(
                  text: "Сохранить", onPressed: _handleSave),
            ),
          )
        ],
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            _MinFileDurationSlider(
              key: sliderKey,
              parentHandleChange: _handleSliderChange,
              initValue: settingMinFileDuration,
            ),
          ],
        ),
      ),
    );
  }
}

class _MinFileDurationSlider extends StatefulWidget {
  final Function parentHandleChange;
  final int initValue;
  _MinFileDurationSlider(
      {Key key, @required this.initValue, @required this.parentHandleChange})
      : assert(initValue != null),
        assert(parentHandleChange != null),
        super(key: key);

  _MinFileDurationSliderState createState() => _MinFileDurationSliderState();
}

class _MinFileDurationSliderState extends State<_MinFileDurationSlider> {
  double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initValue.toDouble();
  }

  String _calcLabel() {
    String seconds = (_value % 60).round().toString();
    if (seconds.length < 2) seconds = "0$seconds";
    return "${_value ~/ 60}:$seconds";
  }

  void _handleChange(double newValue) {
    widget.parentHandleChange(newValue.toInt());
    setState(() {
      _value = newValue;
    });
  }

  void _handleChangeEnd(double newValue) {
    widget.parentHandleChange(_value.toInt());
    setState(() {
      _value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      title: "Минимальная длительность файла",
      description: "Скрыть файлы короче, чем ${_calcLabel()}",
      content: LabelledSlider(
        inactiveColor: Constants.AppTheme.sliderInactive.auto(context),
        min: 0,
        max: 60 * 5.0,
        divisions: 60,
        value: _value,
        onChanged: _handleChange,
        onChangeEnd: _handleChangeEnd,
        label: _calcLabel(),
        minLabel: '0 c',
        maxLabel: '5 мин',
      ),
    );
  }
}
