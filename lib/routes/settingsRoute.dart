import 'package:app/components/SlideStackRightRoute.dart';
import 'package:app/constants/themes.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/prefs.dart';
import 'package:app/player/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key key}) : super(key: key);

  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  bool _switched;

  @override
  void initState() {
    super.initState();
    _switched = ThemeControl.isDark;
  }

  void _switchTheme() {
    setState(() {
      ThemeControl.switchTheme();
      _switched = !_switched;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(63.0), // here the desired height
        child: AppBar(
          titleSpacing: 0.0,
          backgroundColor: Colors.transparent,
          title: Text("Настройки",
              style: TextStyle(color: Theme.of(context).textTheme.title.color)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Container(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            // Padding(
            //   padding: const EdgeInsets.only(left: 12.0),
            //   child: MinFileDurationSlider(
            //     key: sliderKey,
            //     parentHandleChange: handleSliderChange,
            //     initValue: settingMinFileDuration,
            //   ),
            // ),
            // Divider(),
            ListTile(
              title: Text("Расширенные настройки"),
              onTap: () {
                Navigator.of(context).pushNamed("/extendedSettings");
              },
            ),
            GestureDetector(
              onTap: _switchTheme,
              child: ListTile(
                title: Text("Темная тема"),
                trailing: Switch(
                  activeColor: Theme.of(context).primaryColor,
                  value: _switched,
                  onChanged: (value) {
                    _switchTheme();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
