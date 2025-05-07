import 'package:flutter/material.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';

Future<bool?> confirmDialog(
  BuildContext context,
  String title,
  String content,
  String cancelText,
  String confirmText, {
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: kSecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: kSecondaryColor),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              if (onCancel != null) {
                onCancel();
              }
            },
            child: Text(
              cancelText,
              style: TextStyle(color: kSecondaryColor.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              if (onConfirm != null) {
                onConfirm();
              }
            },
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}