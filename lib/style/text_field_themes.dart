import 'package:flutter/material.dart';
import 'package:diohub/style/app_spacing.dart';

InputDecoration inputDecoration({
  required final BuildContext context,
  final String? labelText,
  final String? hintText,
  final FocusNode? focusNode,
  final IconData? icon,
  final EdgeInsetsGeometry? contentPadding,
  final Color? enabledBorderColor,
  final Widget? suffixIcon,
}) =>
    InputDecoration(
      labelText: labelText,
      hintText: hintText?.replaceRange(0, 0, ' '),
      contentPadding: contentPadding,
      suffixIcon: Padding(
        padding: context.spacing.pagePadding,
        child: suffixIcon ??
            Icon(
              icon,
            ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: enabledBorderColor ?? Colors.transparent),
      ),
    );
