import 'package:flutter/material.dart';
import '../models/bloco_estudo.dart';

const _disciplinasCores = {
  'Cálculo I': Color(0xFF5C6BC0),
  'Banco de Dados': Color(0xFF009688),
  'Física': Color(0xFFFF7043),
  'Prog. II': Color(0xFFEC407A),
  'IA': Color(0xFF7E57C2),
};

class NovoBlocoDialog extends StatefulWidget {
  final BlocoEstudo? bloco;
  final DateTime diaSelecionado;

  const NovoBlocoDialog({
    super.key,
    this.bloco,
    required this.diaSelecionado,
  });

  @override
  State<NovoBlocoDialog> createState() => _NovoBlocoDialogState();
}

class _NovoBlocoDialogState extends State<NovoBlocoDialog> {
  late String _disciplina;
  late DateTime _dia;
  late TimeOfDay _inicio;
  late TimeOfDay _fim;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _disciplina = widget.bloco?.disciplina ?? _disciplinasCores.keys.first;
    _dia = widget.bloco?.dia ?? widget.diaSelecionado;
    _inicio = widget.bloco?.inicio ?? const TimeOfDay(hour: 8, minute: 0);
    _fim = widget.bloco?.fim ?? const TimeOfDay(hour: 10, minute: 0);
  }

  bool get _isEdit => widget.bloco != null;

  void _salvar() {
    final inicioMin = _inicio.hour * 60 + _inicio.minute;
    final fimMin = _fim.hour * 60 + _fim.minute;
    if (fimMin <= inicioMin) {
      setState(() => _erro = 'O horário de término deve ser após o início.');
      return;
    }

    final bloco = BlocoEstudo(
      id: widget.bloco?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      disciplina: _disciplina,
      cor: _disciplinasCores[_disciplina] ?? const Color(0xFF9E9E9E),
      dia: _dia,
      inicio: _inicio,
      fim: _fim,
    );
    Navigator.of(context).pop(bloco);
  }

  Future<void> _pickTime(bool isInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? _inicio : _fim,
      helpText: isInicio ? 'Início do bloco' : 'Fim do bloco',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _inicio = picked;
      } else {
        _fim = picked;
      }
      _erro = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dia = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diasNomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return AlertDialog(
      title: Text(_isEdit ? 'Editar bloco' : 'Novo bloco de estudo'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disciplina
            Text('Disciplina', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _disciplina,
              decoration: _inputDecoration(),
              items: _disciplinasCores.keys
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _disciplinasCores[d],
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(d),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _disciplina = v!),
            ),
            const SizedBox(height: 14),

            // Dia
            Text('Dia', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${diasNomes[_dia.weekday - 1]}, ${_dia.day.toString().padLeft(2, '0')}/${_dia.month.toString().padLeft(2, '0')}/${_dia.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Horários
            Text('Horário', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _timePicker('Início', _inicio, () => _pickTime(true))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ),
                Expanded(child: _timePicker('Fim', _fim, () => _pickTime(false))),
              ],
            ),

            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          child: Text(_isEdit ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }

  Widget _timePicker(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
}
