import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

// TODO: https://lottiefiles.com/82795-favorite-icon
// TODO: https://lottiefiles.com/89039-add-to-favorite
class FavoriteIndicator extends StatelessWidget {
  const FavoriteIndicator({
    Key? key,
    this.size,
  }) : super(key: key);

  final double? size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.redAccent,
        size: size,
      ),
    );
  }
}
