// lib/core/dialog_helper.dart

import 'package:flutter/material.dart';

Future<void> showExitConfirmationDialog(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi Keluar"),
      content: const Text(
          "Apakah Anda yakin ingin keluar? Semua data yang belum disimpan akan hilang."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Batal"),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Ya, Keluar"),
        ),
      ],
    ),
  );

  // Jika pengguna menekan "Ya, Keluar"
  if (confirmed == true && context.mounted) {
    Navigator.of(context).pop();
  }
}
