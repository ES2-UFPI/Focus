import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../data/insights_mock.dart';
import '../models/insights_model.dart';
import '../widgets/insight_card.dart';

class InsightsScreen extends StatefulWidget {
  /// Permite exercitar os estados da tela sem alterar a fonte de produção.
  final List<Insight>? insights;

  const InsightsScreen({super.key, this.insights});

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
  ];

  late List<Insight> _items;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _items = widget.insights ?? getInsightsMock();
  }

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insights != widget.insights) {
      _items = widget.insights ?? getInsightsMock();
    }
  }

  List<String> get _availableCategories => _categoryOrder
      .where(
        (category) => _items.any((insight) => insight.categoria == category),
      )
      .toList();

  List<Insight> get _filteredItems {
    if (_selectedCategory == null) return _items;
    return _items
        .where((insight) => insight.categoria == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyInsights(),
            )
          else ...[
            SliverToBoxAdapter(child: _buildIntroduction(items)),
            SliverToBoxAdapter(child: _buildCategoryFilters()),
            if (filteredItems.isEmpty)
              SliverToBoxAdapter(
                child: _CategoryEmpty(
                  category: _categoryLabel(_selectedCategory),
                ),
              )
            else
              SliverToBoxAdapter(child: _buildInsightGrid(filteredItems)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
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
      default:
        return 'esta categoria';
    }
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
  final String category;

  const _CategoryEmpty({required this.category});

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
                'Nenhum insight em $category ainda.',
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
}
