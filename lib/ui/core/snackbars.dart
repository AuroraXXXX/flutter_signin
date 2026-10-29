import 'package:flutter/material.dart';

extension SnackBarMessages on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  void showError(String message) => showMessage(message);
}
