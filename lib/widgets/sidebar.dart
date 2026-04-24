import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../core/trial_config.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final int? badgeCount;

  const SidebarItem({required this.label, required this.icon, this.badgeCount});
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
  });

  static const _mainItems = [
    SidebarItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
    SidebarItem(label: 'Facturas', icon: Icons.receipt_long_rounded),
    SidebarItem(label: 'Cotizaciones', icon: Icons.description_rounded),
    SidebarItem(label: 'Inventario', icon: Icons.inventory_2_rounded),
  ];

  static const _analysisItems = [
    SidebarItem(label: 'Reportes', icon: Icons.bar_chart_rounded),
    SidebarItem(label: 'Historial', icon: Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isCollapsed ? 60.0 : 216.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSidebarColor : AppTheme.sidebarLight,
        border: Border(
          right: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.sidebarBorderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCollapsed) _buildHeader(context, isDark),
          if (isCollapsed) const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGroup(
                    context,
                    isDark,
                    'Principal',
                    _mainItems,
                    startIndex: 0,
                  ),
                  _buildGroup(
                    context,
                    isDark,
                    'Análisis',
                    _analysisItems,
                    startIndex: 4,
                  ),
                ],
              ),
            ),
          ),
          _buildGroup(
            context,
            isDark,
            'Sistema',
            const [
              SidebarItem(
                label: 'Configuración',
                icon: Icons.settings_rounded,
              ),
            ],
            startIndex: 6,
          ),
          if (TrialConfig.isTrialVersion && !isCollapsed) _buildTrialBadge(isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTrialBadge(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.accentMagenta.withValues(alpha: 0.10)
            : AppTheme.accentMagenta.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentMagenta.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: AppTheme.accentMagenta.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Versión de prueba',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.accentMagenta.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final provider = context.watch<AppProvider>();
    final logoPath = provider.companyLogo;
    final name = provider.companyName;
    final phone = provider.companyPhone;

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.sidebarBorderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accentMagenta.withValues(alpha: 0.15)
                  : AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoPath != null && File(logoPath).existsSync()
                ? Image.file(File(logoPath), fit: BoxFit.cover)
                : Center(
                    child: Text(
                      initials.isEmpty ? 'NB' : initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.accentMagenta
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextLight
                        : AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppTheme.darkTextMedium
                          : AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    bool isDark,
    String label,
    List<SidebarItem> items, {
    required int startIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextMedium.withValues(alpha: 0.5)
                    : AppTheme.textLighter,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final index = startIndex + entry.key;
          final item = entry.value;
          final isActive = selectedIndex == index;
          return _buildNavItem(
            context,
            isDark,
            item,
            index,
            isActive,
          );
        }),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    bool isDark,
    SidebarItem item,
    int index,
    bool isActive,
  ) {
    // Colores según tema
    final activeIconColor =
        isDark ? AppTheme.accentMagenta : AppTheme.primaryBlue;
    final inactiveIconColor = isDark
        ? AppTheme.darkTextMedium
        : AppTheme.textLight;
    final activeTextColor = isDark ? AppTheme.darkTextLight : AppTheme.textDark;
    final inactiveTextColor = isDark
        ? AppTheme.darkTextMedium
        : AppTheme.textMedium;
    final activeBg = isDark
        ? AppTheme.accentMagenta.withValues(alpha: 0.10)
        : AppTheme.primaryBlue.withValues(alpha: 0.07);

    if (isCollapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: InkWell(
          onTap: () => onItemSelected(index),
          child: Container(
            width: 60,
            height: 46,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: isActive ? activeIconColor : inactiveIconColor,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 17,
              color: isActive ? activeIconColor : inactiveIconColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
              ),
            ),
            if (item.badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.badgeCount}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMagenta,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
