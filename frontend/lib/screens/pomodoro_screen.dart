import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_shell_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/sessao_estudo_service.dart';

class PomodoroScreen extends StatelessWidget {
  final PomodoroProvider? provider;

  const PomodoroScreen({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => provider ?? PomodoroProvider(),
      child: const _PomodoroView(),
    );
  }
}

class _PomodoroView extends StatefulWidget {
  const _PomodoroView();

  @override
  State<_PomodoroView> createState() => _PomodoroViewState();
}

class _PomodoroViewState extends State<_PomodoroView> {
  bool _productivityPromptOpen = false;
  bool _wasVisibleInShell = false;
  bool _refreshScheduled = false;
  int _lastRefreshRevision = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final shellState = _watchShellState(context);
    _scheduleRefreshIfNeeded(provider, shellState.visible, shellState.revision);

    if (provider.produtividadePendente && !_productivityPromptOpen) {
      _productivityPromptOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _askProductivity(provider);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= AppSizes.desktopBreakpoint;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(provider),
                        if (provider.error != null)
                          _buildErrorBanner(provider.error!),
                        if (provider.disciplinas.isEmpty &&
                            provider.error == null)
                          _buildEmptyDisciplinas()
                        else
                          const SizedBox(height: 22),
                        if (provider.disciplinas.isNotEmpty)
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _TimerCard(provider: provider),
                                    ),
                                    const SizedBox(width: 22),
                                    SizedBox(
                                      width: 340,
                                      child: _SidePanel(provider: provider),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _TimerCard(provider: provider),
                                    const SizedBox(height: 22),
                                    _SidePanel(provider: provider),
                                  ],
                                ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  ({bool visible, int revision}) _watchShellState(BuildContext context) {
    try {
      final shell = context.watch<AppShellProvider>();
      return (
        visible: shell.currentPage == AppPage.pomodoro,
        revision: shell.pomodoroRefreshRevision,
      );
    } on ProviderNotFoundException {
      return (visible: true, revision: 0);
    }
  }

  void _scheduleRefreshIfNeeded(
    PomodoroProvider provider,
    bool visible,
    int revision,
  ) {
    if (!visible) {
      _wasVisibleInShell = false;
      return;
    }
    if (provider.loading) return;

    final shouldRefresh =
        !_wasVisibleInShell || revision != _lastRefreshRevision;
    _wasVisibleInShell = true;
    if (!shouldRefresh || _refreshScheduled) return;

    _lastRefreshRevision = revision;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await provider.atualizarDadosExternos();
      } finally {
        if (mounted) {
          setState(() => _refreshScheduled = false);
        }
      }
    });
  }

  Future<void> _askProductivity(PomodoroProvider provider) async {
    final produtividade = await _showProductivityPrompt(
      context,
      encerradoAntecipadamente: provider.produtividadePendenteAntecipada,
    );
    if (!mounted) return;
    await provider.responderProdutividade(produtividade);
    if (mounted) {
      setState(() => _productivityPromptOpen = false);
    }
  }

  Widget _buildHeader(PomodoroProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pomodoro',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sessões de foco cronometradas e vinculadas às suas disciplinas.',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFF5C6CB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDisciplinas() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Cadastre uma disciplina para iniciar sessões de Pomodoro.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card do timer (esquerda)
// ---------------------------------------------------------------------------

class _TimerCard extends StatelessWidget {
  final PomodoroProvider provider;
  const _TimerCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final d = provider.disciplinaSelecionada!;
    final subtitulo = (d.codigo?.isNotEmpty ?? false)
        ? d.codigo!
        : (d.descricao?.isNotEmpty ?? false)
        ? d.descricao!
        : 'Sessão de foco';

    return _Card(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      child: Column(
        children: [
          // seletor de disciplina + meta
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.appBackground,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: provider.corSelecionada,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MateriaSeletor(provider: provider),
                const SizedBox(height: 10),
                _SessaoSeletor(provider: provider),
              ],
            ),
          ),

          const SizedBox(height: 30),
          _TimerRing(provider: provider),
          const SizedBox(height: 26),
          _PrimaryControls(provider: provider),
          if (provider.mode == PomodoroMode.foco) ...[
            const SizedBox(height: 12),
            _EnergyStatusControl(provider: provider),
            const SizedBox(height: 8),
            _InterruptionControl(provider: provider),
          ],
          const SizedBox(height: 22),
          _ModeTabs(provider: provider),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.surfaceSubtle),
          const SizedBox(height: 18),
          _DurationSteppers(provider: provider),
        ],
      ),
    );
  }
}

