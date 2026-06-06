/// Card unificado para exibir um item de agenda.
///
/// Renderiza variações visuais conforme [AgendaItem.tipo]:
/// - `EVENTO_ACADEMICO` → barra de urgência, badge de tipo com ícone, dias restantes.
/// - `SESSAO_ESTUDO`    → barra de status, horário início/fim, duração.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import '../screens/criar_evento_screen.dart';
import '../screens/criar_sessao_screen.dart';
import '../services/evento_service.dart';
import '../services/sessao_estudo_service.dart';

class AgendaItemCard extends StatelessWidget {
  final AgendaItem item;
  final bool isCompact;

  const AgendaItemCard({
    super.key,
    required this.item,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isConcluido =
        (item.isEvento && item.concluido == true) ||
        (item.isSessao && item.status == 'CONCLUIDO');

    final cardContent = isCompact
        ? _buildCompactCard(context, isConcluido)
        : _buildNormalCard(context, isConcluido);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarOpcoesCard(context),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        child: cardContent,
      ),
    );
  }

  Widget _buildNormalCard(BuildContext context, bool isConcluido) {
    return Opacity(
      opacity: isConcluido ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AgendaColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra lateral colorida ──────────────────────────────
                Container(
                  width: 5,
                  color: _barColor(),
                ),
                // ── Conteúdo ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: item.isEvento
                        ? _buildEvento(context)
                        : _buildSessao(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoesCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  item.isEvento ? 'Opções do Evento' : 'Opções da Sessão',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text(item.isEvento ? 'Editar Evento' : 'Editar Sessão'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  bool? atualizado;
                  if (item.isEvento) {
                    atualizado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CriarEventoScreen(eventoExistente: item),
                      ),
                    );
                  } else {
                    atualizado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CriarSessaoScreen(sessaoExistente: item),
                      ),
                    );
                  }
                  if (atualizado == true && context.mounted) {
                    context.read<AgendaProvider>().fetchAgenda();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(item.isEvento ? 'Excluir Evento' : 'Excluir Sessão'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: Text(item.isEvento ? 'Excluir Evento' : 'Excluir Sessão'),
                        content: const Text('Tem certeza que deseja excluir este item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('CANCELAR'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text(
                              'EXCLUIR',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmar == true && context.mounted) {
                    try {
                      if (item.isEvento) {
                        await EventoService().excluirEvento(item.id);
                      } else {
                        await SessaoEstudoService().excluirSessao(item.id);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(item.isEvento
                                ? 'Evento excluído com sucesso!'
                                : 'Sessão excluída com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        context.read<AgendaProvider>().fetchAgenda();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao excluir item: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // Variação — COMPACTA (para Calendário Semanal)
  // =========================================================================

  Widget _buildCompactCard(BuildContext context, bool isConcluido) {
    final theme = Theme.of(context);
    final cor = _barColor();

    return Opacity(
      opacity: isConcluido ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: cor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isSessao && item.inicio != null && item.fim != null) ...[
              Text(
                '${_formatTime(item.inicio!)} – ${_formatTime(item.fim!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
            ] else if (item.isEvento && item.horaInicio != null) ...[
              Text(
                '${item.horaInicio!}${item.horaFim != null ? ' – ${item.horaFim!}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              item.titulo,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.disciplinaNome.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                item.disciplinaNome,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Variação — EVENTO_ACADEMICO
  // =========================================================================

  Widget _buildEvento(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    IconData iconData;
    String labelIcon = '';
    switch (item.tipoEvento) {
      case 'PROVA':
        iconData = Icons.edit_note;
        labelIcon = '📝';
        break;
      case 'TRABALHO':
        iconData = Icons.description;
        labelIcon = '📄';
        break;
      case 'SEMINARIO':
        iconData = Icons.groups;
        labelIcon = '📌';
        break;
      case 'APRESENTACAO':
        iconData = Icons.co_present;
        labelIcon = '🎤';
        break;
      default:
        iconData = Icons.assignment;
        labelIcon = '📋';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: badge de tipo + dias restantes
        Row(
          children: [
            _badge(
              label: '$labelIcon ${AgendaLabels.tipoEvento(item.tipoEvento)}',
              color: _barColor(),
            ),
            const Spacer(),
            if (item.horaInicio != null) ...[
              Text(
                '${item.horaInicio!}${item.horaFim != null ? ' – ${item.horaFim!}' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (item.diasRestantes != null)
              Text(
                AgendaLabels.diasRestantes(item.diasRestantes),
                style: textTheme.bodySmall?.copyWith(
                  color: _barColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Título com ícone correspondente
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, size: 20, color: _barColor()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.titulo,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Disciplina
        if (item.disciplinaNome.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              item.disciplinaNome,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],

        // Descrição
        if (item.descricao != null && item.descricao!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              item.descricao!,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // Indicador de concluído
        if (item.concluido == true) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Concluído',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // Variação — SESSAO_ESTUDO
  // =========================================================================

  Widget _buildSessao(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: badge de status + horário
        Row(
          children: [
            _badge(
              label: '📚 ${AgendaLabels.statusSessao(item.status)}',
              color: _barColor(),
            ),
            const Spacer(),
            if (item.inicio != null && item.fim != null)
              Text(
                '${_formatTime(item.inicio!)} – ${_formatTime(item.fim!)}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Título
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.menu_book, size: 20, color: _barColor()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.titulo,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Disciplina
        if (item.disciplinaNome.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              item.disciplinaNome,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],

        // Descrição
        if (item.descricao != null && item.descricao!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              item.descricao!,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // Duração realizada (se concluído)
        if (item.status == 'CONCLUIDO' && item.duracaoRealizada != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Foco: ${item.duracaoRealizada} min',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // Helpers privados
  // =========================================================================

  Color _barColor() {
    if (item.isEvento) return AgendaColors.corPorUrgencia(item.urgencia);
    return AgendaColors.corPorStatus(item.status);
  }

  /// Badge compacta colorida com texto.
  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Formata um [DateTime] como `HH:mm`.
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
