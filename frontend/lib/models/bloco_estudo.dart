import 'package:flutter/material.dart';

class BlocoEstudo {
  final String id;
  final String disciplina;
  final Color cor;
  final DateTime dia;
  final TimeOfDay inicio;
  final TimeOfDay fim;

  const BlocoEstudo({
    required this.id,
    required this.disciplina,
    required this.cor,
    required this.dia,
    required this.inicio,
    required this.fim,
  });

  double get duracaoHoras {
    final inicioMin = inicio.hour * 60 + inicio.minute;
    final fimMin = fim.hour * 60 + fim.minute;
    return (fimMin - inicioMin) / 60.0;
  }
}
