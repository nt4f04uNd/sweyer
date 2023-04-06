import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Creates an icon button that adds a content entry to selection.
class AddToSelectionButton<T extends SelectionEntry> extends StatelessWidget {
  const AddToSelectionButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  static const size = kSongTileArtSize;

  /// The padding that is preferred between this action and other UI elements.
  static const preferredPadding = 4.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: NFIconButton(
        icon: const Icon(Icons.add_rounded),
        size: size,
        onPressed: onPressed,
      ),
    );
  }
}
