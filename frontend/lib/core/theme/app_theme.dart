/// Design tokens globais do app Focus.
///
/// Este arquivo centraliza cores, tipografia, raios, espacamentos e helpers de
/// apresentacao. As classes `AgendaColors` e `AgendaLabels` continuam
/// disponiveis como camada de compatibilidade para as telas ja existentes.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Cores globais
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // Marca e navegacao
  static const Color brandPrimary = Color(0xFF6366F1);
  static const Color brandPrimaryDark = Color(0xFF4F46E5);
  static const Color sidebarBackground = Color(0xFF1E1B4B);
  static const Color sidebarBorder = Color(0xFF312E81);
  static const Color sidebarTextMuted = Color(0xFF94A3B8);

  // Texto
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textInverted = Color(0xFFFFFFFF);

  // Superficies e bordas
  static const Color appBackground = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F5);
  static const Color surfaceSubtle = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderSubtle = Color(0xFFE5E7EB);

  // Feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color successSoft = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningStrong = Color(0xFFF9A825);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSoft = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
  static const Color neutral = Color(0xFF9E9E9E);
  static const Color neutralSoft = Color(0xFFBDBDBD);

  // Disciplinas e dados
  static const Color subjectIndigo = Color(0xFF5C6BC0);
  static const Color subjectTeal = Color(0xFF009688);
  static const Color subjectOrange = Color(0xFFFF7043);
  static const Color subjectPink = Color(0xFFEC407A);
  static const Color subjectPurple = Color(0xFF7E57C2);

  // Recomendacoes
  static const Color recommendationBackground = Color(0xFFFFF8E1);
  static const Color recommendationBorder = Color(0xFFFFE082);
  static const Color recommendationIcon = Color(0xFFF9A825);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient consistencyHeader = LinearGradient(
    colors: [AppColors.subjectIndigo, Color(0xFF3F51B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reportsHeader = LinearGradient(
    colors: [AppColors.subjectTeal, AppColors.success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient settingsHeader = LinearGradient(
    colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ---------------------------------------------------------------------------
// Espacamentos, raios e dimensoes
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets listHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets sectionTitle = EdgeInsets.fromLTRB(lg, xxl, lg, sm);
}

class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}

class AppSizes {
  AppSizes._();

  static const double sidebarWidth = 220;
  static const double desktopBreakpoint = 900;
  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconLg = 24;
  static const double avatarSm = 17;
  static const double avatarLg = 32;
}

// ---------------------------------------------------------------------------
// Tipografia
// ---------------------------------------------------------------------------

class AppTypography {
  AppTypography._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}

// ---------------------------------------------------------------------------
// Labels e formatadores globais
// ---------------------------------------------------------------------------

class AppLabels {
  AppLabels._();

  static String tipoEventoAcademico(String? tipo) {
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

  static String statusSessaoEstudo(String? status) {
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

  static String diasRestantes(int? dias) {
    if (dias == null) return '';
    if (dias < 0) return 'Atrasado';
    if (dias == 0) return 'Hoje';
    if (dias == 1) return 'Amanhã';
    return 'Em $dias dias';
  }

  static const List<String> meses = [
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

  static const List<String> diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

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
    final mes = meses[data.month - 1];

    if (diff == 0) return 'Hoje, $dia de $mes';
    if (diff == 1) return 'Amanhã, $dia de $mes';
    if (diff == -1) return 'Ontem, $dia de $mes';

    final diaSemana = diasSemana[data.weekday - 1];
    return '$diaSemana, $dia de $mes';
  }
}

// ---------------------------------------------------------------------------
// Compatibilidade com tokens do modulo Agenda
// ---------------------------------------------------------------------------

class AgendaColors {
  AgendaColors._();

  static const Color urgenciaAtrasado = AppColors.danger;
  static const Color urgenciaAlta = AppColors.dangerSoft;
  static const Color urgenciaMedia = AppColors.warning;
  static const Color urgenciaBaixa = AppColors.info;

  static const Color statusAgendado = AppColors.subjectIndigo;
  static const Color statusEmAndamento = AppColors.successSoft;
  static const Color statusConcluido = AppColors.neutral;
  static const Color statusCancelado = AppColors.neutralSoft;

  static const Color recomendacaoBg = AppColors.recommendationBackground;
  static const Color recomendacaoBorder = AppColors.recommendationBorder;
  static const Color recomendacaoIcon = AppColors.recommendationIcon;

  static const Color cardBackground = AppColors.surface;
  static const Color dateHeaderBg = AppColors.surfaceMuted;
  static const Color timelineConnector = AppColors.border;

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

class AgendaLabels {
  AgendaLabels._();

  static String tipoEvento(String? tipo) {
    return AppLabels.tipoEventoAcademico(tipo);
  }

  static String statusSessao(String? status) {
    return AppLabels.statusSessaoEstudo(status);
  }

  static String diasRestantes(int? dias) {
    return AppLabels.diasRestantes(dias);
  }

  static String formatarCabecalhoData(String dataIso) {
    return AppLabels.formatarCabecalhoData(dataIso);
  }
}
