/// Tela principal da Agenda Acadêmica.
///
/// Apresenta a timeline de atividades do aluno com:
/// - Chips de filtro rápido (Todos / Eventos / Sessões)
/// - Seção de recomendações inteligentes
/// - Timeline cronológica agrupada por data
/// - Pull-To-Refresh via [RefreshIndicator]
/// - Estados visuais de carregamento, erro e lista vazia
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/agenda_provider.dart';
import '../widgets/agenda_timeline.dart';
import '../widgets/recomendacoes_section.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    // Captura a referência ao provider de forma síncrona antes do gap assíncrono.
    final provider = context.read<AgendaProvider>();
    Future.microtask(() => provider.fetchAgenda());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Acadêmica'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Consumer<AgendaProvider>(
        builder: (context, provider, _) {
          // ── Estado de carregamento inicial ──────────────────────────────
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Estado de erro ─────────────────────────────────────────────
          if (provider.errorMessage != null) {
            return _ErrorState(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchAgenda(),
            );
          }

          // ── Conteúdo principal ─────────────────────────────────────────
          return RefreshIndicator(
            onRefresh: () => provider.fetchAgenda(isRefresh: true),
            child: _AgendaContent(provider: provider),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conteúdo principal da agenda (filtros + recomendações + timeline)
// ---------------------------------------------------------------------------

class _AgendaContent extends StatelessWidget {
  final AgendaProvider provider;

  const _AgendaContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final agrupados = provider.itensAgrupadosPorData;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Filtros ────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _FilterChips(provider: provider)),

        // ── Recomendações ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: RecomendacoesSection(
            recomendacoes: provider.recomendacoes,
          ),
        ),

        // ── Timeline ou estado vazio ───────────────────────────────────
        if (agrupados.isEmpty)
          const SliverFillRemaining(child: _EmptyState())
        else
          SliverToBoxAdapter(
            child: AgendaTimeline(itensAgrupadosPorData: agrupados),
          ),

        // Espaço inferior para não cortar o último card
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chips de filtro rápido
// ---------------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  final AgendaProvider provider;

  const _FilterChips({required this.provider});

  static const _filters = [
    {'key': 'TODOS', 'label': 'Todos'},
    {'key': 'EVENTOS', 'label': 'Eventos'},
    {'key': 'SESSOES', 'label': 'Sessões'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        children: _filters.map((f) {
          final isSelected = provider.selectedFilter == f['key'];
          return ChoiceChip(
            label: Text(f['label']!),
            selected: isSelected,
            onSelected: (_) => provider.setFilter(f['key']!),
            showCheckmark: false,
            selectedColor:
                Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vazio
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 16),
            Text(
              'Sua agenda está livre!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nenhuma atividade encontrada para o filtro selecionado.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[450],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de erro
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
