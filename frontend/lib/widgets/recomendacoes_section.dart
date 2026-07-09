/// Seção de recomendações inteligentes de estudo.
///
/// Renderiza uma lista de [AgendaRecomendacao] como cards informativos elegantes,
/// aplicando ícones e cores contextuais de acordo com o teor da recomendação.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.warningStrong,
              ),
              const SizedBox(width: 8),
              Text(
                'Sugestões de Estudo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recomendacoes.map((rec) => _RecomendacaoCard(rec: rec)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de Recomendação Contextualizado
// ---------------------------------------------------------------------------

class _RecomendacaoCard extends StatelessWidget {
  final AgendaRecomendacao rec;

  const _RecomendacaoCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final text = rec.recomendacao.toLowerCase();

    // Determina o ícone, a cor de destaque e a cor de fundo com base no conteúdo
    IconData iconData = Icons.lightbulb;
    Color color = AppColors.warningStrong;
    Color bgColor = AppColors.recommendationBackground;
    String prefixEmoji = '💡';

    if (text.contains('nenhuma sessão') || text.contains('sem sessão')) {
      iconData = Icons.error_outline_rounded;
      color = AppColors.danger;
      bgColor = AppColors.danger.withValues(alpha: 0.08);
      prefixEmoji = '🚨';
    } else if (text.contains('próxima') || text.contains('dias') || text.contains('prazo')) {
      iconData = Icons.warning_amber_rounded;
      color = AppColors.warningStrong;
      bgColor = AppColors.warningStrong.withValues(alpha: 0.10);
      prefixEmoji = '⚠️';
    } else if (text.contains('agendar') || text.contains('mais sessões') || text.contains('considere')) {
      iconData = Icons.menu_book_rounded;
      color = AppColors.brandPrimary;
      bgColor = AppColors.brandPrimary.withValues(alpha: 0.08);
      prefixEmoji = '📚';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(bgColor, AppColors.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prefixEmoji ${rec.eventoTitulo}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.recomendacao,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 13,
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
