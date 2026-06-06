import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import 'agenda_item_card.dart';

class WeeklyCalendarGrid extends StatelessWidget {
  const WeeklyCalendarGrid({super.key});

  static const double hourHeight = 60.0;
  static const int gridStartHour = 7; // Começa às 07:00
  static const int gridEndHour = 22; // Termina às 22:00
  static const double columnWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final inicioSemana = provider.inicioDaSemanaFocal;
    final fimSemana = provider.fimDaSemanaFocal;
    final itens = provider.itensDaSemanaFocal;

    // Gerar a lista de 7 dias da semana focal (Segunda a Domingo)
    final diasSemana = List.generate(7, (index) {
      return inicioSemana.add(Duration(days: index));
    });

    final totalHoras = gridEndHour - gridStartHour + 1;
    final gridHeight = totalHoras * hourHeight;

    return Column(
      children: [
        // 1. Cabeçalho de Navegação da Semana
        _buildNavigationHeader(context, provider, inicioSemana, fimSemana),

        // 2. Calendário e Grade
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Coluna Fixa de Horários (Esquerda)
                  _buildHourLabelsColumn(totalHoras),

                  // Área de Scroll Horizontal contendo a grade de 7 dias
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: diasSemana.map((dia) {
                            final diaIso = _formatarDataIso(dia);
                            final itensDoDia = itens.where((i) => i.data == diaIso).toList();
                            
                            // Separar eventos de dia inteiro e compromissos com horário
                            final eventosSemHorario = itensDoDia.where((i) => i.isEvento && i.horaInicio == null).toList();
                            final itensComHorario = itensDoDia.where((i) => i.isSessao || (i.isEvento && i.horaInicio != null)).toList();

                            final isHoje = _isMesmoDia(dia, DateTime.now());

                            return Container(
                              width: columnWidth,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Cabeçalho do Dia (ex: Seg \n 01)
                                  _buildDayHeader(context, dia, isHoje),

                                  // Área de Eventos do Dia (All-day events, empilhados)
                                  _buildAllDayEventsSection(context, eventosSemHorario),

                                  // Grade de Horários com as Sessões de Estudo Posicionadas
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        // Linhas de Grade de Fundo
                                        ...List.generate(totalHoras, (index) {
                                          return Positioned(
                                            top: index * hourHeight,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: hourHeight,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[150] ?? Colors.grey[200]!,
                                                    width: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),

                                        // Itens Posicionados no Horário
                                        ...itensComHorario.map((item) {
                                          return _buildPositionedItem(context, item, gridHeight);
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Widgets Auxiliares
  // =========================================================================

  /// Cabeçalho superior de controle e navegação temporal.
  Widget _buildNavigationHeader(
    BuildContext context,
    AgendaProvider provider,
    DateTime inicio,
    DateTime fim,
  ) {
    final theme = Theme.of(context);
    final textoPeriodo = _formatarPeriodoSemanal(inicio, fim);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botões de Voltar / Hoje / Avançar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: provider.retrocederSemana,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: provider.irParaHoje,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Hoje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: provider.avancarSemana,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),

          // Texto do Período
          Text(
            textoPeriodo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Coluna de rótulos de horas (ex: 08:00, 09:00...)
  Widget _buildHourLabelsColumn(int totalHoras) {
    return Container(
      width: 50.0,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Espaço correspondente ao cabeçalho de dia e seção de eventos
          const SizedBox(height: 106.0),
          Expanded(
            child: Stack(
              children: List.generate(totalHoras, (index) {
                final hora = gridStartHour + index;
                return Positioned(
                  top: (index * hourHeight) - 8.0, // Ajusta o alinhamento central com a linha
                  left: 0,
                  right: 8,
                  child: Text(
                    '${hora.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
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

  /// Cabeçalho com o dia da semana e o número (ex: Seg \n 01)
  Widget _buildDayHeader(BuildContext context, DateTime dia, bool isHoje) {
    final theme = Theme.of(context);
    final diasSemanaNomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final nomeDia = diasSemanaNomes[dia.weekday - 1];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      color: isHoje ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
      child: Column(
        children: [
          Text(
            nomeDia,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHoje ? theme.colorScheme.primary : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHoje ? theme.colorScheme.primary : Colors.transparent,
            ),
            child: Text(
              dia.day.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHoje ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Área reservada para renderizar eventos de dia inteiro no topo da coluna do dia.
  Widget _buildAllDayEventsSection(BuildContext context, List<AgendaItem> eventos) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46.0),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: eventos.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Sem eventos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                )
              ]
            : eventos.map((ev) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: AgendaItemCard(item: ev, isCompact: true),
                );
              }).toList(),
      ),
    );
  }

  /// Posiciona a Sessão de Estudo ou Evento com Horário dinamicamente no grid.
  Widget _buildPositionedItem(BuildContext context, AgendaItem item, double maxGridHeight) {
    int hourInicio = 0;
    int minuteInicio = 0;
    int hourFim = 23;
    int minuteFim = 59;

    if (item.isSessao) {
      if (item.inicio == null || item.fim == null) {
        return const SizedBox.shrink();
      }
      hourInicio = item.inicio!.hour;
      minuteInicio = item.inicio!.minute;
      hourFim = item.fim!.hour;
      minuteFim = item.fim!.minute;
    } else {
      if (item.horaInicio == null) {
        return const SizedBox.shrink();
      }
      final partsInicio = item.horaInicio!.split(':');
      hourInicio = int.parse(partsInicio[0]);
      minuteInicio = int.parse(partsInicio[1]);

      if (item.horaFim != null) {
        final partsFim = item.horaFim!.split(':');
        hourFim = int.parse(partsFim[0]);
        minuteFim = int.parse(partsFim[1]);
      } else {
        // Se não houver hora_fim, definimos a duração padrão de 1 hora
        hourFim = hourInicio + 1;
        minuteFim = minuteInicio;
        if (hourFim > 23) {
          hourFim = 23;
          minuteFim = 59;
        }
      }
    }

    // Minutos desde o início da grade (gridStartHour)
    final minutosInicio = (hourInicio - gridStartHour) * 60 + minuteInicio;
    final minutosFim = (hourFim - gridStartHour) * 60 + minuteFim;

    // Calcular top e height proporcional
    final top = (minutosInicio / 60.0) * hourHeight;
    final bottom = (minutosFim / 60.0) * hourHeight;
    
    double height = bottom - top;

    // Limites de segurança
    if (top < 0) {
      return const SizedBox.shrink(); // Começa antes de gridStartHour
    }
    if (top >= maxGridHeight) {
      return const SizedBox.shrink(); // Começa depois de gridEndHour
    }

    // Garantir altura mínima de 24px para manter títulos legíveis em sessões muito curtas
    if (height < 24.0) {
      height = 24.0;
    }

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: AgendaItemCard(item: item, isCompact: true),
    );
  }

  // =========================================================================
  // Métodos Utilitários de Data
  // =========================================================================

  /// Retorna data no formato ISO `YYYY-MM-DD`.
  String _formatarDataIso(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Verifica se duas datas são do mesmo dia/mês/ano.
  bool _isMesmoDia(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Retorna o texto formatado do período semanal (ex: "01/Jun a 07/Jun").
  String _formatarPeriodoSemanal(DateTime inicio, DateTime fim) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final diaInicio = inicio.day.toString().padLeft(2, '0');
    final mesInicio = meses[inicio.month - 1];
    final diaFim = fim.day.toString().padLeft(2, '0');
    final mesFim = meses[fim.month - 1];
    final ano = inicio.year;

    if (inicio.month == fim.month) {
      return '$diaInicio a $diaFim de $mesInicio, $ano';
    } else {
      return '$diaInicio/$mesInicio a $diaFim/$mesFim, $ano';
    }
  }
}
