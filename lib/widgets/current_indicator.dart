import 'dart:async';
import 'dart:math' as math;
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';

/// Shows an indicator that marks out the current playing song tile.
/// Consists of three equalizer bars.
class CurrentIndicator extends StatelessWidget {
  const CurrentIndicator({
    super.key,
    this.color = Colors.white,
  });

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
    int? milliseconds,
    Curve? curve,
  ])  : _milliseconds = milliseconds,
        _curve = curve;

  final double height;
  final int? _milliseconds;
  final Curve? _curve;

  int get milliseconds => _milliseconds ?? 180;
  Curve get curve => _curve ?? Curves.linear;

  Duration get duration => Duration(milliseconds: milliseconds);
}

class _Bar extends StatefulWidget {
  const _Bar({
    required this.values,
    this.color,
  });

  final List<_Value> values;
  final Color? color;

  @override
  _BarState createState() => _BarState();
}

class _BarState extends State<_Bar> {
  late int index;
  Timer? timer;
  late StreamSubscription<bool> _playingSubscription;

  _Value get currentValue => widget.values[index];

  @override
  void initState() {
    super.initState();
    index = math.Random(clock.now().second).nextInt(widget.values.length);
    if (MusicPlayer.instance.playing) {
      start();
    }
    _playingSubscription = MusicPlayer.instance.playingStream.listen(_handlePlayerStateChange);
  }

  void _handlePlayerStateChange(bool playing) {
    if (playing) {
      start();
    } else {
      stop();
    }
  }

  void _iterate() {
    if (!mounted) {
      assert(false);
      timer!.cancel();
      timer = null;
    }
    timer = Timer(dilate(currentValue.duration), () {
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
        timer!.cancel();
        timer = null;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _playingSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animating = timer != null;
    return AnimatedContainer(
      height: animating ? 1.0 + 19.0 * currentValue.height : 3.0,
      curve: animating ? currentValue.curve : Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: const BorderRadius.all(
          Radius.circular(100.0),
        ),
      ),
      width: 5.0,
      duration: animating ? currentValue.duration : const Duration(milliseconds: 500),
    );
  }
}
