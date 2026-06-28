// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
//
// // ---------------------------------------------------------------------------
// // Mock data models (privados ao módulo)
// // ---------------------------------------------------------------------------
//
// class _DiaConsistencia {
//   final String abrev;
//   final String status; // 'ok', 'miss', 'partial'
//   final double horas;
//   const _DiaConsistencia(this.abrev, this.status, this.horas);
// }
//
// class _DistribuicaoDisciplina {
//   final String nome;
//   final double horas;
//   final Color cor;
//   const _DistribuicaoDisciplina(this.nome, this.horas, this.cor);
// }
//
// const _mockDias = [
//   _DiaConsistencia('Seg', 'ok', 2.5),
//   _DiaConsistencia('Ter', 'ok', 3.0),
//   _DiaConsistencia('Qua', 'ok', 1.5),
//   _DiaConsistencia('Qui', 'ok', 4.0),
//   _DiaConsistencia('Sex', 'miss', 0),
//   _DiaConsistencia('Sáb', 'ok', 5.5),
//   _DiaConsistencia('Dom', 'partial', 1.0),
// ];
//
// const _mockDistribuicao = [
//   _DistribuicaoDisciplina('Cálculo I', 6.5, Color(0xFF5C6BC0)),
//   _DistribuicaoDisciplina('Banco de Dados', 4.0, Color(0xFF009688)),
//   _DistribuicaoDisciplina('Física', 3.5, Color(0xFFFF7043)),
//   _DistribuicaoDisciplina('Prog. II', 2.0, Color(0xFFEC407A)),
//   _DistribuicaoDisciplina('IA', 1.5, Color(0xFF7E57C2)),
// ];
//
// const _mockIndice = 78;
// const _mockSessoes = 12;
// const _mockHoras = 17.5;
// const _mockDiasConsecutivos = 4;
//
// // ---------------------------------------------------------------------------
// // Tela
// // ---------------------------------------------------------------------------
//
// class ConsistenciaScreen extends StatefulWidget {
//   const ConsistenciaScreen({super.key});
//
//   @override
//   State<ConsistenciaScreen> createState() => _ConsistenciaScreenState();
// }
//
// class _ConsistenciaScreenState extends State<ConsistenciaScreen> {
//   DateTime _semanaRef = DateTime.now();
//
//   String get _textoPeriodo {
//     final inicio = _semanaRef.subtract(Duration(days: _semanaRef.weekday - 1));
//     final fim = inicio.add(const Duration(days: 6));
//     const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
//     final dI = inicio.day.toString().padLeft(2, '0');
//     final dF = fim.day.toString().padLeft(2, '0');
//     final mI = meses[inicio.month - 1];
//     final mF = meses[fim.month - 1];
//     if (inicio.month == fim.month) return '$dI–$dF de $mI';
//     return '$dI/$mI – $dF/$mF';
//   }
//
//   Color get _corIndice {
//     if (_mockIndice >= 80) return const Color(0xFF4CAF50);
//     if (_mockIndice >= 50) return const Color(0xFFFF9800);
//     return const Color(0xFFF44336);
//   }
//
//   String get _labelIndice {
//     if (_mockIndice >= 80) return 'Excelente';
//     if (_mockIndice >= 50) return 'Bom ritmo';
//     return 'Precisa melhorar';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F6FA),
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             pinned: true,
//             expandedHeight: 120,
//             flexibleSpace: FlexibleSpaceBar(
//               centerTitle: true,
//               title: const Text(
//                 'Consistência Semanal',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
//               ),
//               background: Container(
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//               ),
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.share_outlined, color: Colors.white),
//                 onPressed: () {},
//                 tooltip: 'Compartilhar',
//               ),
//             ],
//           ),
//
//           SliverToBoxAdapter(child: _buildWeekSelector(theme)),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//               child: _buildIndexCard(theme),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//               child: _buildMetricsRow(),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//               child: _buildDayConsistencyCard(theme),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//               child: _buildDistribuicaoCard(theme),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//               child: _buildDicaFocusCard(theme),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Seletor de semana
//   // -------------------------------------------------------------------------
//
//   Widget _buildWeekSelector(ThemeData theme) {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.chevron_left),
//             onPressed: () => setState(
//               () => _semanaRef = _semanaRef.subtract(const Duration(days: 7)),
//             ),
//             visualDensity: VisualDensity.compact,
//           ),
//           GestureDetector(
//             onTap: () => setState(() => _semanaRef = DateTime.now()),
//             child: Text(
//               _textoPeriodo,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.chevron_right),
//             onPressed: () => setState(
//               () => _semanaRef = _semanaRef.add(const Duration(days: 7)),
//             ),
//             visualDensity: VisualDensity.compact,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Card: Índice de Consistência
//   // -------------------------------------------------------------------------
//
//   Widget _buildIndexCard(ThemeData theme) {
//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Índice de Consistência',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
//           const SizedBox(height: 2),
//           Text('Baseado nas metas de horas semanais',
//               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
//           const SizedBox(height: 20),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   SizedBox(
//                     width: 110,
//                     height: 110,
//                     child: PieChart(
//                       PieChartData(
//                         startDegreeOffset: -90,
//                         sectionsSpace: 0,
//                         centerSpaceRadius: 36,
//                         sections: [
//                           PieChartSectionData(
//                             value: _mockIndice.toDouble(),
//                             color: _corIndice,
//                             radius: 20,
//                             showTitle: false,
//                           ),
//                           PieChartSectionData(
//                             value: (100 - _mockIndice).toDouble(),
//                             color: const Color(0xFFEEEEEE),
//                             radius: 20,
//                             showTitle: false,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         '$_mockIndice%',
//                         style: TextStyle(
//                             fontSize: 20, fontWeight: FontWeight.bold, color: _corIndice),
//                       ),
//                       Text('índice',
//                           style: TextStyle(fontSize: 10, color: Colors.grey[500])),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _labelIndice,
//                       style: TextStyle(
//                           fontSize: 18, fontWeight: FontWeight.bold, color: _corIndice),
//                     ),
//                     const SizedBox(height: 8),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(4),
//                       child: LinearProgressIndicator(
//                         value: _mockIndice / 100.0,
//                         minHeight: 8,
//                         backgroundColor: const Color(0xFFEEEEEE),
//                         valueColor: AlwaysStoppedAnimation(_corIndice),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Meta: 100% (${(_mockHoras / 0.78).toStringAsFixed(0)}h planejadas)',
//                       style: TextStyle(fontSize: 11, color: Colors.grey[500]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Cards de métricas
//   // -------------------------------------------------------------------------
//
//   Widget _buildMetricsRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: _metricCard(
//             icon: Icons.play_circle_outline_rounded,
//             color: const Color(0xFF5C6BC0),
//             valor: '$_mockSessoes',
//             label: 'Sessões',
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _metricCard(
//             icon: Icons.access_time_rounded,
//             color: const Color(0xFF009688),
//             valor: '${_mockHoras}h',
//             label: 'Horas de estudo',
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _metricCard(
//             icon: Icons.local_fire_department_rounded,
//             color: const Color(0xFFFF7043),
//             valor: '$_mockDiasConsecutivos',
//             label: 'Dias seguidos',
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _metricCard({
//     required IconData icon,
//     required Color color,
//     required String valor,
//     required String label,
//   }) {
//     return _card(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(height: 6),
//           Text(valor,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
//           const SizedBox(height: 2),
//           Text(label,
//               style: TextStyle(color: Colors.grey[500], fontSize: 10),
//               textAlign: TextAlign.center),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Card: Consistência por dia
//   // -------------------------------------------------------------------------
//
//   Widget _buildDayConsistencyCard(ThemeData theme) {
//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Consistência por Dia',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
//           const SizedBox(height: 14),
//           ..._mockDias.map(_buildDiaItem),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDiaItem(_DiaConsistencia d) {
//     final (IconData icon, Color color) = switch (d.status) {
//       'ok' => (Icons.check_circle_rounded, const Color(0xFF4CAF50)),
//       'miss' => (Icons.cancel_rounded, const Color(0xFFF44336)),
//       _ => (Icons.remove_circle_rounded, const Color(0xFFFF9800)),
//     };
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 10),
//           SizedBox(
//             width: 38,
//             child: Text(d.abrev,
//                 style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF374151))),
//           ),
//           Expanded(
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: (d.horas / 6.0).clamp(0.0, 1.0),
//                 minHeight: 8,
//                 backgroundColor: const Color(0xFFEEEEEE),
//                 valueColor: AlwaysStoppedAnimation(color),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 34,
//             child: Text(
//               d.horas > 0 ? '${d.horas}h' : '–',
//               style: TextStyle(color: Colors.grey[600], fontSize: 11),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Card: Distribuição por disciplina
//   // -------------------------------------------------------------------------
//
//   Widget _buildDistribuicaoCard(ThemeData theme) {
//     final total = _mockDistribuicao.fold<double>(0, (s, d) => s + d.horas);
//
//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Distribuição por Disciplina',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
//           const SizedBox(height: 2),
//           Text('${total}h registradas nesta semana',
//               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
//           const SizedBox(height: 16),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(
//                 width: 130,
//                 height: 130,
//                 child: PieChart(
//                   PieChartData(
//                     sectionsSpace: 2,
//                     centerSpaceRadius: 34,
//                     sections: _mockDistribuicao
//                         .map((d) => PieChartSectionData(
//                               value: d.horas,
//                               color: d.cor,
//                               radius: 28,
//                               showTitle: false,
//                             ))
//                         .toList(),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: _mockDistribuicao
//                       .map((d) => Padding(
//                             padding: const EdgeInsets.only(bottom: 7),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 10,
//                                   height: 10,
//                                   decoration: BoxDecoration(
//                                       color: d.cor, shape: BoxShape.circle),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Expanded(
//                                   child: Text(d.nome,
//                                       style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
//                                       overflow: TextOverflow.ellipsis),
//                                 ),
//                                 Text('${d.horas}h',
//                                     style: TextStyle(
//                                         fontSize: 11,
//                                         color: Colors.grey[600],
//                                         fontWeight: FontWeight.w600)),
//                               ],
//                             ),
//                           ))
//                       .toList(),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Card: Dica Focus
//   // -------------------------------------------------------------------------
//
//   Widget _buildDicaFocusCard(ThemeData theme) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFEEF2FF),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFC5CAE9)),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.lightbulb_outline_rounded,
//               color: Color(0xFF5C6BC0), size: 28),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Dica Focus',
//                     style: theme.textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF3F51B5))),
//                 const SizedBox(height: 4),
//                 const Text(
//                   'Distribuir sessões em blocos de 1–2h com intervalos melhora a retenção em até 40%. Evite acumular tudo nos fins de semana.',
//                   style: TextStyle(
//                       fontSize: 12, color: Color(0xFF5C6BC0), height: 1.4),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Helper: card base
//   // -------------------------------------------------------------------------
//
//   Widget _card({required Widget child, EdgeInsets? padding}) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       padding: padding ?? const EdgeInsets.all(16),
//       child: child,
//     );
//   }
// }

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

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
    _dashboardFuture = _apiService.getDashboardConsistencia(); // atribui direto
  }

  void _carregarDados() {
    setState(() {  // setState só é chamado quando o usuário atualiza
      _dashboardFuture = _apiService.getDashboardConsistencia();
    });
  }

  Color _getCorIndice(int valor) {
    if (valor >= 80) return const Color(0xFF4CAF50);
    if (valor >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getLabelIndice(int valor) {
    if (valor >= 80) return 'Excelente ritmo!';
    if (valor >= 50) return 'Bom desempenho!';
    return 'Precisa focar mais';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    _dashboardFuture = _apiService.getDashboardConsistencia();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<DashboardData?>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          // 1. Estado de Espera (Buscando no Django)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C6BC0)),
            );
          }

          // 2. Estado de Erro (Sem internet, Servidor Desligado ou Token Inválido)
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Não foi possível carregar seus indicadores de estudo.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _carregarDados,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
                    child: const Text('Tentar Novamente', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // 3. Sucesso! Dados prontos para renderização
          final dashboard = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _carregarDados(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: const Text(
                      'Consistência Semanal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildIndexCard(theme, dashboard),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMetricsRow(dashboard),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDayConsistencyCard(dashboard.diasConsistencia),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDistribuicaoCard(theme, dashboard.distribuicao, dashboard.horasEstudadas),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndexCard(ThemeData theme, DashboardData data) {
    final cor = _getCorIndice(data.indiceConsistencia);
    return _card(
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 34,
                    sections: [
                      PieChartSectionData(value: data.indiceConsistencia.toDouble(), color: cor, radius: 16, showTitle: false),
                      PieChartSectionData(value: (100 - data.indiceConsistencia).clamp(0, 100).toDouble(), color: const Color(0xFFEEEEEE), radius: 16, showTitle: false),
                    ],
                  ),
                ),
              ),
              Text('${data.indiceConsistencia}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getLabelIndice(data.indiceConsistencia), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.indiceConsistencia / 100.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation(cor),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Realizado: ${data.horasEstudadas.toStringAsFixed(1)}h de ${data.horasPlanejadas.toStringAsFixed(1)}h', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(child: _metricCard(icon: Icons.play_circle_outline, color: const Color(0xFF5C6BC0), valor: '${data.sessoesSemana}', label: 'Sessões')),
        const SizedBox(width: 8),
        Expanded(child: _metricCard(icon: Icons.access_time, color: const Color(0xFF009688), valor: '${data.horasEstudadas.toStringAsFixed(1)}h', label: 'Horas totais')),
        const SizedBox(width: 8),
        Expanded(child: _metricCard(icon: Icons.local_fire_department, color: const Color(0xFFFF7043), valor: '${data.streakDias}', label: 'Dias Seguidos')),
      ],
    );
  }

  Widget _buildDayConsistencyCard(List<DiaConsistenciaData> dias) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frequência de Estudo Diario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dias.map((d) {
              final fezEstudo = d.status == 'ok';
              return Column(
                children: [
                  Text(d.abrev, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Icon(
                    fezEstudo ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: fezEstudo ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                    size: 24,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDistribuicaoCard(ThemeData theme, List<DisciplinaData> dist, double totalHoras) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foco por Disciplina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          if (dist.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text('Nenhuma sessão computada para esta semana.', style: TextStyle(fontSize: 12, color: Colors.grey))),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections: dist.map((d) => PieChartSectionData(value: d.horas, color: d.cor, radius: 18, showTitle: false)).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: dist.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: d.cor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d.nome, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Text('${d.horas.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                  ),
                )
              ],
            )
        ],
      ),
    );
  }

  Widget _metricCard({required IconData icon, required Color color, required String valor, required String label}) {
    return _card(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );
  }
}