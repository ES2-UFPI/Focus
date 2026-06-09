import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AppPage { visaoGeral, cicloEstudos, atividades, materiais, consistencia, relatorios, configuracoes }

class AppSidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageChanged;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1e1b4b),
        border: Border(right: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildItem(context, AppPage.visaoGeral, LucideIcons.layoutDashboard, 'Visão Geral'),
                _buildItem(context, AppPage.cicloEstudos, LucideIcons.repeat2, 'Ciclo de Estudos'),
                _buildItem(context, AppPage.atividades, LucideIcons.clipboardList, 'Atividades'),
                _buildItem(context, AppPage.materiais, LucideIcons.bookOpen, 'Materiais'),
                _buildItem(context, AppPage.consistencia, LucideIcons.barChart2, 'Consistência'),
                _buildItem(context, AppPage.relatorios, LucideIcons.fileText, 'Relatórios'),
                _buildItem(context, AppPage.configuracoes, LucideIcons.settings, 'Configurações'),
              ],
            ),
          ),
          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.zap, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Focus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, AppPage page, IconData icon, String label) {
    final isSelected = currentPage == page;
    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366f1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94a3b8), size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94a3b8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6366f1),
            child: const Text('D', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Diogo Silva', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Ver perfil', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
