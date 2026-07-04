import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../data/insight_disciplina_colors.dart';
import '../data/insights_mock.dart';
import '../models/insights_model.dart';
import '../services/insights_service.dart';
import '../widgets/insight_card.dart';
import 'criar_sessao_screen.dart';
import 'insight_detail_screen.dart';

enum _InsightsView { insights, evolucao }

class InsightsScreen extends StatefulWidget {
  /// Permite exercitar os estados da tela sem alterar a fonte de produção.
  final List<Insight>? insights;

  /// Fonte de dados. Padrão: [InsightsService] (serve o mock hoje; a fase de
  /// dados troca só a implementação do serviço, sem mexer nesta tela).
  final InsightsService? service;

  /// Permite iniciar a biblioteca expandida em testes e estados demonstrativos.
  final bool initiallyShowPatternLibrary;

  const InsightsScreen({
    super.key,
    this.insights,
    this.service,
    this.initiallyShowPatternLibrary = false,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const double _gridBreakpoint = 680;
  static const double _contentMaxWidth = 920;
  static const List<String> _categoryOrder = [
    'tempo',
    'foco',
    'planejamento',
    'rotina',
    'saude',
    'metodo',
  ];

  List<Insight> _items = const [];
  List<InsightJourneyEvent> _journey = const [];
  InsightsDashboard _dashboard = getInsightsDashboardMock();
  bool _loading = false;
  Object? _error;
  late final InsightsService _service;
  _InsightsView _selectedView = _InsightsView.insights;
  String? _selectedCategory;
  String? _selectedDisciplina;
  String? _selectedSeverity;
  bool _attentionOnly = false;
  bool _showPatternLibrary = false;
  String? _reasonPickerFor;
  String? _selectedEvolutionDisciplina;

  // Fase de dados: este mapa local vira
  // POST /api/insights/{id}/feedback (modelo InsightFeedback). A resposta
  // alimentará personalização determinística: reduzir a prioridade de itens
  // rejeitados, ajustar limiares e reavaliar o insight após um período —
  // sem "IA que aprende".
  final Map<String, InsightFeedbackState> _feedbackByType = {};

  @override
  void initState() {
    super.initState();
    _showPatternLibrary = widget.initiallyShowPatternLibrary;
    _service = widget.service ?? const InsightsService();
    if (widget.insights != null) {
      // Injeção síncrona (testes/estados): sem carregamento assíncrono.
      _items = widget.insights!;
      _journey = getJornadaMock();
      _dashboard = getInsightsDashboardMock();
    } else {
      _loading = true;
      _fetch();
    }
  }

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insights != widget.insights && widget.insights != null) {
      _items = widget.insights!;
      _loading = false;
      _error = null;
    }
  }

  /// Reexecuta o carregamento (usado pelo botão "tentar novamente").
  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  /// Ponto único de busca de dados. Hoje resolve o serviço (mock); a fase de
  /// dados apenas troca a implementação do serviço.
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

  List<String> get _availableCategories => _categoryOrder
      .where(
        (category) => _items.any((insight) => insight.categoria == category),
      )
      .toList();

  List<String> get _availableDisciplinas {
    final disciplinas = _items
        .map((insight) => insight.disciplina)
        .whereType<String>()
        .toSet()
        .toList();
    disciplinas.sort();
    return disciplinas;
  }

  List<Insight> get _summaryItems {
    return _items
        .where(
          (insight) =>
              (_selectedCategory == null ||
                  insight.categoria == _selectedCategory) &&
              (_selectedDisciplina == null ||
                  insight.disciplina == _selectedDisciplina),
        )
        .toList();
  }

  List<Insight> get _filteredItems {
    return _summaryItems
        .where(
          (insight) =>
              (_selectedSeverity == null ||
                  insight.severidade == _selectedSeverity) &&
              (!_attentionOnly ||
                  insight.severidade == 'atencao' ||
                  insight.severidade == 'critico'),
        )
        .toList();
  }

  Insight? _insightByType(String type) {
    for (final insight in _items) {
      if (insight.tipo == type) return insight;
    }
    return null;
  }

  bool _isEligibleForPriority(Insight insight) {
    return insight.confianca != 'insuficiente' &&
        _feedbackByType[insight.tipo]?.status != InsightFeedbackStatus.rejected;
  }

  List<_WeeklyPlanEntry> get _weeklyPlan {
    final entries = <_WeeklyPlanEntry>[];
    final keep = _insightByType('melhor_horario');
    final adjust =
        _insightByType('ritmo_disciplina') ?? _insightByType('vies_estimativa');
    final test = _insightByType('duracao_ideal');

    if (keep != null && _isEligibleForPriority(keep)) {
      entries.add(
        _WeeklyPlanEntry(
          label: 'CONTINUE',
          supportingText: 'Esse padrão já aparece em ${keep.amostra} sessões.',
          icon: LucideIcons.circleCheck,
          color: AppColors.success,
          insight: keep,
        ),
      );
    }
    if (adjust != null && _isEligibleForPriority(adjust)) {
      entries.add(
        _WeeklyPlanEntry(
          label: 'AJUSTE',
          supportingText: 'Uma mudança pequena pode reduzir o risco.',
          icon: LucideIcons.slidersHorizontal,
          color: AppColors.warningStrong,
          insight: adjust,
        ),
      );
    }
    if (test != null && _isEligibleForPriority(test)) {
      entries.add(
        _WeeklyPlanEntry(
          label: 'TESTE',
          supportingText: 'Compare os próximos blocos antes de concluir.',
          icon: LucideIcons.flaskConical,
          color: AppColors.info,
          insight: test,
        ),
      );
    }
    return entries;
  }

