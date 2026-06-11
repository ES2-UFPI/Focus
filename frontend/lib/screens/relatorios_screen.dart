import 'package:flutter/material.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Paleta de cores para gráficos
    final graficos = [
      {'dia': 'Seg', 'horas': 2.5, 'color': const Color(0xFF4CAF50)},
      {'dia': 'Ter', 'horas': 4.0, 'color': const Color(0xFF4CAF50)},
      {'dia': 'Qua', 'horas': 1.5, 'color': const Color(0xFF81C784)},
      {'dia': 'Qui', 'horas': 3.0, 'color': const Color(0xFF4CAF50)},
      {'dia': 'Sex', 'horas': 5.5, 'color': const Color(0xFF2E7D32)},
      {'dia': 'Sáb', 'horas': 0.0, 'color': Colors.grey[300]!},
      {'dia': 'Dom', 'horas': 1.0, 'color': const Color(0xFF81C784)},
    ];

    final totalHoras = graficos.fold<double>(0, (sum, item) => sum + (item['horas'] as double));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Estilizado
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Desempenho Acadêmico',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                  fontSize: 20,
                  shadows: const [
                    Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Icon(
                      Icons.analytics_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // KPIs superiores (cards)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context: context,
                      titulo: 'Tempo de Estudo',
                      valor: '${totalHoras}h',
                      detalhe: 'Nesta semana',
                      icon: Icons.timer,
                      color: const Color(0xFF009688),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context: context,
                      titulo: 'Foco Diário',
                      valor: '2.5h',
                      detalhe: 'Meta: 3.0h',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Gráfico de Barras Mockado com Containers
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribuição de Horas de Estudo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resumo diário do tempo de foco nas disciplinas.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 32),
                    // Grade do Gráfico
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: graficos.map((item) {
                        final horas = item['horas'] as double;
                        final altura = horas * 24.0; // Fator de escala
                        final cor = item['color'] as Color;

                        return Column(
                          children: [
                            Text(
                              horas > 0 ? '${horas}h' : '-',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: horas > 0 ? Colors.grey[700] : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 24,
                              height: altura > 0 ? altura : 6,
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['dia'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Painel de Insights Acadêmicos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                    child: Text(
                      'Recomendações de Performance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  _buildInsightItem(
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    titulo: 'Você bateu 75% da meta',
                    descricao: 'Ótimo ritmo em Cálculo Diferencial. Mantenha a consistência para a prova de sexta-feira.',
                  ),
                  const SizedBox(height: 10),
                  _buildInsightItem(
                    icon: Icons.lightbulb_outline_rounded,
                    color: Colors.orange,
                    titulo: 'Foco na matéria Banco de Dados',
                    descricao: 'Você estudou apenas 1.5 horas de Banco de Dados nesta semana. Considere agendar uma nova sessão.',
                  ),
                ],
              ),
            ),
          ),

          // Espaço adicional
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String titulo,
    required String valor,
    required String detalhe,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detalhe,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String titulo,
    required String descricao,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
