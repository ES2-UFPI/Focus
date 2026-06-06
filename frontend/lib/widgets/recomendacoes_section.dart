/// Seção de recomendações inteligentes de estudo.
///
/// Renderiza uma lista de [AgendaRecomendacao] como avisos visuais quando
/// existem eventos acadêmicos próximos sem sessões de estudo suficientes.
/// A seção é omitida se a lista estiver vazia.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';

class RecomendacoesSection extends StatelessWidget {
  final List<AgendaRecomendacao> recomendacoes;

  const RecomendacoesSection({super.key, required this.recomendacoes});

  @override
  Widget build(BuildContext context) {
    if (recomendacoes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AgendaColors.recomendacaoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AgendaColors.recomendacaoBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AgendaColors.recomendacaoIcon,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recomendações de Estudo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AgendaColors.recomendacaoIcon,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: AgendaColors.recomendacaoBorder,
          ),

          // ── Lista de recomendações ────────────────────────────────────
          ...recomendacoes.map((rec) => _RecomendacaoTile(rec: rec)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile individual de recomendação
// ---------------------------------------------------------------------------

class _RecomendacaoTile extends StatelessWidget {
  final AgendaRecomendacao rec;

  const _RecomendacaoTile({required this.rec});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AgendaColors.recomendacaoIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.eventoTitulo,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.recomendacao,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.brown[700],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