  Insight? get _criticalAlert {
    final fatigue = _insightByType('desgaste');
    if (fatigue != null && _isEligibleForPriority(fatigue)) return fatigue;
    for (final insight in _items) {
      if (insight.severidade == 'critico' && _isEligibleForPriority(insight)) {
        return insight;
      }
    }
    return null;
  }

  String? get _activeEvolutionDisciplina {
    final available = _availableDisciplinas;
    if (available.isEmpty) return null;
    if (_selectedEvolutionDisciplina != null &&
        available.contains(_selectedEvolutionDisciplina)) {
      return _selectedEvolutionDisciplina;
    }
    return available.contains('ES2') ? 'ES2' : available.first;
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
            ..._buildLoadedSlivers(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLoadedSlivers() {
    final items = _items;
    final filteredItems = _filteredItems;

    if (_selectedView == _InsightsView.evolucao) {
      return [SliverToBoxAdapter(child: _buildEvolution())];
    }
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: _EmptyInsights()),
      ];
    }
    return [
      SliverToBoxAdapter(child: _buildWeeklyOverview()),
      if (_criticalAlert != null)
        SliverToBoxAdapter(child: _buildCriticalAlert(_criticalAlert!)),
      if (_weeklyPlan.isNotEmpty) SliverToBoxAdapter(child: _buildWeeklyPlan()),
      if (_dashboard.dimensoes.isNotEmpty)
        SliverToBoxAdapter(child: _buildStudyPanorama()),
      SliverToBoxAdapter(child: _buildPatternLibraryToggle(items.length)),
      if (_showPatternLibrary) ...[
        SliverToBoxAdapter(child: _buildIntroduction(items)),
        SliverToBoxAdapter(child: _buildCategoryFilters()),
        SliverToBoxAdapter(child: _buildDisciplinaFilters()),
        SliverToBoxAdapter(child: _buildSeveritySummary()),
        if (filteredItems.isEmpty)
          SliverToBoxAdapter(
            child: _CategoryEmpty(
              category: _selectedCategory == null
                  ? null
                  : _categoryLabel(_selectedCategory),
              disciplina: _selectedDisciplina,
            ),
          )
        else
          SliverToBoxAdapter(child: _buildInsightGrid(filteredItems)),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
    ];
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
                  mainAxisSize: MainAxisSize.min,
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
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ViewButton(
                    key: const ValueKey('view-insights'),
                    label: 'Insights',
                    icon: LucideIcons.sparkles,
                    selected: _selectedView == _InsightsView.insights,
                    onPressed: () =>
                        setState(() => _selectedView = _InsightsView.insights),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ViewButton(
                    key: const ValueKey('view-evolucao'),
                    label: 'Evolução',
                    icon: LucideIcons.trendingUp,
                    selected: _selectedView == _InsightsView.evolucao,
                    onPressed: () =>
                        setState(() => _selectedView = _InsightsView.evolucao),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _WeeklyOverviewHeader(dashboard: _dashboard),
        ),
      ),
    );
  }

  Widget _buildCriticalAlert(Insight insight) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _CriticalInsightAlert(
            insight: insight,
            onTap: () => _openDetail(insight),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPlan() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: _WeeklyPlanSection(
          entries: _weeklyPlan,
          onOpen: _openDetail,
          onAction: _handleAction,
        ),
      ),
    );
  }

  Widget _buildStudyPanorama() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: _StudyPanorama(
          dimensions: _dashboard.dimensoes,
          onOpen: (dimension) {
            final type = dimension.insightTipo;
            if (type == null) return;
            final insight = _insightByType(type);
            if (insight != null) _openDetail(insight);
          },
        ),
      ),
    );
  }

  Widget _buildPatternLibraryToggle(int count) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _PatternLibraryToggle(
            count: count,
            expanded: _showPatternLibrary,
            onPressed: () {
              setState(() => _showPatternLibrary = !_showPatternLibrary);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSeveritySummary() {
    final counts = <String, int>{
      for (final severity in ['positivo', 'atencao', 'critico', 'info'])
        severity: _summaryItems
            .where((insight) => insight.severidade == severity)
            .length,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: _SeveritySummary(
          counts: counts,
          selectedSeverity: _selectedSeverity,
          attentionOnly: _attentionOnly,
          onSeverityPressed: _toggleSeverity,
          onAttentionPressed: _toggleAttentionOnly,
        ),
      ),
    );
  }

  Widget _buildEvolution() {
    final activeSubject = _activeEvolutionDisciplina;
    final subjectInsights = activeSubject == null
        ? const <Insight>[]
        : _items
              .where((insight) => insight.disciplina == activeSubject)
              .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EvolutionOverview(
              dashboard: _dashboard,
              onOpenComparison: (comparison) {
                final type = comparison.insightTipo;
                if (type == null) return;
                final insight = _insightByType(type);
                if (insight != null) _openDetail(insight);
              },
            ),
            if (_dashboard.experimentos.isNotEmpty)
              _ExperimentsSection(
                experiments: _dashboard.experimentos,
                onOpen: (experiment) {
                  final type = experiment.insightTipo;
                  if (type == null) return;
                  final insight = _insightByType(type);
                  if (insight != null) _openDetail(insight);
                },
              ),
            if (activeSubject != null)
              _SubjectJourneySection(
                disciplinas: _availableDisciplinas,
                selected: activeSubject,
                insights: subjectInsights,
                onSelected: (value) {
                  setState(() => _selectedEvolutionDisciplina = value);
                },
                onOpen: _openDetail,
                onAction: _handleAction,
              ),
            _EvolutionTimeline(
              events: _journey,
              insightTitle: (type) {
                for (final insight in _items) {
                  if (insight.tipo == type) return insight.titulo;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction(List<Insight> items) {
    final detected = items
        .where((insight) => insight.confianca != 'insuficiente')
        .length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca de padrões',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Explore todas as tendências dos seus registros. Elas não '
                      'representam relações comprovadas de causa e efeito.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.subjectTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  '$detected ${detected == 1 ? 'padrão' : 'padrões'}',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.subjectTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [null, ..._availableCategories];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: SizedBox(
          height: 48,
          child: ListView.separated(
            padding: AppSpacing.listHorizontal,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category == _selectedCategory;
              final label = category == null
                  ? 'Todos'
                  : _categoryLabel(category);

              return Semantics(
                selected: selected,
                button: true,
                child: selected
                    ? ShadButton(
                        key: ValueKey('filter-${category ?? 'todos'}'),
                        size: ShadButtonSize.sm,
                        height: 34,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        backgroundColor: AppColors.subjectTeal,
                        hoverBackgroundColor: AppColors.subjectTeal,
                        foregroundColor: AppColors.textInverted,
                        onPressed: () =>
                            setState(() => _selectedCategory = category),
                        child: Text(
                          label,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textInverted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ShadButton.outline(
                        key: ValueKey('filter-${category ?? 'todos'}'),
                        size: ShadButtonSize.sm,
                        height: 34,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        backgroundColor: AppColors.surface,
                        hoverBackgroundColor: AppColors.surfaceMuted,
                        foregroundColor: AppColors.textSecondary,
                        onPressed: () =>
                            setState(() => _selectedCategory = category),
                        child: Text(
                          label,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplinaFilters() {
    final disciplinas = [null, ..._availableDisciplinas];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'FILTRAR POR MATÉRIA',
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: AppSpacing.listHorizontal,
                scrollDirection: Axis.horizontal,
                itemCount: disciplinas.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final disciplina = disciplinas[index];
                  final selected = disciplina == _selectedDisciplina;
                  final label = disciplina ?? 'Todas as matérias';
                  final color = _disciplinaColor(disciplina);

                  final child = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (disciplina != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.textInverted : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          color: selected
                              ? AppColors.textInverted
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  );

                  return Semantics(
                    selected: selected,
                    button: true,
                    child: selected
                        ? ShadButton(
                            key: ValueKey(
                              'subject-filter-${disciplina ?? 'todas'}',
                            ),
                            size: ShadButtonSize.sm,
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            backgroundColor: AppColors.subjectTeal,
                            hoverBackgroundColor: AppColors.subjectTeal,
                            foregroundColor: AppColors.textInverted,
                            onPressed: () => setState(
                              () => _selectedDisciplina = disciplina,
                            ),
                            child: child,
                          )
                        : ShadButton.outline(
                            key: ValueKey(
                              'subject-filter-${disciplina ?? 'todas'}',
                            ),
                            size: ShadButtonSize.sm,
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            backgroundColor: AppColors.surface,
                            hoverBackgroundColor: AppColors.surfaceMuted,
                            foregroundColor: AppColors.textSecondary,
                            onPressed: () => setState(
                              () => _selectedDisciplina = disciplina,
                            ),
                            child: child,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightGrid(List<Insight> items) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= _gridBreakpoint ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final insight in items)
                    SizedBox(
                      key: ValueKey('grid-${insight.tipo}'),
                      width: cardWidth,
                      child: InsightCard(
                        key: ValueKey(insight.tipo),
                        insight: insight,
                        disciplinaColorHex: getInsightDisciplinaColorHex(
                          insight.disciplina,
                        ),
                        onTap: () => _openDetail(insight),
                        onAction: insight.acao == null
                            ? null
                            : () => _handleAction(insight),
                        feedback: _feedbackByType[insight.tipo],
                        showFeedbackReasons: _reasonPickerFor == insight.tipo,
                        onUseful: () => _markUseful(insight),
                        onNotUseful: () => _openReasonPicker(insight),
                        onSelectFeedbackReason: (reason) =>
                            _rejectInsight(insight, reason),
                        onClearFeedback: () => _clearFeedback(insight),
                      ),
                    ),
                ],
              );
            },
          ),
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
            setState(() {
              if (feedback == null) {
                _feedbackByType.remove(insight.tipo);
              } else {
                _feedbackByType[insight.tipo] = feedback;
              }
            });
          },
          onAction: insight.acao == null ? null : () => _handleAction(insight),
        ),
      ),
    );
  }

  void _toggleSeverity(String severity) {
    setState(() {
      _selectedSeverity = _selectedSeverity == severity ? null : severity;
      _attentionOnly = false;
    });
  }

  void _toggleAttentionOnly() {
    setState(() {
      _attentionOnly = !_attentionOnly;
      _selectedSeverity = null;
    });
  }

  void _markUseful(Insight insight) {
    unawaited(_service.submitFeedback(insightId: insight.id, useful: true));
    setState(() {
      _feedbackByType[insight.tipo] = const InsightFeedbackState(
        status: InsightFeedbackStatus.useful,
      );
      _reasonPickerFor = null;
    });
  }

  void _openReasonPicker(Insight insight) {
    setState(() {
      _reasonPickerFor = _reasonPickerFor == insight.tipo ? null : insight.tipo;
    });
  }

  void _rejectInsight(Insight insight, String reason) {
    unawaited(
      _service.submitFeedback(
        insightId: insight.id,
        useful: false,
        reason: reason,
      ),
    );
    setState(() {
      _feedbackByType[insight.tipo] = InsightFeedbackState(
        status: InsightFeedbackStatus.rejected,
        reason: reason,
      );
      _reasonPickerFor = null;
    });
  }

  void _clearFeedback(Insight insight) {
    setState(() {
      _feedbackByType.remove(insight.tipo);
      _reasonPickerFor = null;
    });
  }

  Color _disciplinaColor(String? disciplina) {
    final hex = getInsightDisciplinaColorHex(disciplina)?.replaceFirst('#', '');
    if (hex == null || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return AppColors.brandPrimary;
    }
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _handleAction(Insight insight) {
    final acao = insight.acao;
    if (acao == null) return;

    switch (acao.tipo) {
      case 'agendar_sessao':
      case 'reagendar':
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (context) => CriarSessaoScreen(
              disciplinaIdInicial: acao.disciplinaId,
              horarioSugerido: acao.horarioSugerido,
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

  String _categoryLabel(String? category) {
    switch (category) {
      case 'tempo':
        return 'Tempo';
      case 'foco':
        return 'Foco';
      case 'planejamento':
        return 'Planejamento';
      case 'rotina':
        return 'Rotina';
      case 'saude':
        return 'Saúde';
      case 'metodo':
        return 'Método';
      default:
        return 'esta categoria';
    }
  }
}

class _WeeklyPlanEntry {
  final String label;
  final String supportingText;
  final IconData icon;
  final Color color;
  final Insight insight;

  const _WeeklyPlanEntry({
    required this.label,
    required this.supportingText,
    required this.icon,
    required this.color,
    required this.insight,
  });
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.subjectTeal,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

class _WeeklyOverviewHeader extends StatelessWidget {
  final InsightsDashboard dashboard;

  const _WeeklyOverviewHeader({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.subjectTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  'ESTA SEMANA',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.subjectTeal,
                  ),
                ),
              ),
              Text(
                dashboard.periodo,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Seu estudo, traduzido em decisões',
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Veja primeiro o que manter, ajustar e testar. Os números completos '
            'continuam disponíveis na biblioteca de padrões.',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _InlineMetadata(
                icon: LucideIcons.database,
                label: dashboard.atualizadoEm,
              ),
              const _InlineMetadata(
                icon: LucideIcons.telescope,
                label: 'Leitura observacional',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMetadata extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineMetadata({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CriticalInsightAlert extends StatelessWidget {
  final Insight insight;
  final VoidCallback onTap;

  const _CriticalInsightAlert({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: const ValueKey('critical-insight-alert'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  LucideIcons.triangleAlert,
                  color: AppColors.danger,
                  size: AppSizes.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATENÇÃO AGORA',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      insight.titulo,
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      insight.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                LucideIcons.arrowRight,
                size: AppSizes.iconMd,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyPlanSection extends StatelessWidget {
  final List<_WeeklyPlanEntry> entries;
  final ValueChanged<Insight> onOpen;
  final ValueChanged<Insight> onAction;

  const _WeeklyPlanSection({
    required this.entries,
    required this.onOpen,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'PLANO DA SEMANA',
            title: 'Três decisões, sem sobrecarga',
            description:
                'Uma prática para manter, uma para ajustar e uma hipótese para testar.',
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780
                  ? 3
                  : constraints.maxWidth >= 540
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: _WeeklyPlanCard(
                        entry: entry,
                        onOpen: () => onOpen(entry.insight),
                        onAction: entry.insight.acao == null
                            ? null
                            : () => onAction(entry.insight),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyPlanCard extends StatelessWidget {
  final _WeeklyPlanEntry entry;
  final VoidCallback onOpen;
  final VoidCallback? onAction;

  const _WeeklyPlanCard({
    required this.entry,
    required this.onOpen,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final insight = entry.insight;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('weekly-plan-${insight.tipo}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      entry.icon,
                      size: AppSizes.iconMd,
                      color: entry.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    entry.label,
                    style: AppTypography.sectionTitle.copyWith(
                      color: entry.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                insight.titulo,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.supportingText,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.acao?.label ?? 'Ver evidência e como testar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: onAction == null
                            ? AppColors.subjectTeal
                            : AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    size: AppSizes.iconSm,
                    color: onAction == null
                        ? AppColors.subjectTeal
                        : AppColors.brandPrimary,
                  ),
                ],
              ),
              if (onAction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Aplicar agora'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyPanorama extends StatelessWidget {
  final List<StudyDimension> dimensions;
  final ValueChanged<StudyDimension> onOpen;

  const _StudyPanorama({required this.dimensions, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'PANORAMA',
            title: 'Saúde do seu estudo',
            description:
                'Cada dimensão é lida separadamente — sem uma nota geral artificial.',
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780
                  ? 3
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final dimension in dimensions)
                    SizedBox(
                      width: width,
                      child: _DimensionCard(
                        dimension: dimension,
                        onTap: () => onOpen(dimension),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  final StudyDimension dimension;
  final VoidCallback onTap;

  const _DimensionCard({required this.dimension, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _insightSeverityColor(dimension.severidade);
    final icon = _dimensionIcon(dimension.id);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('dimension-${dimension.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: AppSizes.iconMd, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      dimension.titulo,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _TrendDirection(direction: dimension.direcao, color: color),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                dimension.resumo,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dimension.tendencia,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _dimensionIcon(String id) {
    switch (id) {
      case 'tempo':
        return LucideIcons.clock;
      case 'foco':
        return LucideIcons.focus;
      case 'planejamento':
        return LucideIcons.listChecks;
      case 'consistencia':
        return LucideIcons.trendingUp;
      case 'recuperacao':
        return LucideIcons.batteryWarning;
      default:
        return LucideIcons.sparkles;
    }
  }
}

class _TrendDirection extends StatelessWidget {
  final String direction;
  final Color color;

  const _TrendDirection({required this.direction, required this.color});

  @override
  Widget build(BuildContext context) {
    final symbol = direction == 'subindo'
        ? '↗'
        : direction == 'caindo'
        ? '↘'
        : direction == 'atencao'
        ? '!'
        : '→';

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        symbol,
        style: AppTypography.bodyStrong.copyWith(color: color),
      ),
    );
  }
}

class _PatternLibraryToggle extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onPressed;

  const _PatternLibraryToggle({
    required this.count,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.subjectTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              LucideIcons.search,
              size: AppSizes.iconMd,
              color: AppColors.subjectTeal,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explorar todos os padrões',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count observações com filtros, métricas e evidências.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton.outline(
            key: const ValueKey('toggle-pattern-library'),
            size: ShadButtonSize.sm,
            foregroundColor: AppColors.subjectTeal,
            onPressed: onPressed,
            child: Text(expanded ? 'Recolher' : 'Explorar'),
          ),
        ],
      ),
    );
  }
}

class _EvolutionOverview extends StatelessWidget {
  final InsightsDashboard dashboard;
  final ValueChanged<InsightComparison> onOpenComparison;

  const _EvolutionOverview({
    required this.dashboard,
    required this.onOpenComparison,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            eyebrow: 'EVOLUÇÃO',
            title: 'Antes × agora',
            description:
                'Mudanças observadas nas últimas semanas, sem transformar tudo em uma nota.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                dashboard.periodo,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780
                  ? 3
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final comparison in dashboard.comparacoes)
                    SizedBox(
                      width: width,
                      child: _ComparisonCard(
                        comparison: comparison,
                        onTap: () => onOpenComparison(comparison),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final InsightComparison comparison;
  final VoidCallback onTap;

  const _ComparisonCard({required this.comparison, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final improved = comparison.melhoraQuandoDiminui
        ? comparison.agora < comparison.antes
        : comparison.agora > comparison.antes;
    final color = improved ? AppColors.success : AppColors.warningStrong;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('comparison-${comparison.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comparison.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                comparison.contexto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ComparisonValue(
                    label: 'Antes',
                    value: comparison.antes,
                    unit: comparison.unidade,
                    muted: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: AppSizes.iconSm,
                      color: AppColors.textMuted,
                    ),
                  ),
                  _ComparisonValue(
                    label: 'Agora',
                    value: comparison.agora,
                    unit: comparison.unidade,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    comparison.variacao,
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (comparison.serie.length >= 2) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: _MiniTrendChart(
                    values: comparison.serie,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonValue extends StatelessWidget {
  final String label;
  final num value;
  final String unit;
  final bool muted;
  final Color? color;

  const _ComparisonValue({
    required this.label,
    required this.value,
    required this.unit,
    this.muted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        color ?? (muted ? AppColors.textMuted : AppColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${_formatInsightNumber(value)}$unit',
          style: AppTypography.cardTitle.copyWith(color: foreground),
        ),
      ],
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  final List<num> values;
  final Color color;

  const _MiniTrendChart({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniTrendPainter(values: values, color: color),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<num> values;
  final Color color;

  const _MiniTrendPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    var minimum = values.first.toDouble();
    var maximum = values.first.toDouble();
    for (final value in values.skip(1)) {
      final current = value.toDouble();
      if (current < minimum) minimum = current;
      if (current > maximum) maximum = current;
    }
    final span = maximum == minimum ? 1.0 : maximum - minimum;
    final path = Path();
    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final normalized = (values[index].toDouble() - minimum) / span;
      final y = size.height - 4 - normalized * (size.height - 8);
      final point = Offset(x, y);
      points.add(point);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final guidePaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      guidePaint,
    );

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 3.5, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _ExperimentsSection extends StatelessWidget {
  final List<InsightExperiment> experiments;
  final ValueChanged<InsightExperiment> onOpen;

  const _ExperimentsSection({required this.experiments, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'EXPERIMENTOS',
            title: 'Da hipótese ao resultado',
            description:
                'Acompanhe o que foi detectado, testado e observado nas suas próprias sessões.',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < experiments.length; index++) ...[
            _ExperimentCard(
              experiment: experiments[index],
              onTap: () => onOpen(experiments[index]),
            ),
            if (index != experiments.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  final InsightExperiment experiment;
  final VoidCallback onTap;

  const _ExperimentCard({required this.experiment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stateColor = _experimentColor(experiment.estado);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('experiment-${experiment.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      _experimentStateLabel(experiment.estado),
                      style: AppTypography.caption.copyWith(
                        color: stateColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    experiment.disciplina,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    experiment.inicio,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                experiment.titulo,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                experiment.hipotese,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExperimentProgress(state: experiment.estado),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Wrap(
                  spacing: AppSpacing.xxl,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ExperimentMetric(
                      label: 'Métrica',
                      value: experiment.metrica,
                    ),
                    _ExperimentMetric(
                      label: 'Inicial',
                      value:
                          '${_formatInsightNumber(experiment.valorInicial)}${experiment.unidade}',
                    ),
                    _ExperimentMetric(
                      label: 'Agora',
                      value: experiment.valorAtual == null
                          ? 'Aguardando'
                          : '${_formatInsightNumber(experiment.valorAtual!)}${experiment.unidade}',
                      color: experiment.valorAtual == null
                          ? AppColors.textMuted
                          : stateColor,
                    ),
                    _ExperimentMetric(
                      label: 'Variação',
                      value: experiment.variacao,
                      color: stateColor,
                    ),
                    _ExperimentMetric(
                      label: 'Evidência',
                      value: experiment.amostra == 0
                          ? 'Ainda sem sessões'
                          : '${experiment.amostra} sessões · ${_confidenceLabelShort(experiment.confianca)}',
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
}

class _ExperimentProgress extends StatelessWidget {
  static const _labels = ['Padrão', 'Ação', 'Teste', 'Resultado'];
  final String state;

  const _ExperimentProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    final activeSteps = state == 'resultado'
        ? 4
        : state == 'testando'
        ? 3
        : 2;

    return Row(
      children: [
        for (var index = 0; index < _labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index < activeSteps
                        ? AppColors.subjectTeal
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: index < activeSteps
                          ? AppColors.subjectTeal
                          : AppColors.border,
                    ),
                  ),
                  child: index < activeSteps
                      ? const Icon(
                          LucideIcons.circleCheck,
                          size: 13,
                          color: AppColors.textInverted,
                        )
                      : Text(
                          '${index + 1}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: index < activeSteps
                        ? AppColors.subjectTeal
                        : AppColors.textMuted,
                    fontWeight: index < activeSteps
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (index != _labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: index < activeSteps - 1
                    ? AppColors.subjectTeal
                    : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _ExperimentMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ExperimentMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.bodyStrong.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SubjectJourneySection extends StatelessWidget {
  final List<String> disciplinas;
  final String selected;
  final List<Insight> insights;
  final ValueChanged<String> onSelected;
  final ValueChanged<Insight> onOpen;
  final ValueChanged<Insight> onAction;

  const _SubjectJourneySection({
    required this.disciplinas,
    required this.selected,
    required this.insights,
    required this.onSelected,
    required this.onOpen,
    required this.onAction,
  });

  Insight? _findByTypes(List<String> types) {
    for (final type in types) {
      for (final insight in insights) {
        if (insight.tipo == type) return insight;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current =
        _findByTypes([
          'progresso',
          'efeito_acao',
          'sequencia_produtiva',
          'tarefas_no_prazo',
        ]) ??
        _firstWhere((insight) => insight.severidade == 'positivo');
    final best =
        _findByTypes([
          'melhor_horario',
          'melhor_dia_semana',
          'foco_sem_interrupcoes',
        ]) ??
        current;
    final next =
        _findByTypes([
          'ritmo_disciplina',
          'vies_estimativa',
          'cramming',
          'equilibrio_metodo',
          'duracao_ideal',
        ]) ??
        _firstWhere((insight) => insight.acao != null) ??
        _firstWhere(
          (insight) =>
              insight.severidade == 'critico' ||
              insight.severidade == 'atencao',
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'POR MATÉRIA',
            title: 'A história de cada disciplina',
            description:
                'Concentre a leitura no momento atual, na melhor condição e no próximo passo.',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: disciplinas.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final disciplina = disciplinas[index];
                final isSelected = disciplina == selected;
                return isSelected
                    ? ShadButton(
                        key: ValueKey('evolution-subject-$disciplina'),
                        size: ShadButtonSize.sm,
                        backgroundColor: AppColors.subjectTeal,
                        foregroundColor: AppColors.textInverted,
                        onPressed: () => onSelected(disciplina),
                        child: Text(disciplina),
                      )
                    : ShadButton.outline(
                        key: ValueKey('evolution-subject-$disciplina'),
                        size: ShadButtonSize.sm,
                        foregroundColor: AppColors.textSecondary,
                        onPressed: () => onSelected(disciplina),
                        child: Text(disciplina),
                      );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: AppSpacing.card,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (current != null)
                  _SubjectStoryRow(
                    label: 'AGORA',
                    icon: LucideIcons.trendingUp,
                    color: AppColors.success,
                    insight: current,
                    onOpen: () => onOpen(current),
                  ),
                if (current != null && best != null)
                  const Divider(height: AppSpacing.xxl),
                if (best != null)
                  _SubjectStoryRow(
                    label: 'MELHOR CONDIÇÃO',
                    icon: LucideIcons.circleCheck,
                    color: AppColors.subjectTeal,
                    insight: best,
                    onOpen: () => onOpen(best),
                  ),
                if ((current != null || best != null) && next != null)
                  const Divider(height: AppSpacing.xxl),
                if (next != null)
                  _SubjectStoryRow(
                    label: 'PRÓXIMO PASSO',
                    icon: LucideIcons.target,
                    color: AppColors.warningStrong,
                    insight: next,
                    onOpen: () => onOpen(next),
                    onAction: next.acao == null ? null : () => onAction(next),
                  ),
                if (current == null && best == null && next == null)
                  Text(
                    'Ainda não há dados suficientes para montar esta jornada.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Insight? _firstWhere(bool Function(Insight insight) test) {
    for (final insight in insights) {
      if (test(insight)) return insight;
    }
    return null;
  }
}

class _SubjectStoryRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Insight insight;
  final VoidCallback onOpen;
  final VoidCallback? onAction;

  const _SubjectStoryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.insight,
    required this.onOpen,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, size: AppSizes.iconMd, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.sectionTitle.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                insight.titulo,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${insight.amostra} sessões · ${_confidenceLabelShort(insight.confianca)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: onOpen,
                    child: const Text('Ver evidência'),
                  ),
                  if (onAction != null)
                    FilledButton.tonal(
                      onPressed: onAction,
                      child: Text(insight.acao!.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _experimentColor(String state) {
  switch (state) {
    case 'resultado':
      return AppColors.success;
    case 'testando':
      return AppColors.info;
    case 'pronto':
    default:
      return AppColors.warningStrong;
  }
}

String _experimentStateLabel(String state) {
  switch (state) {
    case 'resultado':
      return 'RESULTADO OBSERVADO';
    case 'testando':
      return 'EM TESTE';
    case 'pronto':
    default:
      return 'PRONTO PARA TESTAR';
  }
}

String _confidenceLabelShort(String confidence) {
  switch (confidence) {
    case 'alta':
      return 'confiança alta';
    case 'media':
      return 'confiança média';
    case 'insuficiente':
    default:
      return 'evidência inicial';
  }
}

String _formatInsightNumber(num value) {
  return value % 1 == 0
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
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
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppSizes.iconSm),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyStrong.copyWith(
            color: selected ? AppColors.textInverted : AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (selected) {
      return ShadButton(
        height: 38,
        backgroundColor: AppColors.subjectTeal,
        hoverBackgroundColor: AppColors.subjectTeal,
        foregroundColor: AppColors.textInverted,
        onPressed: onPressed,
        child: child,
      );
    }

    return ShadButton.ghost(
      height: 38,
      foregroundColor: AppColors.textSecondary,
      hoverBackgroundColor: AppColors.surfaceMuted,
      onPressed: onPressed,
      child: child,
    );
  }
}

class _SeveritySummary extends StatelessWidget {
  final Map<String, int> counts;
  final String? selectedSeverity;
  final bool attentionOnly;
  final ValueChanged<String> onSeverityPressed;
  final VoidCallback onAttentionPressed;

  const _SeveritySummary({
    required this.counts,
    required this.selectedSeverity,
    required this.attentionOnly,
    required this.onSeverityPressed,
    required this.onAttentionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        width: double.infinity,
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo dos seus padrões',
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SummaryChip(
                    key: const ValueKey('summary-positivo'),
                    count: counts['positivo'] ?? 0,
                    label: 'conquistas',
                    color: AppColors.success,
                    selected: selectedSeverity == 'positivo',
                    onTap: () => onSeverityPressed('positivo'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SummaryChip(
                    key: const ValueKey('summary-atencao'),
                    count: counts['atencao'] ?? 0,
                    label: 'atenção',
                    color: AppColors.warningStrong,
                    selected: selectedSeverity == 'atencao',
                    onTap: () => onSeverityPressed('atencao'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SummaryChip(
                    key: const ValueKey('summary-critico'),
                    count: counts['critico'] ?? 0,
                    label: 'críticos',
                    color: AppColors.danger,
                    selected: selectedSeverity == 'critico',
                    onTap: () => onSeverityPressed('critico'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SummaryChip(
                    key: const ValueKey('summary-info'),
                    count: counts['info'] ?? 0,
                    label: 'informativos',
                    color: AppColors.neutral,
                    selected: selectedSeverity == 'info',
                    onTap: () => onSeverityPressed('info'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ShadButton.outline(
              key: const ValueKey('summary-needs-attention'),
              size: ShadButtonSize.sm,
              backgroundColor: attentionOnly
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.surface,
              hoverBackgroundColor: AppColors.warning.withValues(alpha: 0.12),
              foregroundColor: AppColors.warningStrong,
              leading: const Icon(
                LucideIcons.triangleAlert,
                size: AppSizes.iconSm,
              ),
              onPressed: onAttentionPressed,
              child: Text(
                attentionOnly
                    ? 'Mostrando o que precisa de atenção'
                    : 'Só o que precisa de atenção',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryChip({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? color : AppColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTypography.cardTitle.copyWith(color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionTimeline extends StatelessWidget {
  final List<InsightJourneyEvent> events;
  final String? Function(String type) insightTitle;

  const _EvolutionTimeline({required this.events, required this.insightTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico das mudanças',
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O registro cronológico complementa as comparações acima e mostra '
            'quando cada ação aconteceu.',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (events.isEmpty)
            Text(
              'Sua jornada aparecerá aqui conforme novos padrões forem observados.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            )
          else
            ...List.generate(
              events.length,
              (index) => _TimelineEvent(
                event: events[index],
                relatedTitle: events[index].insightTipo == null
                    ? null
                    : insightTitle(events[index].insightTipo!),
                isLast: index == events.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final InsightJourneyEvent event;
  final String? relatedTitle;
  final bool isLast;

  const _TimelineEvent({
    required this.event,
    required this.relatedTitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.tipo);
    final icon = _eventIcon(event.tipo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, size: AppSizes.iconSm, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              padding: AppSpacing.card,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        event.data,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          _eventLabel(event.tipo),
                          style: AppTypography.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    event.texto,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (relatedTitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Relacionado a: $relatedTitle',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _eventColor(String type) {
    switch (type) {
      case 'acao':
        return AppColors.info;
      case 'melhora':
        return AppColors.success;
      case 'detectado':
      default:
        return AppColors.warningStrong;
    }
  }

  static IconData _eventIcon(String type) {
    switch (type) {
      case 'acao':
        return LucideIcons.zap;
      case 'melhora':
        return LucideIcons.trendingUp;
      case 'detectado':
      default:
        return LucideIcons.search;
    }
  }

  static String _eventLabel(String type) {
    switch (type) {
      case 'acao':
        return 'Ação';
      case 'melhora':
        return 'Melhora observada';
      case 'detectado':
      default:
        return 'Detectado';
    }
  }
}

Color _insightSeverityColor(String severity) {
  switch (severity) {
    case 'positivo':
      return AppColors.success;
    case 'atencao':
      return AppColors.warningStrong;
    case 'critico':
      return AppColors.danger;
    case 'info':
    default:
      return AppColors.info;
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: CircularProgressIndicator(color: AppColors.subjectTeal),
      ),
    );
  }
}

class _InsightsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _InsightsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: const Icon(
                  LucideIcons.triangleAlert,
                  color: AppColors.danger,
                  size: 30,
                ),
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
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ShadButton(
                key: const ValueKey('insights-retry'),
                backgroundColor: AppColors.subjectTeal,
                hoverBackgroundColor: AppColors.subjectTeal,
                foregroundColor: AppColors.textInverted,
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.info,
                  size: 30,
                ),
              ),
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
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryEmpty extends StatelessWidget {
  final String? category;
  final String? disciplina;

  const _CategoryEmpty({this.category, this.disciplina});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, minHeight: 220),
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.searchX,
                color: AppColors.neutral,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _message {
    if (category != null && disciplina != null) {
      return 'Nenhum insight em $category para $disciplina ainda.';
    }
    if (disciplina != null) {
      return 'Nenhum insight para $disciplina ainda.';
    }
    if (category != null) {
      return 'Nenhum insight em $category ainda.';
    }
    return 'Nenhum insight para estes filtros ainda.';
  }
}