/// Primeiro passo do seletor: escolhe a matéria (disciplina).
class _MateriaSeletor extends StatelessWidget {
  final PomodoroProvider provider;
  const _MateriaSeletor({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _SeletorContainer(
      label: 'MATÉRIA',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textMuted,
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          value: provider.disciplinaSelecionada?.id,
          hint: const Text(
            'Selecione a matéria',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          selectedItemBuilder: (context) {
            return provider.disciplinas.map((d) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  d.nome,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList();
          },
          items: provider.disciplinas
              .map(
                (d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    d.nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final d = provider.disciplinas.firstWhere((e) => e.id == id);
            provider.selecionarDisciplina(d);
          },
        ),
      ),
    );
  }
}

/// Segundo passo do seletor: escolhe a sessão específica (por data/horário)
/// dentro da matéria já selecionada. Some vazio se a matéria não tiver sessão.
class _SessaoSeletor extends StatelessWidget {
  final PomodoroProvider provider;
  const _SessaoSeletor({required this.provider});

  static String _formatarSessao(SessaoEstudoResumo s) {
    final data =
        '${s.inicio.day.toString().padLeft(2, '0')}/${s.inicio.month.toString().padLeft(2, '0')}';
    final hIni =
        '${s.inicio.hour.toString().padLeft(2, '0')}:${s.inicio.minute.toString().padLeft(2, '0')}';
    final hFim =
        '${s.fim.hour.toString().padLeft(2, '0')}:${s.fim.minute.toString().padLeft(2, '0')}';
    return '$data · $hIni - $hFim';
  }

  @override
  Widget build(BuildContext context) {
    final sessoes = provider.sessoesDaDisciplinaSelecionada;

    if (sessoes.isEmpty) {
      return _SeletorContainer(
        label: 'SESSÃO',
        child: Text(
          'Não há sessão agendada para esta matéria.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

    final valorAtual =
        sessoes.any((s) => s.id == provider.sessaoSelecionada?.id)
        ? provider.sessaoSelecionada?.id
        : null;

    return _SeletorContainer(
      label: 'SESSÃO',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textMuted,
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          value: valorAtual,
          hint: const Text(
            'Selecione a sessão',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          selectedItemBuilder: (context) {
            return sessoes.map((s) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatarSessao(s),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList();
          },
          items: sessoes
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    _formatarSessao(s),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final s = sessoes.firstWhere((e) => e.id == id);
            provider.selecionarSessao(s);
          },
        ),
      ),
    );
  }
}

class _SeletorContainer extends StatelessWidget {
  final String label;
  final Widget child;
  const _SeletorContainer({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.neutral,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.cardSoft,
          ),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
  }
}

class _TimerRing extends StatelessWidget {
  final PomodoroProvider provider;
  const _TimerRing({required this.provider});

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(
              progress: provider.elapsedFraction,
              color: provider.ringColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: provider.ringColorSuave,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  PomodoroProvider.modeLabels[provider.mode]!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: provider.ringColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.timeText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.cycleText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - 16) / 2;

    final track = Paint()
      ..color = AppColors.surfaceSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, track);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _PrimaryControls extends StatelessWidget {
  final PomodoroProvider provider;
  const _PrimaryControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundIconButton(
          icon: Icons.replay_rounded,
          onTap: provider.reset,
          tooltip: 'Reiniciar',
        ),
        const SizedBox(width: 14),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _handleToggle(context),
            icon: Icon(
              provider.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
            ),
            label: Text(provider.running ? 'Pausar' : 'Iniciar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.ringColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              elevation: 6,
              shadowColor: provider.ringColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _RoundIconButton(
          icon: Icons.skip_next_rounded,
          onTap: provider.skip,
          tooltip: 'Pular',
        ),
      ],
    );
  }

  Future<void> _handleToggle(BuildContext context) async {
    if (provider.running || !provider.deveSolicitarEnergia) {
      provider.toggle();
      return;
    }

    final energia = await _showEnergyPrompt(
      context,
      initialValue: provider.energiaInicial,
    );
    if (!context.mounted) return;

    if (energia == null) {
      provider.ignorarEnergiaInicial();
    } else {
      provider.definirEnergiaInicial(energia);
    }
    provider.toggle();
  }
}

Future<int?> _showEnergyPrompt(BuildContext context, {int? initialValue}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black54,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RatingPrompt(
      title: 'Como está sua energia agora?',
      subtitle: 'Opcional · um toque antes de começar',
      keyPrefix: 'energia',
      labels: const ['Muito baixa', 'Baixa', 'Regular', 'Alta', 'Muito alta'],
      initialValue: initialValue,
    ),
  );
}

Future<int?> _showProductivityPrompt(
  BuildContext context, {
  required bool encerradoAntecipadamente,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black54,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RatingPrompt(
      title: 'Como foi seu foco neste bloco?',
      subtitle: encerradoAntecipadamente
          ? 'O bloco terminou antes · responder mantém este registro'
          : 'Opcional · avalie apenas o ciclo que acabou',
      keyPrefix: 'produtividade',
      labels: const ['Muito baixo', 'Baixo', 'Regular', 'Bom', 'Excelente'],
      skipLabel: encerradoAntecipadamente
          ? 'Não responder e descartar bloco'
          : 'Agora não',
    ),
  );
}

class _RatingPrompt extends StatelessWidget {
  final String title;
  final String subtitle;
  final String keyPrefix;
  final List<String> labels;
  final String skipLabel;
  final int? initialValue;

