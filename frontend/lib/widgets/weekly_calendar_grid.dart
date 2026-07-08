import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import '../screens/criar_evento_screen.dart';
import '../screens/criar_sessao_screen.dart';
import '../services/evento_service.dart';
import '../services/sessao_estudo_service.dart';

class WeeklyCalendarGrid extends StatelessWidget {
  const WeeklyCalendarGrid({super.key});

  static const double _hourHeight = 72;
  static const double _hourColumnWidth = 64;
  static const double _minDayWidth = 148;
  static const int _gridStartHour = 6;
  static const int _gridEndHour = 23;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final weekStart = provider.inicioDaSemanaFocal;
    final weekEnd = provider.fimDaSemanaFocal;
    final days = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSizes.desktopBreakpoint;
        return Column(
          children: [
            _CalendarToolbar(
              weekStart: weekStart,
              weekEnd: weekEnd,
              provider: provider,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? AppSpacing.xl : AppSpacing.md,
                  AppSpacing.md,
                  isWide ? AppSpacing.xl : AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWide) ...[
                      SizedBox(
                        width: 272,
                        child: _CalendarSidebar(provider: provider),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                    ],
                    Expanded(
                      child: DecoratedBox(
                        decoration: AppDecorations.card(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: _WeekGrid(days: days, provider: provider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isWide)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _FilterStrip(provider: provider),
              ),
          ],
        );
      },
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final AgendaProvider provider;

  const _CalendarToolbar({
    required this.weekStart,
    required this.weekEnd,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: provider.irParaHoje,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Hoje'),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconControl(
            tooltip: 'Semana anterior',
            icon: Icons.chevron_left_rounded,
            onPressed: provider.retrocederSemana,
          ),
          _IconControl(
            tooltip: 'Proxima semana',
            icon: Icons.chevron_right_rounded,
            onPressed: provider.avancarSemana,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              _formatWeekRange(weekStart, weekEnd),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_view_week_rounded,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Semana',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
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

class _IconControl extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _IconControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.surfaceMuted,
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}

class _CalendarSidebar extends StatelessWidget {
  final AgendaProvider provider;

  const _CalendarSidebar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.card(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MiniMonth(provider: provider),
            const SizedBox(height: AppSpacing.xl),
            _FilterStrip(provider: provider),
            const SizedBox(height: AppSpacing.xl),
            _CalendarLegend(),
          ],
        ),
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final AgendaProvider provider;

  const _MiniMonth({required this.provider});

  @override
  Widget build(BuildContext context) {
    final focus = provider.dataFocal;
    final firstDay = DateTime(focus.year, focus.month, 1);
    final visibleStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final selectedWeekStart = provider.inicioDaSemanaFocal;
    final selectedWeekEnd = provider.fimDaSemanaFocal;
    final itemDates = provider.itensFiltrados
        .map((item) => DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day))
        .toSet();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_monthName(focus.month)} ${focus.year}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _TinyIconButton(
              icon: Icons.chevron_left_rounded,
              onPressed: provider.retrocederMes,
              tooltip: 'Mes anterior',
            ),
            _TinyIconButton(
              icon: Icons.chevron_right_rounded,
              onPressed: provider.avancarMes,
              tooltip: 'Proximo mes',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            _MiniWeekday('S'),
            _MiniWeekday('T'),
            _MiniWeekday('Q'),
            _MiniWeekday('Q'),
            _MiniWeekday('S'),
            _MiniWeekday('S'),
            _MiniWeekday('D'),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemBuilder: (context, index) {
            final day = visibleStart.add(Duration(days: index));
            final inMonth = day.month == focus.month;
            final isSelected = _isSameDay(day, focus);
            final inSelectedWeek =
                !day.isBefore(selectedWeekStart) && !day.isAfter(selectedWeekEnd);
            final hasItem = itemDates.any((date) => _isSameDay(date, day));

            return InkWell(
              onTap: () => provider.selecionarData(day),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : inSelectedWeek
                          ? AppColors.brandPrimary.withValues(alpha: 0.08)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textInverted
                            : inMonth
                                ? AppColors.textSecondary
                                : AppColors.textMuted.withValues(alpha: 0.55),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (hasItem)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.textInverted
                                : AppColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniWeekday extends StatelessWidget {
  final String label;

  const _MiniWeekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _TinyIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(32, 32),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final AgendaProvider provider;

  const _FilterStrip({required this.provider});

  static const _filters = [
    {'key': 'TODOS', 'label': 'Todos'},
    {'key': 'EVENTOS', 'label': 'Eventos'},
    {'key': 'SESSOES', 'label': 'Sessoes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _filters.map((filter) {
        final key = filter['key']!;
        final label = filter['label']!;
        final selected = provider.selectedFilter == key;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => provider.setFilter(key),
          selectedColor: AppColors.brandPrimary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: selected ? AppColors.brandPrimary : AppColors.borderSubtle,
          ),
          labelStyle: TextStyle(
            color: selected ? AppColors.textInverted : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Legenda',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _LegendItem(color: AgendaColors.statusAgendado, label: 'Sessao agendada'),
        _LegendItem(color: AgendaColors.statusEmAndamento, label: 'Em andamento'),
        _LegendItem(color: AgendaColors.urgenciaAlta, label: 'Evento importante'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  final List<DateTime> days;
  final AgendaProvider provider;

  const _WeekGrid({required this.days, required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalHours = WeeklyCalendarGrid._gridEndHour - WeeklyCalendarGrid._gridStartHour;
    final gridHeight = totalHours * WeeklyCalendarGrid._hourHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - WeeklyCalendarGrid._hourColumnWidth,
        );
        final dayWidth = math.max(
          WeeklyCalendarGrid._minDayWidth,
          availableWidth / 7,
        );
        final calendarWidth = WeeklyCalendarGrid._hourColumnWidth + dayWidth * 7;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: calendarWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: WeeklyCalendarGrid._hourColumnWidth),
                      ...days.map((day) => _DayHeader(day: day, width: dayWidth)),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AllDayLabelCell(),
                      ...days.map((day) {
                        final items = _itemsForDay(day, provider.itensDaSemanaFocal);
                        final allDay = items
                            .where((item) => item.isEvento && item.horaInicio == null)
                            .toList();
                        return _AllDayCell(width: dayWidth, items: allDay);
                      }),
                    ],
                  ),
                  SizedBox(
                    height: gridHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HourLabels(height: gridHeight),
                        ...days.map((day) {
                          final items = _itemsForDay(day, provider.itensDaSemanaFocal);
                          final timed = items
                              .where((item) =>
                                  item.isSessao ||
                                  (item.isEvento && item.horaInicio != null))
                              .toList()
                            ..sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));
                          return _DayColumn(
                            width: dayWidth,
                            height: gridHeight,
                            items: timed,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final double width;

  const _DayHeader({required this.day, required this.width});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(day, DateTime.now());
    return Container(
      width: width,
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.borderSubtle),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayName(day.weekday),
            style: TextStyle(
              color: isToday ? AppColors.brandPrimary : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.brandPrimary.withValues(alpha: 0.14) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? AppColors.brandPrimary : AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDayLabelCell extends StatelessWidget {
  const _AllDayLabelCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WeeklyCalendarGrid._hourColumnWidth,
      height: 58,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: const Text(
        'Dia',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AllDayCell extends StatelessWidget {
  final double width;
  final List<AgendaItem> items;

  const _AllDayCell({required this.width, required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items.take(2).toList();
    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.borderSubtle),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _AllDayPill(item: item),
            ),
          if (items.length > 2)
            Text(
              '+${items.length - 2} eventos',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDayPill extends StatelessWidget {
  final AgendaItem item;

  const _AllDayPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _itemColor(item);
    return InkWell(
      onTap: () => _showItemDetails(context, item),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          item.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HourLabels extends StatelessWidget {
  final double height;

  const _HourLabels({required this.height});

  @override
  Widget build(BuildContext context) {
    final totalHours = WeeklyCalendarGrid._gridEndHour - WeeklyCalendarGrid._gridStartHour;
    return Container(
      width: WeeklyCalendarGrid._hourColumnWidth,
      height: height,
      color: AppColors.surface,
      child: Stack(
        children: List.generate(totalHours + 1, (index) {
          final hour = WeeklyCalendarGrid._gridStartHour + index;
          return Positioned(
            top: math.max(0.0, index * WeeklyCalendarGrid._hourHeight - 9),
            right: AppSpacing.sm,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final double width;
  final double height;
  final List<AgendaItem> items;

  const _DayColumn({
    required this.width,
    required this.height,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = WeeklyCalendarGrid._gridEndHour - WeeklyCalendarGrid._gridStartHour;
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Stack(
        children: [
          ...List.generate(totalHours, (index) {
            return Positioned(
              top: index * WeeklyCalendarGrid._hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: WeeklyCalendarGrid._hourHeight,
                decoration: BoxDecoration(
                  color: index.isEven
                      ? AppColors.surface
                      : AppColors.surfaceMuted.withValues(alpha: 0.28),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderSubtle.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ),
            );
          }),
          ...items.map((item) {
            final minutesStart = _startMinutes(item);
            final minutesEnd = _endMinutes(item);
            final top = ((minutesStart - WeeklyCalendarGrid._gridStartHour * 60) / 60) *
                WeeklyCalendarGrid._hourHeight;
            final bottom = ((minutesEnd - WeeklyCalendarGrid._gridStartHour * 60) / 60) *
                WeeklyCalendarGrid._hourHeight;
            final clampedTop = top.clamp(0.0, height).toDouble();
            final clampedBottom = bottom.clamp(0.0, height).toDouble();
            final eventHeight = math.max(42.0, clampedBottom - clampedTop);

            if (clampedTop >= height || clampedBottom <= 0) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: clampedTop,
              left: 7,
              right: 7,
              height: eventHeight,
              child: _CalendarEventBlock(item: item),
            );
          }),
        ],
      ),
    );
  }
}

class _CalendarEventBlock extends StatelessWidget {
  final AgendaItem item;

  const _CalendarEventBlock({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _itemColor(item);
    final isDone =
        (item.isSessao && item.status == 'CONCLUIDO') ||
        (item.isEvento && item.concluido == true);
    return Opacity(
      opacity: isDone ? 0.58 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetails(context, item),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(alpha: 0.12),
                AppColors.surface,
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: color.withValues(alpha: 0.22)),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _AdaptiveEventContent(
                        item: item,
                        color: color,
                        availableHeight: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveEventContent extends StatelessWidget {
  final AgendaItem item;
  final Color color;
  final double availableHeight;

  const _AdaptiveEventContent({
    required this.item,
    required this.color,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (availableHeight <= 18) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          item.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (availableHeight <= 38) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timeLabel(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _timeLabel(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.titulo,
          maxLines: availableHeight > 68 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (availableHeight > 74 && item.disciplinaNome.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.disciplinaNome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _showItemDetails(BuildContext context, AgendaItem item) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheetContext) {
      final color = _itemColor(item);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      item.isSessao
                          ? Icons.menu_book_rounded
                          : Icons.event_note_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titulo,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.isSessao
                              ? AgendaLabels.statusSessao(item.status)
                              : AgendaLabels.tipoEvento(item.tipoEvento),
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailLine(
                icon: Icons.schedule_rounded,
                label: _timeLabel(item),
              ),
              if (item.disciplinaNome.isNotEmpty)
                _DetailLine(
                  icon: Icons.school_rounded,
                  label: item.disciplinaNome,
                ),
              if (item.descricao != null && item.descricao!.isNotEmpty)
                _DetailLine(
                  icon: Icons.notes_rounded,
                  label: item.descricao!,
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        bool? updated;
                        if (item.isEvento) {
                          updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CriarEventoScreen(eventoExistente: item),
                            ),
                          );
                        } else {
                          updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CriarSessaoScreen(sessaoExistente: item),
                            ),
                          );
                        }
                        if (updated == true && context.mounted) {
                          context.read<AgendaProvider>().fetchAgenda();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _deleteItem(context, item);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _deleteItem(BuildContext context, AgendaItem item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(item.isEvento ? 'Excluir evento' : 'Excluir sessao'),
        content: const Text('Tem certeza que deseja excluir este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  try {
    if (item.isEvento) {
      await EventoService().excluirEvento(item.id);
    } else {
      await SessaoEstudoService().excluirSessao(item.id);
    }
    if (context.mounted) {
      context.read<AgendaProvider>().fetchAgenda();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item.isEvento ? 'Evento excluido.' : 'Sessao excluida.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir item: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

List<AgendaItem> _itemsForDay(DateTime day, List<AgendaItem> items) {
  return items.where((item) {
    final date = item.timestamp;
    return date.year == day.year && date.month == day.month && date.day == day.day;
  }).toList();
}

Color _itemColor(AgendaItem item) {
  if (item.isEvento) return AgendaColors.corPorUrgencia(item.urgencia);
  return AgendaColors.corPorStatus(item.status);
}

int _startMinutes(AgendaItem item) {
  if (item.isSessao && item.inicio != null) {
    return item.inicio!.hour * 60 + item.inicio!.minute;
  }
  if (item.horaInicio != null) {
    final parts = item.horaInicio!.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  return WeeklyCalendarGrid._gridStartHour * 60;
}

int _endMinutes(AgendaItem item) {
  if (item.isSessao && item.fim != null) {
    return item.fim!.hour * 60 + item.fim!.minute;
  }
  if (item.horaFim != null) {
    final parts = item.horaFim!.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  return _startMinutes(item) + 60;
}

String _timeLabel(AgendaItem item) {
  if (item.isSessao && item.inicio != null && item.fim != null) {
    return '${_formatTime(item.inicio!)} - ${_formatTime(item.fim!)}';
  }
  if (item.horaInicio != null) {
    return item.horaFim == null
        ? item.horaInicio!
        : '${item.horaInicio!} - ${item.horaFim!}';
  }
  return 'Dia inteiro';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _formatWeekRange(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return '${start.day} a ${end.day} de ${_monthName(start.month)}, ${start.year}';
  }
  return '${start.day} de ${_monthName(start.month)} a '
      '${end.day} de ${_monthName(end.month)}, ${end.year}';
}

String _monthName(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return months[month - 1];
}

String _weekdayName(int weekday) {
  const names = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  return names[weekday - 1];
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
