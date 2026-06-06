/// Card unificado para exibir um item de agenda.
///
/// Renderiza variações visuais conforme [AgendaItem.tipo]:
/// - `EVENTO_ACADEMICO` → barra de urgência, badge de tipo, dias restantes.
/// - `SESSAO_ESTUDO`    → barra de status, horário início/fim, duração.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';

class AgendaItemCard extends StatelessWidget {
  final AgendaItem item;

  const AgendaItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isConcluido =
        (item.isEvento && item.concluido == true) ||
        (item.isSessao && item.status == 'CONCLUIDO');

    return Opacity(
      opacity: isConcluido ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AgendaColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra lateral colorida ──────────────────────────────
                Container(
                  width: 5,
                  color: _barColor(),
                ),
                // ── Conteúdo ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: item.isEvento
                        ? _buildEvento(context)
                        : _buildSessao(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Variação — EVENTO_ACADEMICO
  // =========================================================================

  Widget _buildEvento(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: badge de tipo + dias restantes
        Row(
          children: [
            _badge(
              label: AgendaLabels.tipoEvento(item.tipoEvento),
              color: _barColor(),
            ),
            const Spacer(),
            if (item.diasRestantes != null)
              Text(
                AgendaLabels.diasRestantes(item.diasRestantes),
                style: textTheme.bodySmall?.copyWith(
                  color: _barColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Título
        Text(
          item.titulo,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Disciplina
        if (item.disciplinaNome.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.disciplinaNome,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],

        // Descrição
        if (item.descricao != null && item.descricao!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.descricao!,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Indicador de concluído
        if (item.concluido == true) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Concluído',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // Variação — SESSAO_ESTUDO
  // =========================================================================

  Widget _buildSessao(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: badge de status + horário
        Row(
          children: [
            _badge(
              label: AgendaLabels.statusSessao(item.status),
              color: _barColor(),
            ),
            const Spacer(),
            if (item.inicio != null && item.fim != null)
              Text(
                '${_formatTime(item.inicio!)} – ${_formatTime(item.fim!)}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Título
        Text(
          item.titulo,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Disciplina
        if (item.disciplinaNome.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.disciplinaNome,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],

        // Descrição
        if (item.descricao != null && item.descricao!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.descricao!,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Duração realizada (se concluído)
        if (item.status == 'CONCLUIDO' && item.duracaoRealizada != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Foco: ${item.duracaoRealizada} min',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // Helpers privados
  // =========================================================================

  Color _barColor() {
    if (item.isEvento) return AgendaColors.corPorUrgencia(item.urgencia);
    return AgendaColors.corPorStatus(item.status);
  }

  /// Badge compacta colorida com texto.
  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Formata um [DateTime] como `HH:mm`.
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
