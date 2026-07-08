import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

enum InsightFeedbackStatus { useful, rejected }

class InsightFeedbackState {
  final InsightFeedbackStatus status;
  final String? reason;

  const InsightFeedbackState({required this.status, this.reason});
}

class InsightFeedbackControl extends StatelessWidget {
  static const _reasons = [
    'Semana atípica',
    'Não concordo',
    'Já resolvi',
    'Pouco relevante',
  ];

  final String insightType;
  final InsightFeedbackState? feedback;
  final bool showReasons;
  final VoidCallback? onUseful;
  final VoidCallback? onNotUseful;
  final ValueChanged<String>? onSelectReason;
  final VoidCallback? onClear;

  const InsightFeedbackControl({
    super.key,
    required this.insightType,
    required this.feedback,
    required this.showReasons,
    this.onUseful,
    this.onNotUseful,
    this.onSelectReason,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (feedback?.status == InsightFeedbackStatus.useful) {
      return _FeedbackNotice(
        icon: LucideIcons.thumbsUp,
        message: 'Valeu! Vamos priorizar insights assim.',
        color: AppColors.success,
        onClear: onClear,
      );
    }

    if (feedback?.status == InsightFeedbackStatus.rejected) {
      final reason = feedback?.reason;
      return _FeedbackNotice(
        icon: LucideIcons.eyeOff,
        message: 'Marcado como não útil${reason == null ? '' : ' · $reason'}',
        color: AppColors.neutral,
        onClear: onClear,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.xxl, color: AppColors.borderSubtle),
        Row(
          children: [
            Expanded(
              child: Text(
                'Isso faz sentido pra você?',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tooltip(
              message: 'Sim, foi útil',
              child: Semantics(
                label: 'Marcar insight como útil',
                button: true,
                child: ShadButton.outline(
                  key: ValueKey('feedback-up-$insightType'),
                  size: ShadButtonSize.sm,
                  width: 34,
                  height: 30,
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColors.success,
                  onPressed: onUseful,
                  child: const Icon(LucideIcons.thumbsUp, size: 15),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: 'Não bateu',
              child: Semantics(
                label: 'Marcar insight como não útil',
                button: true,
                child: ShadButton.outline(
                  key: ValueKey('feedback-down-$insightType'),
                  size: ShadButtonSize.sm,
                  width: 34,
                  height: 30,
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColors.textMuted,
                  onPressed: onNotUseful,
                  child: const Icon(LucideIcons.thumbsDown, size: 15),
                ),
              ),
            ),
          ],
        ),
        if (showReasons) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O que não bateu?',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final reason in _reasons)
                ShadButton.outline(
                  key: ValueKey('feedback-reason-$insightType-$reason'),
                  size: ShadButtonSize.sm,
                  height: 30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  backgroundColor: AppColors.surface,
                  hoverBackgroundColor: AppColors.surfaceMuted,
                  pressedBackgroundColor: AppColors.surfaceSubtle,
                  foregroundColor: AppColors.textSecondary,
                  hoverForegroundColor: AppColors.textPrimary,
                  pressedForegroundColor: AppColors.textPrimary,
                  onPressed: () => onSelectReason?.call(reason),
                  child: Text(
                    reason,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FeedbackNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onClear;

  const _FeedbackNotice({
    required this.icon,
    required this.message,
    required this.color,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onClear != null)
          TextButton(onPressed: onClear, child: const Text('Desfazer')),
      ],
    );
  }
}
