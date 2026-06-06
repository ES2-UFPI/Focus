/// Definições de tema, cores e utilitários visuais para a Agenda Acadêmica.
///
/// Centraliza as paletas de cor de urgência (eventos) e status (sessões)
/// para manter a consistência visual em todos os widgets da feature.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Paleta de cores — Urgência (Eventos Acadêmicos)
// ---------------------------------------------------------------------------

class AgendaColors {
  AgendaColors._();

  // Urgência
  static const Color urgenciaAtrasado = Color(0xFFE53935); // vermelho forte
  static const Color urgenciaAlta = Color(0xFFEF5350); // vermelho
  static const Color urgenciaMedia = Color(0xFFFFA726); // âmbar
  static const Color urgenciaBaixa = Color(0xFF42A5F5); // azul

  // Status da sessão
  static const Color statusAgendado = Color(0xFF5C6BC0); // indigo
  static const Color statusEmAndamento = Color(0xFF66BB6A); // verde
  static const Color statusConcluido = Color(0xFF9E9E9E); // cinza
  static const Color statusCancelado = Color(0xFFBDBDBD); // cinza claro

  // Recomendações
  static const Color recomendacaoBg = Color(0xFFFFF8E1); // âmbar muito claro
  static const Color recomendacaoBorder = Color(0xFFFFE082); // âmbar claro
  static const Color recomendacaoIcon = Color(0xFFF9A825); // âmbar escuro

  // Superfícies
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dateHeaderBg = Color(0xFFF5F5F5);
  static const Color timelineConnector = Color(0xFFE0E0E0);

  /// Retorna a cor da barra lateral esquerda conforme a urgência do evento.
  static Color corPorUrgencia(String? urgencia) {
    switch (urgencia) {
      case 'ATRASADO':
        return urgenciaAtrasado;
      case 'ALTA':
        return urgenciaAlta;
      case 'MEDIA':
        return urgenciaMedia;
      case 'BAIXA':
        return urgenciaBaixa;
      default:
        return urgenciaBaixa;
    }
  }

  /// Retorna a cor da barra lateral esquerda conforme o status da sessão.
  static Color corPorStatus(String? status) {
    switch (status) {
      case 'AGENDADO':
        return statusAgendado;
      case 'EM_ANDAMENTO':
        return statusEmAndamento;
      case 'CONCLUIDO':
        return statusConcluido;
      case 'CANCELADO':
        return statusCancelado;
      default:
        return statusAgendado;
    }
  }
}

// ---------------------------------------------------------------------------
// Labels de apresentação
// ---------------------------------------------------------------------------

class AgendaLabels {
  AgendaLabels._();

  /// Rótulo legível para o tipo de evento acadêmico.
  static String tipoEvento(String? tipo) {
    switch (tipo) {
      case 'PROVA':
        return 'Prova';
      case 'TRABALHO':
        return 'Trabalho';
      case 'SEMINARIO':
        return 'Seminário';
      case 'APRESENTACAO':
        return 'Apresentação';
      case 'OUTRO':
        return 'Outro';
      default:
        return tipo ?? 'Evento';
    }
  }

  /// Rótulo legível para o status de uma sessão de estudo.
  static String statusSessao(String? status) {
    switch (status) {
      case 'AGENDADO':
        return 'Agendado';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status ?? '';
    }
  }

  /// Texto descritivo de dias restantes.
  static String diasRestantes(int? dias) {
    if (dias == null) return '';
    if (dias < 0) return 'Atrasado';
    if (dias == 0) return 'Hoje';
    if (dias == 1) return 'Amanhã';
    return 'Em $dias dias';
  }

  /// Nomes dos meses em Português.
  static const List<String> _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
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

  /// Nomes dos dias da semana em Português.
  static const List<String> _diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  /// Formata uma data ISO `YYYY-MM-DD` em um cabeçalho amigável.
  ///
  /// Exemplos: `"Hoje, 05 de Junho"`, `"Amanhã, 06 de Junho"`,
  /// `"Segunda-feira, 09 de Junho"`.
  static String formatarCabecalhoData(String dataIso) {
    final partes = dataIso.split('-');
    final data = DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );

    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final diff = data.difference(hojeSemHora).inDays;

    final dia = data.day.toString().padLeft(2, '0');
    final mes = _meses[data.month - 1];

    if (diff == 0) return 'Hoje, $dia de $mes';
    if (diff == 1) return 'Amanhã, $dia de $mes';
    if (diff == -1) return 'Ontem, $dia de $mes';

    // weekday: 1 = Monday … 7 = Sunday → índice 0-based
    final diaSemana = _diasSemana[data.weekday - 1];
    return '$diaSemana, $dia de $mes';
  }
}
