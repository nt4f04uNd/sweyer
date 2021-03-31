/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

/// Shows an indicator that marks out the current playing song tile.
/// Consists of three equalizer bars.
class CurrentIndicator extends StatelessWidget {
  const CurrentIndicator({Key key, this.color = Colors.white})
      : assert(color != null),
        super(key: key);

  /// Color of the bars.
  final Color color;

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(width: 3.0);
    return SizedBox(
      height: 20.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Bar(
            color: color,
            values: const [
              _Value(0.2, 150),
              _Value(0.7, 300),
              _Value(0.9, 300, Curves.easeOutCubic),
              _Value(0.7, 100),
              _Value(0.9, 200),
              _Value(0.3, 400),
              _Value(0.8, 400),
              _Value(0.3, 300),
              _Value(0.5, 150),
            ],
          ),
          spacer,
          _Bar(
            color: color,
            values: const [
              _Value(0.2, 400),
              _Value(0.8, 300),
              _Value(0.6),
              _Value(0.9, 300),
              _Value(0.7),
              _Value(1.0, 200),
              _Value(0.5, 250),
              _Value(0.9),
            ],
          ),
          spacer,
          _Bar(
            color: color,
            values: const [
              _Value(0.3, 200, Curves.easeOut),
              _Value(0.9, 250),
              _Value(0.5, 240),
              _Value(0.9, 240),
              _Value(0.5),
              _Value(0.85, 180, Curves.easeOutCubic),
              _Value(1.0, 180, Curves.easeOutCubic),
              _Value(0.5, 350),
              _Value(0.8),
              _Value(0.9),
              _Value(0.6, 200),
              _Value(0.8, 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _Value {
  const _Value(
    this.height, [
    int milliseconds,
    Curve curve,
  ])  : _milliseconds = milliseconds,
        _curve = curve;

  final double height;
  final int _milliseconds;
  final Curve _curve;

  int get milliseconds => _milliseconds ?? 180;
  Curve get curve => _curve ?? Curves.linear;

  Duration get duration => Duration(milliseconds: milliseconds);
}

class _Bar extends StatefulWidget {
  const _Bar({
    Key key,
    this.values,
    this.color,
  }) : super(key: key);
  final List<_Value> values;
  final Color color;
  @override
  _BarState createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  int index;
  Timer timer;
  StreamSubscription<MusicPlayerState> _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    index = math.Random().nextInt(widget.values.length);
    if (MusicPlayer.playerState == MusicPlayerState.PLAYING) {
      start();
    }
    _playerStateSubscription = MusicPlayer.onStateChange.listen(_handlePlayerStateChange);
  }

  void _handlePlayerStateChange(state) {
    switch (state) {
      case MusicPlayerState.PLAYING:
        start();
        break;
      case MusicPlayerState.PAUSED:
      case MusicPlayerState.COMPLETED:
      default:
        stop();
        break;
    }
  }

  void _iterate() {
    if (!mounted) {
      assert(false);
      timer.cancel();
      timer = null;
    }
    timer = Timer(dilate(widget.values[index].duration), () {
      setState(() {
        if (index == widget.values.length - 1) {
          index = 0;
        } else {
          index++;
        }
      });
      _iterate();
    });
  }

  Future<void> start() async {
    if (timer == null) {
      _iterate();
    }
  }

  void stop() {
    if (timer != null && mounted) {
      setState(() {
        timer.cancel();
        timer = null;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _playerStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animating = timer != null;
    return AnimatedContainer(
      height: animating ? 1.0 + 19.0 * widget.values[index].height : 3.0,
      curve: animating ? widget.values[index].curve : Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: const BorderRadius.all(
          Radius.circular(100.0),
        ),
      ),
      width: 5.0,
      duration: animating
          ? widget.values[index].duration
          : const Duration(milliseconds: 500),
    );
  }
}
