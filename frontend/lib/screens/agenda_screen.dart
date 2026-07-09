/// Tela principal da Agenda Academica.
///
/// A experiencia principal e um calendario semanal navegavel, com sessoes de
/// estudo e eventos academicos posicionados por dia e horario.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/agenda_provider.dart';
import '../widgets/weekly_calendar_grid.dart';
import 'criar_evento_screen.dart';
import 'criar_sessao_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AgendaProvider>();
    Future.microtask(() => provider.fetchAgenda());
  }

  void _abrirOpcoesCadastro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'Registrar na agenda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.brandPrimaryDark,
                  ),
                  title: const Text(
                    'Evento academico',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Provas, trabalhos, seminarios e entregas',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  iconColor: AppColors.brandPrimaryDark,
                  textColor: AppColors.textPrimary,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final criado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CriarEventoScreen(),
                      ),
                    );
                    if (criado == true && context.mounted) {
                      context.read<AgendaProvider>().fetchAgenda();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.subjectTeal,
                  ),
                  title: const Text(
                    'Sessao de estudo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Bloco de foco ligado a uma disciplina',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  iconColor: AppColors.subjectTeal,
                  textColor: AppColors.textPrimary,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final criado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CriarSessaoScreen(),
                      ),
                    );
                    if (criado == true && context.mounted) {
                      context.read<AgendaProvider>().fetchAgenda();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Calendario'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        actions: [
          IconButton(
            tooltip: 'Atualizar agenda',
            onPressed: () =>
                context.read<AgendaProvider>().fetchAgenda(isRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<AgendaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return _ErrorState(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchAgenda(),
            );
          }

          return const WeeklyCalendarGrid();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirOpcoesCadastro(context),
        label: const Text('Registrar'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textInverted,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.55),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
