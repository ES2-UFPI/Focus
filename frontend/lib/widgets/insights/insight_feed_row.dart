import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

class InsightFeedRow extends StatelessWidget {
  final String id;
  final Color indicatorColor;
  final IconData icon;
  final _InsightFeedPresentation presentation;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const InsightFeedRow._({
    super.key,
    required this.id,
    required this.indicatorColor,
    required this.icon,
    required this.presentation,
    this.onTap,
    this.onAcknowledge,
  });

  factory InsightFeedRow.fromInsight({
    Key? key,
    required Insight insight,
    required VoidCallback onTap,
    VoidCallback? onAcknowledge,
  }) {
    return InsightFeedRow._(
      key: key,
      id: insight.tipo,
      indicatorColor: severityColor(insight.severidade),
      icon: insightIcon(insight.tipo),
      presentation: _InsightFeedPresentation.fromInsight(insight),
      onTap: onTap,
      onAcknowledge: onAcknowledge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppRadii.md);

    return Semantics(
      button: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: cardRadius,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          child: InkWell(
            key: ValueKey('feed-row-$id'),
            onTap: onTap,
            borderRadius: cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: indicatorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(
                          icon,
                          size: AppSizes.iconMd,
                          color: indicatorColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InsightTag(tag: presentation.tag),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              presentation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              presentation.context,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: AppSizes.iconSm,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InsightStoryGrid(
                    sections: presentation.sections,
                    accentColor: indicatorColor,
                  ),
                  if (presentation.showAcknowledge) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        key: ValueKey('feed-ack-$id'),
                        onPressed: onAcknowledge,
                        icon: const Icon(
                          LucideIcons.check,
                          size: AppSizes.iconSm,
                        ),
                        label: const Text('Ciente'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightFeedPresentation {
  final String title;
  final String context;
  final _InsightTagData tag;
  final List<_InsightStorySection> sections;
  final bool showAcknowledge;

  const _InsightFeedPresentation({
    required this.title,
    required this.context,
    required this.tag,
    required this.sections,
    this.showAcknowledge = false,
  });

  factory _InsightFeedPresentation.fromInsight(Insight insight) {
    final isProblem =
        insight.severidade == 'critico' || insight.severidade == 'atencao';
    final context = _contextForInsight(insight);

    if (!isProblem) {
      return _InsightFeedPresentation(
        title: insight.titulo,
        context: context,
        tag: _InsightTagData.discovery(),
        sections: _discoverySections(insight),
      );
    }

    return _InsightFeedPresentation(
      title: insight.titulo,
      context: context,
      tag: _InsightTagData.problem(hasAction: insight.acao != null),
      sections: _problemSections(insight),
      showAcknowledge: insight.acao == null,
    );
  }

  static String _contextForInsight(Insight insight) {
    if (insight.tipo == 'desgaste' || insight.tipo == 'sono_x_rendimento') {
      return 'Sono e rotina';
    }
    if (insight.tipo == 'tela_antes_sessao') {
      return 'Uso do celular';
    }
    return insight.disciplina ?? categoryLabel(insight.categoria);
  }

  static List<_InsightStorySection> _problemSections(Insight insight) {
    switch (insight.tipo) {
      case 'desgaste':
        return const [
          _InsightStorySection(
            label: 'Padrão ruim observado',
            text:
                'Estudar depois das 20h aparece junto com sono curto e queda de produtividade.',
          ),
          _InsightStorySection(
            label: 'Recomendação',
            text: 'Deixe tarefas exigentes para a manhã e use a noite só para revisão leve.',
          ),
          _InsightStorySection(
            label: 'Resultado esperado',
            text: 'Menos cansaço acumulado e rendimento mais estável.',
          ),
        ];
      case 'duracao_ideal':
        return const [
          _InsightStorySection(
            label: 'Padrão ruim observado',
            text: 'Revisões de Banco de Dados passam a perder foco após blocos longos.',
          ),
          _InsightStorySection(
            label: 'Recomendação',
            text: 'Use blocos de até 50 min e faça uma pausa curta antes de continuar.',
          ),
          _InsightStorySection(
            label: 'Resultado esperado',
            text: 'Mais energia no fim do bloco e menos queda de foco.',
          ),
        ];
      case 'taxa_furo':
        return const [
          _InsightStorySection(
            label: 'Padrão ruim observado',
            text: 'Sexta à noite concentra cancelamentos de Banco de Dados.',
          ),
          _InsightStorySection(
            label: 'Recomendação',
            text: 'Reagende essa sessão para manhã ou início da tarde.',
          ),
          _InsightStorySection(
            label: 'Resultado esperado',
            text: 'Menos cancelamentos e uma semana de estudo mais previsível.',
          ),
        ];
      default:
        return [
          _InsightStorySection(
            label: 'Padrão ruim observado',
            text: insight.descricao,
          ),
          const _InsightStorySection(
            label: 'Recomendação',
            text: 'Ajuste a próxima sessão e acompanhe se o padrão diminui.',
          ),
          const _InsightStorySection(
            label: 'Resultado esperado',
            text: 'Um estudo mais previsível e fácil de manter.',
          ),
        ];
    }
  }

  static List<_InsightStorySection> _discoverySections(Insight insight) {
    switch (insight.tipo) {
      case 'melhor_horario':
        return const [
          _InsightStorySection(
            label: 'Comportamento mapeado',
            text: 'Estruturas de Dados rende melhor no período da manhã.',
          ),
          _InsightStorySection(
            label: 'Como manter',
            text: 'Reserve esse horário para exercícios mais difíceis.',
          ),
          _InsightStorySection(
            label: 'Próximo uso',
            text: 'Teste aplicar essa janela em Banco de Dados.',
          ),
        ];
      case 'tarefas_no_prazo':
        return const [
          _InsightStorySection(
            label: 'Comportamento mapeado',
            text: 'A maior parte das entregas recentes ficou dentro do prazo.',
          ),
          _InsightStorySection(
            label: 'Como manter',
            text: 'Continue separando pendências antes da semana fechar.',
          ),
          _InsightStorySection(
            label: 'Próximo uso',
            text: 'Use o mesmo ritual no trabalho prático de Banco de Dados.',
          ),
        ];
      case 'efeito_acao':
        return const [
          _InsightStorySection(
            label: 'Comportamento mapeado',
            text: 'Antecipar sessões já melhorou o rendimento observado.',
          ),
          _InsightStorySection(
            label: 'Como manter',
            text: 'Mantenha dois blocos antes do estágio nesta semana.',
          ),
          _InsightStorySection(
            label: 'Próximo uso',
            text: 'Repita o ajuste em conteúdos que exigem mais concentração.',
          ),
        ];
      default:
        return [
          _InsightStorySection(
            label: 'Comportamento mapeado',
            text: insight.descricao,
          ),
          const _InsightStorySection(
            label: 'Como manter',
            text: 'Continue registrando sessões para confirmar esse padrão.',
          ),
          const _InsightStorySection(
            label: 'Próximo uso',
            text: 'Observe se o mesmo comportamento aparece em outras matérias.',
          ),
        ];
    }
  }
}

class _InsightTagData {
  final String label;
  final Color color;

  const _InsightTagData({required this.label, required this.color});

  factory _InsightTagData.problem({required bool hasAction}) {
    if (hasAction) {
      return const _InsightTagData(
        label: 'Ação recomendada',
        color: Color(0xFF1E3A8A),
      );
    }
    return const _InsightTagData(label: 'Informativo', color: AppColors.info);
  }

  factory _InsightTagData.discovery() {
    return const _InsightTagData(
      label: 'Informativo',
      color: AppColors.info,
    );
  }
}

class _InsightTag extends StatelessWidget {
  final _InsightTagData tag;

  const _InsightTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          tag.label,
          style: AppTypography.caption.copyWith(
            color: tag.color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InsightStorySection {
  final String label;
  final String text;

  const _InsightStorySection({required this.label, required this.text});
}

class _InsightStoryGrid extends StatelessWidget {
  final List<_InsightStorySection> sections;
  final Color accentColor;

  const _InsightStoryGrid({required this.sections, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;
        final itemWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: sections.map((section) {
            return SizedBox(
              width: itemWidth,
              child: _InsightStoryBlock(
                section: section,
                accentColor: accentColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InsightStoryBlock extends StatelessWidget {
  final _InsightStorySection section;
  final Color accentColor;

  const _InsightStoryBlock({
    required this.section,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              section.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
