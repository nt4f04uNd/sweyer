/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:catcher/core/catcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/api.dart' as API;
import 'package:flutter/material.dart';

import 'package:sweyer/constants.dart' as Constants;

import 'package:flutter/scheduler.dart' show timeDilation;

class DebugRoute extends StatelessWidget {
  DebugRoute({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageBase(
      name: "Дебаг",
      child: Container(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            ListTile(
              title: Text('Остановить сервис'),
              onTap: () {
                API.ServiceHandler.stopService();
              },
            ),
            ListTile(
              title: Text('Тестовый тост'),
              onTap: () {
                ShowFunctions.showToast(
                  msg: "Тест",
                  toastLength: Toast.LENGTH_LONG,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            _TimeDilationSlider(),
            Builder(
              builder: (BuildContext context) => ListTile(
                title: Text('Сгенерировать ошибку'),
                onTap: () async {
                  Catcher.sendTestException();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeDilationSlider extends StatefulWidget {
  _TimeDilationSlider({Key key}) : super(key: key);

  _TimeDilationSliderState createState() => _TimeDilationSliderState();
}

class _TimeDilationSliderState extends State<_TimeDilationSlider> {
  double _value;

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
    return SettingItem(
      title: "Замедление анимаций",
      trailing: ChangedSwitcher(
        changed: _value != 1.0,
        child: ButtonTheme(
          height: 36.0,
          child: PrimaryRaisedButton(
            text: "Сбросить",
            onPressed: () {
              _handleChangeEnd(1.0);
            },
          ),
        ),
      ),
      content: LabelledSlider(
        inactiveColor: Constants.AppTheme.sliderInactive.auto(context),
        min: 0.001,
        max: 10,
        divisions: 100,
        value: _value,
        onChanged: _handleChange,
        onChangeEnd: _handleChangeEnd,
        label: "x" + _value.toStringAsFixed(3),
        minLabel: 'x0',
        maxLabel: 'x10',
        themeData:
            SliderThemeData(tickMarkShape: SliderTickMarkShape.noTickMark),
      ),
    );
  }
}
