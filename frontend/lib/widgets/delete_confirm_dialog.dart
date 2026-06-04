import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final String titulo;

  const DeleteConfirmDialog({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: const Text('Remover material'),
      description: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Tem certeza que deseja remover "$titulo"? Esta ação não pode ser desfeita.'),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remover'),
        ),
      ],
    );
  }
}
