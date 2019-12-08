import 'player.dart';
import 'package:flutter/material.dart';

/// Component to show artist, or automatically show "Неизвестный исполнитель" instead of "<unknown>"
class Artist extends StatelessWidget {
  final String artist;
  const Artist({Key key, @required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        artistString(artist),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          //Default flutter subtitle font size (not densed)
          fontSize: 14,
          // This is used in ListTile elements
          color: Theme.of(context).textTheme.caption.color,
        ),
      ),
    );
  }
}
