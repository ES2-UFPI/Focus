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

  const InsightsScreen({super.key, this.insights, this.service});

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
  bool _loading = false;
  Object? _error;
  late final InsightsService _service;
  _InsightsView _selectedView = _InsightsView.insights;
  String? _selectedCategory;
  String? _selectedDisciplina;
  String? _selectedSeverity;
  bool _attentionOnly = false;
  String? _reasonPickerFor;

  // Fase de dados: este mapa local vira
  // POST /api/insights/{id}/feedback (modelo InsightFeedback). A resposta
  // alimentará personalização determinística: reduzir a prioridade de itens
  // rejeitados, ajustar limiares e reavaliar o insight após um período —
  // sem "IA que aprende".
  final Map<String, InsightFeedbackState> _feedbackByType = {};

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const InsightsService();
    if (widget.insights != null) {
      // Injeção síncrona (testes/estados): sem carregamento assíncrono.
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

  Insight? get _weeklyFocus {
    final candidates = _items
        .where(
          (insight) =>
              insight.confianca != 'insuficiente' &&
              _feedbackByType[insight.tipo]?.status !=
                  InsightFeedbackStatus.rejected,
        )
        .toList();

    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) =>
          _severityPriority(b.severidade) - _severityPriority(a.severidade),
    );
    return candidates.first;
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
    final weeklyFocus = _weeklyFocus;

    if (_selectedView == _InsightsView.evolucao) {
      return [SliverToBoxAdapter(child: _buildEvolution())];
    }
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: _EmptyInsights()),
      ];
    }
    return [
      SliverToBoxAdapter(child: _buildIntroduction(items)),
      if (weeklyFocus != null)
        SliverToBoxAdapter(child: _buildWeeklyFocus(weeklyFocus)),
      SliverToBoxAdapter(child: _buildSeveritySummary()),
      SliverToBoxAdapter(child: _buildCategoryFilters()),
      SliverToBoxAdapter(child: _buildDisciplinaFilters()),
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

  Widget _buildWeeklyFocus(Insight insight) {
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
          child: _WeeklyFocusCard(
            insight: insight,
            onTap: () => _openDetail(insight),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _EvolutionTimeline(
          events: _journey,
          insightTitle: (type) {
            for (final insight in _items) {
              if (insight.tipo == type) return insight.titulo;
            }
            return null;
          },
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
                      'Seus padrões',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'São tendências dos seus registros, não relações de causa '
                      'e efeito.',
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

  int _severityPriority(String severity) {
    switch (severity) {
      case 'critico':
        return 4;
      case 'atencao':
        return 3;
      case 'positivo':
        return 2;
      case 'info':
      default:
        return 1;
    }
  }

  void _markUseful(Insight insight) {
    unawaited(
      _service.submitFeedback(insightId: insight.id, useful: true),
    );
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

class _WeeklyFocusCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback onTap;

  const _WeeklyFocusCard({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final severityColor = _insightSeverityColor(insight.severidade);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const ValueKey('weekly-focus-card'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppGradients.reportsHeader,
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textInverted.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Icon(
                  LucideIcons.target,
                  color: AppColors.textInverted,
                  size: AppSizes.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Foco da semana',
                          style: AppTypography.sectionTitle.copyWith(
                            color: AppColors.textInverted.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            _severityLabel(insight.severidade),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textInverted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      insight.titulo,
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textInverted,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      insight.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textInverted.withValues(alpha: 0.86),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                LucideIcons.arrowRight,
                color: AppColors.textInverted,
                size: AppSizes.iconLg,
              ),
            ],
          ),
        ),
      ),
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
            'Sua evolução',
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Uma linha do tempo observacional entre padrões detectados, ações '
            'registradas e mudanças percebidas.',
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

String _severityLabel(String severity) {
  switch (severity) {
    case 'positivo':
      return 'Conquista';
    case 'atencao':
      return 'Atenção';
    case 'critico':
      return 'Crítico';
    case 'info':
    default:
      return 'Informativo';
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
