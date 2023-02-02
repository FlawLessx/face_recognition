import 'package:flutter/material.dart';

void showSnackbar(
  BuildContext context,
  String message,
  bool isSuccess, {
  bool floating = true,
  Color? color,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        backgroundColor: color ?? (isSuccess ? Colors.green : Colors.red),
      ),
    );
}
