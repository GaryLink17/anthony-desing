import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helper.dart';

/// Barra de paginación reutilizable con navegación entre páginas,
/// números de página visibles (máximo 5 a la vez) y total de items.
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPageChanged,
  });

  /// Retorna las páginas visibles (máximo 5) centradas en la página actual.
  List<int> _visiblePages() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i);
    }
    if (currentPage <= 2) {
      return [0, 1, 2, 3, 4];
    }
    if (currentPage >= totalPages - 3) {
      return [
        totalPages - 5,
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
      ];
    }
    return [
      currentPage - 2,
      currentPage - 1,
      currentPage,
      currentPage + 1,
      currentPage + 2,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border.all(
          color: ThemeHelper.getBorderColor(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavButton(
                context,
                icon: Icons.chevron_left_rounded,
                onTap: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 4),
              ..._visiblePages().map((p) => _buildPageButton(context, p)),
              const SizedBox(width: 4),
              _buildNavButton(
                context,
                icon: Icons.chevron_right_rounded,
                onTap: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Página ${currentPage + 1} de $totalPages — $totalItems items',
            style: TextStyle(
              fontSize: 11,
              color: ThemeHelper.getTextLightColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ThemeHelper.getBorderColor(context)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null
                ? ThemeHelper.getTextMediumColor(context)
                : ThemeHelper.getBorderColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final isActive = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () => onPageChanged(page),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accentMagenta : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive
                  ? null
                  : Border.all(color: ThemeHelper.getBorderColor(context)),
            ),
            child: Text(
              '${page + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? Colors.white
                    : ThemeHelper.getTextMediumColor(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
