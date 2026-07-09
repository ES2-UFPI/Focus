import 'package:flutter/material.dart';

import '../models/meta_semanal_model.dart';
import '../services/meta_semanais_service.dart';
import '../services/agenda_service.dart';

class MetasSemanaisScreen extends StatefulWidget {
  const MetasSemanaisScreen({super.key});

  @override
  State<MetasSemanaisScreen> createState() => _MetasSemanaisScreenState();
}

class _MetasSemanaisScreenState extends State<MetasSemanaisScreen> {
  final _service = MetasSemanaisService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<MetaSemanal> _metas = [];

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final metas = await _service.listarMetas();

      setState(() {
        _metas = metas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar metas semanais.';
        _loading = false;
      });
    }
  }

  void _alterarHoras(int index, int delta) {
    setState(() {
      final meta = _metas[index];
      final novaCarga = meta.cargaHorariaPlanejada + (delta * 60);

      meta.cargaHorariaPlanejada = novaCarga < 0 ? 0 : novaCarga;
    });
  }

  Future<void> _salvarMetas() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      for (final meta in _metas) {
        if (meta.cargaHorariaPlanejada > 0) {
          await _service.salvarMeta(meta);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metas semanais salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _carregarMetas();
    } on AgendaServiceException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Erro inesperado ao salvar metas.';
        _saving = false;
      });
    }
  }

  int get _totalMinutos {
    return _metas.fold(
      0,
      (total, meta) => total + meta.cargaHorariaPlanejada,
    );
  }

  String _formatarMinutos(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;

    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Metas Semanais'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarMetas,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildResumo(),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildErro(),
                  ],

                  const SizedBox(height: 16),

                  if (_metas.isEmpty)
                    const Center(
                      child: Text(
                        'Nenhuma disciplina encontrada.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...List.generate(
                      _metas.length,
                      (index) => _buildMetaCard(index),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _salvarMetas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Salvar Metas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResumo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planejamento da Semana',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meta total: ${_formatarMinutos(_totalMinutos)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          Text(
            'Disciplinas planejadas: ${_metas.where((m) => m.cargaHorariaPlanejada > 0).length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }

  Widget _buildMetaCard(int index) {
    final meta = _metas[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E7ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              meta.disciplinaNome.isNotEmpty
                  ? meta.disciplinaNome[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.disciplinaNome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meta semanal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _alterarHoras(index, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),

          Text(
            '${meta.horas}h',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          IconButton(
            onPressed: () => _alterarHoras(index, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}