import 'package:flutter/material.dart';

class Notifier {

  static void showError(BuildContext context, String message) {

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(

        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),

        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showNotify(BuildContext context, String message) {

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(

        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),

        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        duration: const Duration(seconds: 2),
      ),
    );
  }
}