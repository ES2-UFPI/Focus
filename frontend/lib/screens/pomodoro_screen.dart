import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PomodoroProvider(),
      child: const _PomodoroView(),
    );
  }
}

class _PomodoroView extends StatelessWidget {
  const _PomodoroView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= AppSizes.desktopBreakpoint;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(provider),
                        if (provider.error != null) _buildErrorBanner(provider.error!),
                        if (provider.disciplinas.isEmpty && provider.error == null)
                          _buildEmptyDisciplinas()
                        else
                          const SizedBox(height: 22),
                        if (provider.disciplinas.isNotEmpty)
                          isWide
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: _TimerCard(provider: provider)),
                                      const SizedBox(width: 22),
                                      SizedBox(width: 340, child: _SidePanel(provider: provider)),
                                    ],
                                  ),
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

  Widget _buildHeader(PomodoroProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pomodoro',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
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
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
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
                      decoration: BoxDecoration(color: provider.corSelecionada, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.nome,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: provider.trocarDisciplina,
                      icon: const Icon(Icons.sync_alt_rounded, size: 14),
                      label: const Text('Trocar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_bottom_rounded, size: 14, color: provider.dueColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(provider.dueText,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: provider.dueColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (provider.temMultiplasMetas) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: provider.trocarMeta,
                              borderRadius: BorderRadius.circular(6),
                              child: const Tooltip(
                                message: 'Trocar meta (Prova, Trabalho...)',
                                child: Icon(Icons.swap_horiz_rounded, size: 15, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${provider.doneCountSelecionado} de ${provider.goalPlanejado} pomodoros',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: provider.goalPct,
                    minHeight: 8,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation(provider.corSelecionada),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          _TimerRing(provider: provider),
          const SizedBox(height: 26),
          _PrimaryControls(provider: provider),
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
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                decoration: BoxDecoration(color: provider.ringColorSuave, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  PomodoroProvider.modeLabels[provider.mode]!.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: provider.ringColor),
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
              Text(provider.cycleText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
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
        _RoundIconButton(icon: Icons.replay_rounded, onTap: provider.reset, tooltip: 'Reiniciar'),
        const SizedBox(width: 14),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: provider.toggle,
            icon: Icon(provider.running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
            label: Text(provider.running ? 'Pausar' : 'Iniciar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.ringColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              elevation: 6,
              shadowColor: provider.ringColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _RoundIconButton(icon: Icons.skip_next_rounded, onTap: provider.skip, tooltip: 'Pular'),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _RoundIconButton({required this.icon, required this.onTap, required this.tooltip});

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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? color : AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(PomodoroProvider.modeLabels[m]!,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('${provider.durations[m]} min',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: (selected ? Colors.white : AppColors.textSecondary).withValues(alpha: 0.85))),
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
        const Text('DURAÇÕES (MINUTOS)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.neutral)),
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
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(PomodoroProvider.modeLabels[m]!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    _StepperButton(icon: Icons.remove, onTap: () => provider.ajustarDuracao(m, -1)),
                    SizedBox(
                      width: 52,
                      child: Text('${provider.durations[m]} min',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    _StepperButton(icon: Icons.add, onTap: () => provider.ajustarDuracao(m, 1)),
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
        _ConsistenciaSemanalCard(provider: provider),
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
          const Text('Resumo de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatBox(value: '${provider.sessionsToday}', label: 'Sessões', color: AppColors.brandPrimary)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(value: provider.focusHojeText, label: 'Foco', color: AppColors.subjectTeal)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(value: '${provider.sessionsToday}', label: 'Ciclos', color: AppColors.subjectPurple)),
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
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.appBackground, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ConsistenciaSemanalCard extends StatelessWidget {
  final PomodoroProvider provider;
  const _ConsistenciaSemanalCard({required this.provider});

  static const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final maxH = max(6.0, provider.weekHours.fold<double>(0, max));
    final total = provider.weekHours.fold<double>(0, (a, b) => a + b);
    final hojeIdx = DateTime.now().weekday - 1;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consistência semanal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${total.toStringAsFixed(1)}h registradas nesta semana',
              style: const TextStyle(fontSize: 12.5, color: AppColors.neutral)),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = provider.weekHours[i];
                final pct = h <= 0 ? 0.0 : (h / maxH).clamp(0.0, 1.0);
                final isHoje = i == hojeIdx;
                final barColor = h <= 0 ? AppColors.borderSubtle : (isHoje ? AppColors.brandPrimary : AppColors.successSoft);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: pct == 0 ? 0.02 : pct,
                              child: Container(
                                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_dias[i],
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isHoje ? FontWeight.w700 : FontWeight.w500,
                                color: isHoje ? AppColors.brandPrimary : AppColors.neutral)),
                      ],
                    ),
                  ),
                );
              }),
            ),
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
          const Text('Pomodoros recentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Últimas sessões de foco concluídas.', style: TextStyle(fontSize: 12.5, color: AppColors.neutral)),
          const SizedBox(height: 12),
          if (provider.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Nenhuma sessão concluída ainda hoje.', style: TextStyle(color: AppColors.neutral, fontSize: 13)),
              ),
            )
          else
            ...provider.history.map((h) => Padding(
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
                            decoration: BoxDecoration(color: h.cor, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.disciplinaNome,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('${h.duracaoMinutos} min · foco', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(h.hora, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.neutral)),
                    ],
                  ),
                )),
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
        boxShadow: const [BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }
}
