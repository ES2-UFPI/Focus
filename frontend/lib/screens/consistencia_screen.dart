import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Tokens de design
// ─────────────────────────────────────────────

abstract class _C {
  static const bg = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const surfaceHigh = Color(0xFFF8F9FC);
  static const border = Color(0xFFE3E7ED);
  static const primary = Color(0xFF2563EB);
  static const primaryDim = Color(0x337C6FFF);
  static const success = Color(0xFF2DD4A0);
  static const successDim = Color(0x332DD4A0);
  static const warning = Color(0xFFFF8C42);
  static const warningDim = Color(0x33FF8C42);
  static const danger = Color(0xFFFF5C7A);
  static const dangerDim = Color(0x33FF5C7A);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
}

// ─────────────────────────────────────────────
// Tela principal
// ─────────────────────────────────────────────

class ConsistenciaScreen extends StatefulWidget {
  const ConsistenciaScreen({super.key});

  @override
  State<ConsistenciaScreen> createState() => _ConsistenciaScreenState();
}

class _ConsistenciaScreenState extends State<ConsistenciaScreen> {
  late Future<DashboardData?> _dashboardFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _apiService.getDashboardConsistencia();
  }

  void _carregarDados() {
    final future = _apiService.getDashboardConsistencia();
    setState(() => _dashboardFuture = future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DashboardData?>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _C.primary),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _buildErro();
          }

          final d = snapshot.data!;

          return RefreshIndicator(
            color: _C.primary,
            backgroundColor: _C.surface,
            onRefresh: () async => _carregarDados(),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildHero(d)),
                SliverToBoxAdapter(child: _buildMetricasRapidas(d)),
                if (d.alertas.isNotEmpty)
                  SliverToBoxAdapter(child: _buildAlertas(d)),
                SliverToBoxAdapter(child: _buildFrequenciaDias(d)),
                SliverToBoxAdapter(child: _buildMetas(d)),
                SliverToBoxAdapter(child: _buildComponentesIndice(d)),
                SliverToBoxAdapter(child: _buildComparacao(d)),
                SliverToBoxAdapter(child: _buildDistribuicao(d)),
                SliverToBoxAdapter(child: _buildEvolucao(d)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── App Bar ──────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _C.bg,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Consistência',
        style: TextStyle(
          color: _C.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _C.textSecondary),
          onPressed: _carregarDados,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  // ── Hero — Índice de Consistência ────────────

  Widget _buildHero(DashboardData d) {
    final cor = _corIndice(d.indiceConsistencia);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: _card(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      valor: d.indiceConsistencia / 100,
                      cor: cor,
                      corFundo: _C.border,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d.indiceConsistencia.toInt()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: cor,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              d.labelIndice,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${d.horasEstudadas.toStringAsFixed(1)}h estudadas de ${d.horasPlanejadas.toStringAsFixed(1)}h planejadas',
              style: const TextStyle(
                fontSize: 13,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: d.horasPlanejadas > 0
                    ? (d.horasEstudadas / d.horasPlanejadas).clamp(0, 1)
                    : 0,
                minHeight: 6,
                backgroundColor: _C.border,
                valueColor: AlwaysStoppedAnimation(cor),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Métricas Rápidas ─────────────────────────

  Widget _buildMetricasRapidas(DashboardData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _metricaCard(
              icone: Icons.play_circle_outline_rounded,
              cor: _C.primary,
              valor: '${d.sessoesSemana}',
              label: 'Sessões',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metricaCard(
              icone: Icons.local_fire_department_rounded,
              cor: _C.warning,
              valor: '${d.streakDias}',
              label: 'Dias seguidos',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metricaCard(
              icone: Icons.calendar_today_rounded,
              cor: _C.success,
              valor: '${d.frequencia.diasEstudados}/7',
              label: 'Dias ativos',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricaCard({
    required IconData icone,
    required Color cor,
    required String valor,
    required String label,
  }) {
    return _card(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _C.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Alertas ──────────────────────────────────

  Widget _buildAlertas(DashboardData d) {
    final cor = d.severidadeAlertas == 'alta'
        ? _C.danger
        : d.severidadeAlertas == 'media'
            ? _C.warning
            : _C.textSecondary;
    final corDim = d.severidadeAlertas == 'alta'
        ? _C.dangerDim
        : d.severidadeAlertas == 'media'
            ? _C.warningDim
            : _C.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: corDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Atenção',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...d.alertas.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.mensagem,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _C.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Frequência por Dia ───────────────────────

  Widget _buildFrequenciaDias(DashboardData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao('Frequência diária', '${d.frequencia.percentual.toInt()}% da semana'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: d.diasConsistencia.map((dia) {
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: dia.estudou ? _C.successDim : _C.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: dia.estudou ? _C.success : _C.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        dia.estudou
                            ? Icons.check_rounded
                            : Icons.remove_rounded,
                        size: 16,
                        color: dia.estudou ? _C.success : _C.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dia.abrev,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: dia.estudou ? _C.textPrimary : _C.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metas por Disciplina ─────────────────────

  Widget _buildMetas(DashboardData d) {
    if (d.metasDisciplinas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao(
              'Metas semanais',
              '${d.metasDisciplinas.where((m) => m.atingiu).length}/${d.metasDisciplinas.length} atingidas',
            ),
            const SizedBox(height: 16),
            ...d.metasDisciplinas.map((meta) => _itemMeta(meta)),
          ],
        ),
      ),
    );
  }

  Widget _itemMeta(MetaDisciplinaData meta) {
    final cor = meta.atingiu ? _C.success : _C.primary;
    final percentFormatado = (meta.percentual * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meta.nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (meta.atingiu)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.successDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ Meta',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.success,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                '${meta.horasEstudadas.toStringAsFixed(1)}h / ${meta.meta.toStringAsFixed(0)}h',
                style: const TextStyle(
                  fontSize: 12,
                  color: _C.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: meta.percentual,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$percentFormatado%',
            style: TextStyle(
              fontSize: 10,
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Componentes do Índice ────────────────────

  Widget _buildComponentesIndice(DashboardData d) {
    final c = d.componentesIndice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao('Como o índice é calculado', null),
            const SizedBox(height: 16),
            _itemComponente('Frequência semanal', c.frequencia, '40%', _C.primary),
            const SizedBox(height: 12),
            _itemComponente('Metas atingidas', c.metas, '40%', _C.success),
            const SizedBox(height: 12),
            _itemComponente('Dias seguidos', c.streak, '20%', _C.warning),
          ],
        ),
      ),
    );
  }

  Widget _itemComponente(String label, double valor, String peso, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: _C.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.surfaceHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                peso,
                style: const TextStyle(
                  fontSize: 10,
                  color: _C.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${valor.toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (valor / 100).clamp(0, 1),
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Comparação de Semanas ────────────────────

  Widget _buildComparacao(DashboardData d) {
    final c = d.comparacao;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao('Esta semana vs anterior', null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _colunaComparacao('Esta semana', c.horasAtual, c.sessoesAtual, true)),
                Container(width: 1, height: 60, color: _C.border),
                Expanded(child: _colunaComparacao('Semana passada', c.horasAnterior, c.sessoesAnterior, false)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _deltaChip(c.diferencaHoras, 'h de estudo'),
                  const SizedBox(width: 16),
                  _deltaChip(c.diferencaSessoes.toDouble(), 'sessões'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colunaComparacao(String titulo, double horas, int sessoes, bool destaque) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color: destaque ? _C.primary : _C.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${horas.toStringAsFixed(1)}h',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: destaque ? _C.textPrimary : _C.textSecondary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '$sessoes sessões',
            style: const TextStyle(fontSize: 11, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _deltaChip(double valor, String label) {
    final positivo = valor >= 0;
    final cor = positivo ? _C.success : _C.danger;
    final prefixo = positivo ? '+' : '';
    final icone = positivo ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 4),
        Text(
          '$prefixo${valor % 1 == 0 ? valor.toInt() : valor.toStringAsFixed(1)} $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ],
    );
  }

  // ── Distribuição por Disciplina ──────────────

  Widget _buildDistribuicao(DashboardData d) {
    if (d.distribuicao.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao('Distribuição de foco', null),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 30,
                      sections: d.distribuicao
                          .map(
                            (e) => PieChartSectionData(
                              value: e.horas,
                              color: e.cor,
                              radius: 20,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: d.distribuicao.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: e.cor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.nome,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.horas.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.percentual.toInt()}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: e.cor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Evolução 12 semanas ──────────────────────

  Widget _buildEvolucao(DashboardData d) {
    if (d.evolucao.isEmpty) return const SizedBox.shrink();

    // Inverte para mostrar do mais antigo ao mais recente
    final semanas = d.evolucao.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao('Evolução — últimas 12 semanas', null),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: _C.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= semanas.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % 3 != 0) return const SizedBox.shrink();
                          return Text(
                            'S${semanas[idx].semana + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: _C.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        semanas.length,
                        (i) => FlSpot(i.toDouble(), semanas[i].indice),
                      ),
                      isCurved: true,
                      color: _C.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _C.primaryDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 8, height: 2, color: _C.primary),
                const SizedBox(width: 4),
                const Text(
                  'Índice de consistência',
                  style: TextStyle(fontSize: 10, color: _C.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Estado de erro ───────────────────────────

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: _C.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Não foi possível carregar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique sua conexão e tente novamente.',
              style: TextStyle(fontSize: 13, color: _C.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _carregarDados,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de UI ────────────────────────────

  Color _corIndice(double valor) {
    if (valor >= 80) return _C.success;
    if (valor >= 50) return _C.warning;
    return _C.danger;
  }

  Widget _tituloSecao(String titulo, String? subtitulo) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (subtitulo != null)
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: _C.textSecondary),
          ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Painter do arco do índice
// ─────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double valor;
  final Color cor;
  final Color corFundo;

  const _ArcPainter({
    required this.valor,
    required this.cor,
    required this.corFundo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.width / 2 - 12;
    const espessura = 12.0;
    const inicio = -math.pi * 0.75;
    const total = math.pi * 1.5;

    final paintFundo = Paint()
      ..color = corFundo
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      inicio,
      total,
      false,
      paintFundo,
    );

    if (valor > 0) {
      final paintValor = Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio),
        inicio,
        total * valor,
        false,
        paintValor,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.valor != valor || old.cor != cor;
}