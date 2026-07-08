import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/insights_model.dart';
import '../services/insights_service.dart';
import '../widgets/insights/insight_evolution_view.dart';
import '../widgets/insights/insight_feed_row.dart';
import '../widgets/insights/insight_feed_section.dart';
import '../widgets/insights/insight_feedback_control.dart';
import 'criar_sessao_screen.dart';
import 'insight_detail_screen.dart';

enum _InsightsView { insights, evolucao }

class InsightsScreen extends StatefulWidget {
  final InsightsService? service;

  const InsightsScreen({super.key, this.service});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const double _contentMaxWidth = 920;

  List<Insight> _items = const [];
  List<InsightJourneyEvent> _journey = const [];
  bool _loading = false;
  Object? _error;
  late final InsightsService _service;
  _InsightsView _selectedView = _InsightsView.insights;
  String? _selectedDisciplina;
  final Map<String, InsightFeedbackState> _feedbackByType = {};

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const InsightsService();
    _loading = true;
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _service.fetchInsights(),
        _service.fetchJourney(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<Insight>;
        _journey = results[1] as List<InsightJourneyEvent>;
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

  bool _isEligible(Insight insight) {
    return insight.confianca != 'insuficiente' &&
        _feedbackByType[insight.tipo]?.status != InsightFeedbackStatus.rejected;
  }

  List<Insight> get _eligibleItems => _items.where(_isEligible).toList();

  InsightFeedGroups get _feedGroups {
    return groupInsightsByPriority(
      _eligibleItems,
      disciplina: _activeInsightsDisciplina,
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
          child: DecoratedBox(
            decoration: AppDecorations.card(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Material(
              color: Colors.transparent,
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
      ),
    );
  }

  Widget _buildInsightsTab() {
    final groups = _feedGroups;
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
              _buildSubjectFilters(),
              const SizedBox(height: AppSpacing.xxl),
              InsightFeedSection(
                title: 'Pontos para melhorar',
                description:
                    'Padrões ruins observados nos seus registros, com recomendação e resultado esperado.',
                rows: groups.attention
                    .map<Widget>(
                      (insight) => InsightFeedRow.fromInsight(
                        insight: insight,
                        onTap: () => _openDetail(insight),
                        onAcknowledge: () => _handleAcknowledged(insight),
                      ),
                    )
                    .toList(),
              ),
              if (groups.attention.isNotEmpty && groups.discoveries.isNotEmpty)
                const SizedBox(height: AppSpacing.xxxl),
              InsightFeedSection(
                title: 'Descobertas',
                description:
                    'Comportamentos bons que já aparecem nos dados e vale manter.',
                rows: groups.discoveries
                    .map<Widget>(
                      (insight) => InsightFeedRow.fromInsight(
                        insight: insight,
                        onTap: () => _openDetail(insight),
                        onAcknowledge: () => _handleAcknowledged(insight),
                      ),
                    )
                    .toList(),
              ),
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
          insights: _items,
          journey: _journey,
          onOpenInsight: _openDetail,
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

  void _handleAcknowledged(Insight insight) {
    _handleFeedbackChanged(
      insight,
      const InsightFeedbackState(status: InsightFeedbackStatus.useful),
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
