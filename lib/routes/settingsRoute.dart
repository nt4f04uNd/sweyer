import 'package:app/components/SlideStackRightRoute.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/prefs.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// @oldRoute needed cause this route transition utilizes `SlideStackRightRoute`
Route createSettingsRoute([Widget oldRoute]) {
  // final GlobalKey globalKey = GlobalKey<TrackListState>();
  // print(globalKey.currentState.);
  // return SlideStackRightRoute(exitPage: oldRoute, enterPage: SettingsRoute());
  return SlideStackRightRoute(exitPage: oldRoute, enterPage: SettingsRoute());
}

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key key}) : super(key: key);

  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  /// Whether user changed something or not
  bool isChanged = false;

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
    final res = await Prefs.byKey.settingMinFileDurationInt.getPref();
    setState(() {
      initSettingMinFileDuration = res ?? 30;
      settingMinFileDuration = res ?? 30; // Thirty seconds is default
      sliderKey = UniqueKey();
    });
  }

  void handleSliderChange(int newSettingMinFileDuration) {
    if (initSettingMinFileDuration != newSettingMinFileDuration)
      setState(() {
        isChanged = true;
        settingMinFileDuration = newSettingMinFileDuration;
      });
    else
      setState(() {
        isChanged = false;
        settingMinFileDuration = newSettingMinFileDuration;
      });
  }

  void _handleSave() async {
    Prefs.byKey.settingMinFileDurationInt.setPref(settingMinFileDuration);
    if (initSettingMinFileDuration <= settingMinFileDuration)
      PlaylistControl.filterSongs();
    else
      PlaylistControl.refetchSongs();
    initSettingMinFileDuration = settingMinFileDuration;
    Fluttertoast.showToast(
        msg: "Настройки сохранены",
        backgroundColor: Color.fromRGBO(18, 18, 18, 1));
    setState(() {
      isChanged = false;
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
          title: Text("Настройки"),
          actions: <Widget>[
            IgnorePointer(
              ignoring: !isChanged,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: isChanged ? 1.0 : 0.0,
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 10.0, bottom: 10.0, right: 10.0),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                    ),
                    child: Text("Сохранить"),
                    color: Colors.deepPurple,
                    onPressed: _handleSave,
                  ),
                ),
              ),
            )
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Container(
          padding: const EdgeInsets.all(8.0),
          child: ListView.separated(
            itemCount: 1,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) => Divider(),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: MinFileDurationSlider(
                  key: sliderKey,
                  parentHandleChange: handleSliderChange,
                  initValue: settingMinFileDuration,
                ),
              );
            },
          )),
    );
  }
}

class MinFileDurationSlider extends StatefulWidget {
  final Function parentHandleChange;
  final int initValue;
  MinFileDurationSlider(
      {Key key, @required this.initValue, @required this.parentHandleChange})
      : assert(initValue != null),
        assert(parentHandleChange != null),
        super(key: key);

  _MinFileDurationSliderState createState() => _MinFileDurationSliderState();
}

class _MinFileDurationSliderState extends State<MinFileDurationSlider> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Минимальная длительность файла',
            style: TextStyle(fontSize: 16.0)),
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Скрыть файлы короче, чем ${_calcLabel()}',
            style: TextStyle(color: Theme.of(context).textTheme.caption.color),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              transform: Matrix4.translationValues(0, 0, 0),
              child: Text(
                '0 c',
                style: TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Slider(
                activeColor: Colors.deepPurple,
                inactiveColor: Colors.white.withOpacity(0.2),
                min: 0,
                value: _value,
                max: 60 * 5.0,
                divisions: 60,
                label: _calcLabel(),
                onChanged: _handleChange,
                onChangeEnd: _handleChangeEnd,
              ),
            ),
            Container(
              transform: Matrix4.translationValues(-12, 0, 0),
              child: Text(
                '5 мин',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        )
      ],
    );
  }
}
