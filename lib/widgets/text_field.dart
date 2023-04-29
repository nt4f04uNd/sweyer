import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    Key? key,
    this.onSubmit,
    this.autofocus = false,
    this.isDense = false,
    this.maxLines = 1,
    this.textStyle,
    this.hintStyle,
    this.contentPadding,
    this.controller,
    this.onDispose,
  }) : super(key: key);

  final ValueSetter<String>? onSubmit;
  final bool autofocus;
  final bool isDense;
  final int maxLines;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final TextEditingController? controller;
  final VoidCallback? onDispose;

  @override
  _AppTextFieldState createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    return TextField(
      selectionControls: NFTextSelectionControls(),
      controller: widget.controller,
      autofocus: widget.autofocus,
      style: theme.textTheme.titleLarge?.merge(widget.textStyle) ?? widget.textStyle,
      minLines: 1,
      maxLines: widget.maxLines,
      onSubmitted: widget.onSubmit,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: widget.contentPadding,
        hintText: l10n.title,
        hintStyle: widget.hintStyle,
        isDense: widget.isDense,
      ),
    );
  }
}