  const _RatingPrompt({
    required this.title,
    required this.subtitle,
    required this.keyPrefix,
    required this.labels,
    this.skipLabel = 'Agora não',
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final columns = constraints.maxWidth >= 520 ? 5 : 3;
                  final cardWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (var index = 0; index < labels.length; index++)
                        SizedBox(
                          width: cardWidth,
                          height: 72,
                          child: Semantics(
                            selected: initialValue == index + 1,
                            label: '$title ${index + 1}: ${labels[index]}',
                            button: true,
                            child: Material(
                              color: initialValue == index + 1
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: initialValue == index + 1
                                      ? AppColors.brandPrimary
                                      : const Color(0xFFCBD5E1),
                                  width: initialValue == index + 1 ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: ValueKey('$keyPrefix-${index + 1}'),
                                onTap: () =>
                                    Navigator.of(context).pop(index + 1),
                                overlayColor: WidgetStatePropertyAll(
                                  AppColors.brandPrimary.withValues(alpha: 0.1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandPrimaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      labels[index],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: ValueKey('$keyPrefix-pular'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandPrimaryDark,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(skipLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyStatusControl extends StatelessWidget {
  final PomodoroProvider provider;

  const _EnergyStatusControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    final energia = provider.energiaInicial;
    return OutlinedButton.icon(
      key: const ValueKey('energia-status'),
      onPressed: provider.podeIniciarFoco && !provider.running
          ? () => _editEnergy(context)
          : null,
      icon: Icon(
        energia == null
            ? Icons.battery_unknown_outlined
            : Icons.battery_charging_full_rounded,
        size: 18,
      ),
      label: Text(
        energia == null
            ? 'Informar energia'
            : 'Energia inicial: $energia/5 · Alterar',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandPrimaryDark,
        side: const BorderSide(color: Color(0xFFC7D2FE)),
      ),
    );
  }

  Future<void> _editEnergy(BuildContext context) async {
    final energia = await _showEnergyPrompt(
      context,
      initialValue: provider.energiaInicial,
    );
    if (!context.mounted || energia == null) return;
    provider.definirEnergiaInicial(energia);
  }
}

class _InterruptionControl extends StatelessWidget {
  final PomodoroProvider provider;

  const _InterruptionControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    final count = provider.interrupcoesBloco;
    return Tooltip(
      message: 'Registre quando algo quebrar seu foco.',
      child: OutlinedButton.icon(
        key: const ValueKey('registrar-interrupcao'),
        onPressed: provider.podeRegistrarInterrupcao
            ? provider.registrarInterrupcao
            : null,
        icon: const Icon(Icons.notifications_active_outlined, size: 18),
        label: Text(
          count == 0
              ? 'Registrar interrupção'
              : '$count ${count == 1 ? 'interrupção' : 'interrupções'}',
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final PomodoroProvider provider;
  const _ModeTabs({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PomodoroMode.values.map((m) {
        final selected = provider.mode == m;
        final color = PomodoroProvider.modeColors[m]!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: m != PomodoroMode.longa ? 10 : 0),
            child: InkWell(
              onTap: () => provider.setMode(m),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      PomodoroProvider.modeLabels[m]!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.durations[m]} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            (selected ? Colors.white : AppColors.textSecondary)
                                .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DurationSteppers extends StatelessWidget {
  final PomodoroProvider provider;
  const _DurationSteppers({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DURAÇÕES (MINUTOS)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.neutral,
          ),
        ),
        const SizedBox(height: 12),
        ...PomodoroMode.values.map((m) {
          final color = PomodoroProvider.modeColors[m]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      PomodoroProvider.modeLabels[m]!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: () => provider.ajustarDuracao(m, -1),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${provider.durations[m]} min',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: () => provider.ajustarDuracao(m, 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painel lateral (direita)
// ---------------------------------------------------------------------------

class _SidePanel extends StatelessWidget {
  final PomodoroProvider provider;
  const _SidePanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResumoHojeCard(provider: provider),
        const SizedBox(height: 22),
        _HistoricoCard(provider: provider),
      ],
    );
  }
}

class _ResumoHojeCard extends StatelessWidget {
  final PomodoroProvider provider;
  const _ResumoHojeCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de hoje',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '${provider.sessionsToday}',
                  label: 'Sessões',
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  value: provider.focusHojeText,
                  label: 'Foco',
                  color: AppColors.subjectTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  value: '${provider.sessionsToday}',
                  label: 'Ciclos',
                  color: AppColors.subjectPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  final PomodoroProvider provider;
  const _HistoricoCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pomodoros recentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Últimas sessões de foco concluídas.',
            style: TextStyle(fontSize: 12.5, color: AppColors.neutral),
          ),
          const SizedBox(height: 12),
          if (provider.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhuma sessão concluída ainda hoje.',
                  style: TextStyle(color: AppColors.neutral, fontSize: 13),
                ),
              ),
            )
          else
            ...provider.history.map(
              (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color.lerp(h.cor, Colors.white, 0.85),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: h.cor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.disciplinaNome,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${h.duracaoMinutos} min · foco',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      h.hora,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: card base
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
