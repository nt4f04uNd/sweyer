import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sweyer/sweyer.dart';

class Seekbar extends StatefulWidget {
  const Seekbar({
    super.key,
    this.color,
    this.player,
    this.duration,
  });

  /// Color of the active slider part.
  ///
  /// If non specified [ColorScheme.primary] color will be used.
  final Color? color;

  /// Player to use instead of [MusicPlayer], which is used by default.
  final AudioPlayer? player;

  /// Predefined duration to use.
  final Duration? duration;

  @override
  _SeekbarState createState() => _SeekbarState();
}

class _SeekbarState extends State<Seekbar> with SingleTickerProviderStateMixin {
  // Duration of playing track.
  Duration _duration = Duration.zero;

  /// Actual track position value.
  double _value = 0.0;

  /// Value to perform drag.
  late double _localValue;

  /// Is user dragging slider right now.
  bool _isDragging = false;

  /// Value to work with.
  double? get workingValue => _isDragging ? _localValue : _value;

  late StreamSubscription<Duration> _positionSubscription;
  StreamSubscription<Song>? _songChangeSubscription;

  AudioPlayer get player => widget.player ?? MusicPlayer.instance;

  late AnimationController animationController;
  late Animation<double> thumbSizeAnimation;

  @override
  void initState() {
    super.initState();
    final duration = widget.duration ?? player.duration;
    if (duration != null) {
      _duration = duration;
    }
    _value = _positionToValue(player.position);
    // Handle track position movement
    _positionSubscription = player.positionStream.listen((position) {
      if (!_isDragging) {
        setState(() {
          _value = _positionToValue(position);
        });
      }
    });
    if (widget.player == null) {
      // Handle track switch
      _songChangeSubscription = PlaybackControl.instance.onSongChange.listen((song) {
        setState(() {
          _isDragging = false;
          _localValue = 0.0;
          // Not setting to 0, because even though I'm initializing player in proper order, i.e.
          // set song and then seek to needed position, it still fires in reverse, not sure why.
          _value = _positionToValue(MusicPlayer.instance.position);
          _duration = Duration(milliseconds: song.duration);
        });
      });
    }
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    thumbSizeAnimation = Tween(
      begin: 7.0,
      end: 9.0,
    ).animate(CurvedAnimation(
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      parent: animationController,
    ));
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _songChangeSubscription?.cancel();
    animationController.dispose();
    super.dispose();
  }

  double _positionToValue(Duration position) {
    return (position.inMilliseconds / math.max(_duration.inMilliseconds, 1.0)).clamp(0.0, 1.0);
  }

  // Drag functions
  void _handleChangeStart(double newValue) {
    setState(() {
      _isDragging = true;
      _localValue = newValue;
    });
  }

  void _handleChanged(double newValue) {
    setState(() {
      if (animationController.status != AnimationStatus.completed &&
          animationController.status != AnimationStatus.forward) {
        animationController.forward();
      }
      _localValue = newValue;
    });
  }

  Future<void> _handleChangeEnd(double newValue) async {
    await player.seek(_duration * newValue);
    if (mounted) {
      setState(() {
        _isDragging = false;
        _value = newValue;
        animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scaleFactor = textScaleFactor == 1.0 ? 1.0 : textScaleFactor * 1.1;

    final wrapLabels = textScaleFactor > 1.5;

    final leftLabel = Container(
      width: 36.0 * scaleFactor,
      transform: Matrix4.translationValues(5.0, 0.0, 0.0),
      child: Text(
        formatDuration(_duration * workingValue!),
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.titleLarge!.color,
        ),
      ),
    );

    final rightLabel = Container(
      width: 36.0 * scaleFactor,
      transform: Matrix4.translationValues(-5.0, 0.0, 0.0),
      child: Text(
        formatDuration(_duration),
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.titleLarge!.color,
        ),
      ),
    );

    final slider = AnimatedBuilder(
      animation: thumbSizeAnimation,
      builder: (context, child) => SliderTheme(
        data: SliderThemeData(
          trackHeight: 2.0,
          thumbColor: color,
          overlayColor: color.withValues(alpha: ThemeControl.instance.isLight ? 0.12 : 0.24),
          activeTrackColor: color,
          inactiveTrackColor: theme.appThemeExtension.sliderInactiveColor,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 17.0),
          thumbShape: RoundSliderThumbShape(
            pressedElevation: 3.0,
            enabledThumbRadius: thumbSizeAnimation.value,
          ),
        ),
        child: child!,
      ),
      child: Slider(
        value: _isDragging ? _localValue : _value,
        onChangeStart: _handleChangeStart,
        onChanged: _handleChanged,
        onChangeEnd: _handleChangeEnd,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: wrapLabels
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                slider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    leftLabel,
                    rightLabel,
                  ],
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                leftLabel,
                Expanded(child: slider),
                rightLabel,
              ],
            ),
    );
  }
}
