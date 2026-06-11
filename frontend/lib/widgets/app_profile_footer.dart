import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppProfileFooter extends StatelessWidget {
  final String name;
  final String caption;
  final String initials;
  final VoidCallback? onTap;

  const AppProfileFooter({
    super.key,
    required this.name,
    required this.caption,
    required this.initials,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF312e81))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF6366f1),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94a3b8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFF94a3b8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
