import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// The screen that contains the text message and the widget slot.
class CenterContentScreen extends StatelessWidget {
  const CenterContentScreen({
    Key? key,
    required this.text,
    required this.widget,
  }) : super(key: key);

  final String text;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: widget,
              )
            ],
          ),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              leading: const SettingsButton(),
            ),
          ),
        ],
      ),
    );
  }
}
