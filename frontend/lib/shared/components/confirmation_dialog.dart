import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
  required String cancelLabel,
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: confirmColor ?? Colors.red),
          ),
        ),
      ],
    ),
  );
}
