/// Widget de timeline cronológica para a Agenda Acadêmica.
///
/// Recebe os itens já agrupados por data (via [AgendaProvider.itensAgrupadosPorData])
/// e renderiza cabeçalhos de dia com uma linha de timeline conectando os cards.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import 'agenda_item_card.dart';

class AgendaTimeline extends StatelessWidget {
  /// Mapa ordenado cronologicamente: chave = data ISO `YYYY-MM-DD`,
  /// valor = lista de itens daquele dia.
  final Map<String, List<AgendaItem>> itensAgrupadosPorData;

  const AgendaTimeline({super.key, required this.itensAgrupadosPorData});

  @override
  Widget build(BuildContext context) {
    final datas = itensAgrupadosPorData.keys.toList();

    return ListView.builder(
      // Usado dentro de um NestedScrollView ou diretamente — desabilita
      // scroll próprio quando encapsulado em outro scrollable.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: datas.length,
      itemBuilder: (context, index) {
        final dataKey = datas[index];
        final itens = itensAgrupadosPorData[dataKey]!;

        return _DayGroup(
          dataIso: dataKey,
          itens: itens,
          isLast: index == datas.length - 1,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grupo de um dia (cabeçalho + cards com linha de timeline)
// ---------------------------------------------------------------------------

class _DayGroup extends StatelessWidget {
  final String dataIso;
  final List<AgendaItem> itens;
  final bool isLast;

  const _DayGroup({
    required this.dataIso,
    required this.itens,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho de data ───────────────────────────────────────────
          _DateHeader(dataIso: dataIso),
          const SizedBox(height: 4),

          // ── Timeline de itens ───────────────────────────────────────────
          ...List.generate(itens.length, (i) {
            return _TimelineRow(
              item: itens[i],
              isLastInGroup: i == itens.length - 1 && isLast,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho de data formatado
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  final String dataIso;

  const _DateHeader({required this.dataIso});

  @override
  Widget build(BuildContext context) {
    final label = AgendaLabels.formatarCabecalhoData(dataIso);
    final isHoje = label.startsWith('Hoje');

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHoje
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
              : AgendaColors.dateHeaderBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isHoje
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linha individual da timeline (dot + conector vertical + card)
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  final AgendaItem item;
  final bool isLastInGroup;

  const _TimelineRow({
    required this.item,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Coluna da timeline (dot + linha vertical) ──────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isEvento
                        ? AgendaColors.corPorUrgencia(item.urgencia)
                        : AgendaColors.corPorStatus(item.status),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (item.isEvento
                                ? AgendaColors.corPorUrgencia(item.urgencia)
                                : AgendaColors.corPorStatus(item.status))
                            .withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Conector vertical
                if (!isLastInGroup)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AgendaColors.timelineConnector,
                    ),
                  ),
                if (isLastInGroup) const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // ── Card do item ──────────────────────────────────────────────
          Expanded(child: AgendaItemCard(item: item)),
        ],
      ),
    );
  }
}
