import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class AppRadioListTile<T> extends StatelessWidget {
  const AppRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 14.0),
        child: Row(
          children: [
            Radio<T>(
              activeColor:
                  ThemeControl.instance.isDark ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.primary,
              value: value,
              splashRadius: 0.0,
              groupValue: groupValue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
            if (title != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: title,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
