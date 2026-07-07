import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../data/insights_mock.dart';
import '../models/insights_model.dart';
import '../services/insights_service.dart';
import '../widgets/insights/insight_editorial_summary.dart';
import '../widgets/insights/insight_evolution_view.dart';
import '../widgets/insights/insight_feed_row.dart';
import '../widgets/insights/insight_feed_section.dart';
import '../widgets/insights/insight_feedback_control.dart';
import '../widgets/insights/insight_hero_chart.dart';
import '../widgets/insights/insight_kpi_strip.dart';
import '../widgets/insights/insight_presentation.dart';
import '../widgets/insights/insight_recommendations_section.dart';
import 'criar_sessao_screen.dart';
import 'insight_detail_screen.dart';

enum _InsightsView { insights, evolucao }

class InsightsScreen extends StatefulWidget {
  final List<Insight>? insights;
  final InsightsService? service;

  const InsightsScreen({super.key, this.insights, this.service});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const double _contentMaxWidth = 920;

  List<Insight> _items = const [];
  List<InsightJourneyEvent> _journey = const [];
  InsightsDashboard _dashboard = getInsightsDashboardMock();
  bool _loading = false;
  Object? _error;
  late final InsightsService _service;
  _InsightsView _selectedView = _InsightsView.insights;
  String? _selectedDisciplina;
  String? _selectedEvolutionDisciplina;
  final Map<String, InsightFeedbackState> _feedbackByType = {};

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const InsightsService();
    if (widget.insights != null) {
      _items = widget.insights!;
      _journey = getJornadaMock();
    } else {
      _loading = true;
      _fetch();
    }
  }

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insights != widget.insights && widget.insights != null) {
      setState(() {
        _items = widget.insights!;
        _loading = false;
        _error = null;
      });
    }
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _service.fetchInsights(),
        _service.fetchJourney(),
        _service.fetchDashboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<Insight>;
        _journey = results[1] as List<InsightJourneyEvent>;
        _dashboard = results[2] as InsightsDashboard;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  List<String> get _availableDisciplinas {
    final values = _items
        .map((insight) => insight.disciplina)
        .whereType<String>()
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  String? get _activeInsightsDisciplina {
    final selected = _selectedDisciplina;
    return selected != null && _availableDisciplinas.contains(selected)
        ? selected
        : null;
  }

  String? get _activeEvolutionDisciplina {
    final available = _availableDisciplinas;
    if (available.isEmpty) return null;
    final selected = _selectedEvolutionDisciplina;
    if (selected != null && available.contains(selected)) return selected;
    return available.contains('ES2') ? 'ES2' : available.first;
  }

  bool _isEligible(Insight insight) {
    return insight.confianca != 'insuficiente' &&
        _feedbackByType[insight.tipo]?.status != InsightFeedbackStatus.rejected;
  }

  List<Insight> get _eligibleItems => _items.where(_isEligible).toList();

  Insight? _insightByType(String? type) {
    if (type == null) return null;
    for (final insight in _items) {
      if (insight.tipo == type) return insight;
    }
    return null;
  }

  Insight? get _criticalAnchor {
    final fatigue = _insightByType('desgaste');
    if (fatigue != null && _isEligible(fatigue)) return fatigue;
    for (final insight in _items) {
      if (insight.severidade == 'critico' && _isEligible(insight)) {
        return insight;
      }
    }
    return null;
  }

  Insight? get _heroChartInsight {
    final critical = _criticalAnchor;
    if (critical?.grafico != null) return critical;
    for (final insight in _eligibleItems) {
      if (insight.severidade == 'critico' && insight.grafico != null) {
        return insight;
      }
    }
    for (final types in [
      ['melhor_horario'],
      ['ritmo_disciplina', 'vies_estimativa'],
      ['duracao_ideal'],
    ]) {
      for (final type in types) {
        final insight = _insightByType(type);
        if (insight != null &&
            insight.grafico != null &&
            _isEligible(insight)) {
          return insight;
        }
      }
    }
    return null;
  }

  InsightFeedGroups get _feedGroups {
    return groupInsightsByPriority(
      _eligibleItems,
      disciplina: _activeInsightsDisciplina,
    );
  }

  List<StudyDimension> get _evolutionFeedRows {
    final selected = _activeInsightsDisciplina;
    if (selected == null) return _dashboard.dimensoes;
    return _dashboard.dimensoes.where((dimension) {
      return _insightByType(dimension.insightTipo)?.disciplina == selected;
    }).toList();
  }

  List<InsightRecommendationEntry> get _recommendations {
    return buildInsightRecommendationEntries(
      insights: _eligibleItems,
      experiments: _dashboard.experimentos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _InsightsLoading(),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _InsightsError(onRetry: _reload),
            )
          else ...[
            SliverToBoxAdapter(child: _buildViewSelector()),
            if (_selectedView == _InsightsView.evolucao)
              SliverToBoxAdapter(child: _buildEvolution())
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyInsights(),
              )
            else
              SliverToBoxAdapter(child: _buildInsightsTab()),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: AppColors.subjectTeal,
      foregroundColor: AppColors.textInverted,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        title: Text(
          'Insights',
          style: AppTypography.pageTitle.copyWith(
            color: AppColors.textInverted,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppGradients.reportsHeader),
          child: Stack(
            children: [
              Positioned(
                right: AppSpacing.xxl,
                top: AppSpacing.xxxl,
                child: Icon(
                  LucideIcons.sparkles,
                  size: 112,
                  color: AppColors.textInverted.withValues(alpha: 0.14),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                top: 76,
                right: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que seus hábitos revelam',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textInverted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Padrões observados nas suas sessões para você entender '
                      'melhor como estuda.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textInverted.withValues(alpha: 0.86),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewButton(
                      key: const ValueKey('view-insights'),
                      label: 'Insights',
                      icon: LucideIcons.sparkles,
                      selected: _selectedView == _InsightsView.insights,
                      onPressed: () => setState(
                        () => _selectedView = _InsightsView.insights,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _ViewButton(
                      key: const ValueKey('view-evolucao'),
                      label: 'Evolução',
                      icon: LucideIcons.trendingUp,
                      selected: _selectedView == _InsightsView.evolucao,
                      onPressed: () => setState(
                        () => _selectedView = _InsightsView.evolucao,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    final briefing = buildEditorialBriefing(
      insights: _eligibleItems,
      dashboard: _dashboard,
      anchor: _criticalAnchor,
    );
    final hero = _heroChartInsight;
    final groups = _feedGroups;
    final dimensions = _evolutionFeedRows;
    final recommendations = _recommendations;
    final hasInsufficient = _items.any(
      (insight) =>
          insight.confianca == 'insuficiente' &&
          (_activeInsightsDisciplina == null ||
              insight.disciplina == _activeInsightsDisciplina),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InsightEditorialSummary(briefing: briefing, onOpen: _openDetail),
              if (_dashboard.comparacoes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxl),
                InsightKpiStrip(comparisons: _dashboard.comparacoes),
              ],
              if (hero?.grafico != null) ...[
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'O dado por trás do destaque',
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hero!.titulo,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 280,
                  child: AnnotatedInsightChart(
                    chart: hero.grafico!,
                    color: severityColor(hero.severidade),
                    semanticLabel: 'Gráfico de ${hero.titulo}',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openDetail(hero),
                    child: const Text('Ver gráfico completo'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              _buildSubjectFilters(),
              const SizedBox(height: AppSpacing.xxl),
              InsightFeedSection(
                title: '⚠️ Vale sua atenção',
                rows: groups.attention
                    .map<Widget>(
                      (insight) => InsightFeedRow.fromInsight(
                        insight: insight,
                        onTap: () => _openDetail(insight),
                      ),
                    )
                    .toList(),
              ),
              if (groups.attention.isNotEmpty && groups.discoveries.isNotEmpty)
                const SizedBox(height: AppSpacing.xxxl),
              InsightFeedSection(
                title: '💡 Descobertas',
                rows: groups.discoveries
                    .map<Widget>(
                      (insight) => InsightFeedRow.fromInsight(
                        insight: insight,
                        onTap: () => _openDetail(insight),
                      ),
                    )
                    .toList(),
              ),
              if ((groups.attention.isNotEmpty ||
                      groups.discoveries.isNotEmpty) &&
                  dimensions.isNotEmpty)
                const SizedBox(height: AppSpacing.xxxl),
              InsightFeedSection(
                title: '📈 Evolução',
                rows: dimensions.map<Widget>((dimension) {
                  final insight = _insightByType(dimension.insightTipo);
                  return StudyDimensionFeedRow(
                    dimension: dimension,
                    onTap: insight == null ? null : () => _openDetail(insight),
                  );
                }).toList(),
              ),
              if (hasInsufficient) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Alguns padrões ainda estão se formando; continue '
                  'registrando suas sessões.',
                  key: const ValueKey('insufficient-patterns-note'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxl),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.xxxl),
                InsightRecommendationsSection(
                  entries: recommendations,
                  onOpenInsight: _openDetail,
                  onAction: _handleAction,
                  onOpenExperiment: _openExperiment,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectFilters() {
    final selected = _activeInsightsDisciplina;
    final values = [null, ..._availableDisciplinas];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILTRAR LEITURA POR MATÉRIA',
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final disciplina = values[index];
              final isSelected = disciplina == selected;
              final label = disciplina ?? 'Todas';
              final key = ValueKey('subject-filter-${disciplina ?? 'todas'}');
              return isSelected
                  ? ShadButton(
                      key: key,
                      size: ShadButtonSize.sm,
                      backgroundColor: AppColors.subjectTeal,
                      foregroundColor: AppColors.textInverted,
                      onPressed: () =>
                          setState(() => _selectedDisciplina = disciplina),
                      child: Text(label),
                    )
                  : ShadButton.ghost(
                      key: key,
                      size: ShadButtonSize.sm,
                      foregroundColor: AppColors.textSecondary,
                      onPressed: () =>
                          setState(() => _selectedDisciplina = disciplina),
                      child: Text(label),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvolution() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: InsightEvolutionView(
          dashboard: _dashboard,
          insights: _items,
          journey: _journey,
          disciplinas: _availableDisciplinas,
          selectedDisciplina: _activeEvolutionDisciplina,
          onSelectDisciplina: (value) {
            setState(() => _selectedEvolutionDisciplina = value);
          },
          onOpenInsight: _openDetail,
          onAction: _handleAction,
        ),
      ),
    );
  }

  void _openDetail(Insight insight) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => InsightDetailScreen(
          insight: insight,
          initialFeedback: _feedbackByType[insight.tipo],
          onFeedbackChanged: (feedback) {
            if (!mounted) return;
            _handleFeedbackChanged(insight, feedback);
          },
          onAction: insight.acao == null ? null : () => _handleAction(insight),
        ),
      ),
    );
  }

  void _handleFeedbackChanged(Insight insight, InsightFeedbackState? feedback) {
    if (feedback != null) {
      unawaited(
        _service.submitFeedback(
          insightId: insight.id,
          useful: feedback.status == InsightFeedbackStatus.useful,
          reason: feedback.reason,
        ),
      );
    }
    setState(() {
      if (feedback == null) {
        _feedbackByType.remove(insight.tipo);
      } else {
        _feedbackByType[insight.tipo] = feedback;
      }
    });
  }

  void _openExperiment(InsightExperiment experiment) {
    final insight = _insightByType(experiment.insightTipo);
    if (insight != null) {
      _openDetail(insight);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acompanhamento disponível em breve.')),
    );
  }

  void _handleAction(Insight insight) {
    final action = insight.acao;
    if (action == null) return;
    switch (action.tipo) {
      case 'agendar_sessao':
      case 'reagendar':
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (context) => CriarSessaoScreen(
              disciplinaIdInicial: action.disciplinaId,
              horarioSugerido: action.horarioSugerido,
            ),
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta ação estará disponível em breve.'),
          ),
        );
    }
  }
}

class _ViewButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _ViewButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.subjectTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: selected ? AppColors.textInverted : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyStrong.copyWith(
                  color: selected
                      ? AppColors.textInverted
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.subjectTeal),
    );
  }
}

class _InsightsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _InsightsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: AppColors.danger,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar seus insights',
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            ShadButton(
              key: const ValueKey('insights-retry'),
              backgroundColor: AppColors.subjectTeal,
              foregroundColor: AppColors.textInverted,
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, color: AppColors.info, size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Seus insights começam com algumas sessões',
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Estude algumas sessões para desbloquear seus insights.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
