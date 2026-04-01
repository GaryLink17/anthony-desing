import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

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
    SidebarItem(label: 'Dashboard', icon: Icons.grid_view_rounded),      // 0
    SidebarItem(label: 'Facturas', icon: Icons.receipt_long_rounded),    // 1
    SidebarItem(label: 'Cotizaciones', icon: Icons.description_rounded), // 2
    SidebarItem(label: 'Inventario', icon: Icons.inventory_2_rounded),   // 3
  ];

  static const _analysisItems = [
    SidebarItem(label: 'Reportes', icon: Icons.bar_chart_rounded),  // 5
    SidebarItem(label: 'Historial', icon: Icons.history_rounded),   // 6
  ];

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isCollapsed ? 60.0 : 210.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSidebarColor : AppTheme.primaryBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: isDark
            ? Border(
                right: BorderSide(
                  color: AppTheme.darkBorderColor.withOpacity(0.6),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCollapsed) _buildHeader(context),
          _buildGroup(
            context,
            'Principal',
            _mainItems,
            startIndex: 0,
            isCollapsed: isCollapsed,
          ),
          _buildGroup(
            context,
            'Análisis',
            _analysisItems,
            startIndex: 4,
            isCollapsed: isCollapsed,
          ),
          const Spacer(),
          _buildGroup(
            context,
            'Sistema',
            const [
              SidebarItem(label: 'Configuración', icon: Icons.settings_rounded),
            ],
            startIndex: 6,
            isCollapsed: isCollapsed,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final logoPath = provider.companyLogo;
    final name = provider.companyName;
    final phone = provider.companyPhone;

    // Iniciales del negocio para mostrar si no hay logo
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            // Logo o iniciales
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: logoPath != null && File(logoPath).existsSync()
                  ? Image.file(File(logoPath), fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initials.isEmpty ? 'NB' : initials,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlue,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.lightBlue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String label,
    List<SidebarItem> items, {
    required int startIndex,
    bool isCollapsed = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final index = startIndex + entry.key;
          final item = entry.value;
          final isActive = selectedIndex == index;
          return _buildNavItem(
            context,
            item,
            index,
            isActive,
            isCollapsed: isCollapsed,
            sectionName: isCollapsed ? label : null,
          );
        }),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    SidebarItem item,
    int index,
    bool isActive, {
    bool isCollapsed = false,
    String? sectionName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltipMessage = sectionName != null
        ? '$sectionName - ${item.label}'
        : item.label;

    final activeBorderColor =
        isDark ? AppTheme.accentMagenta : Colors.white;
    final activeBgColor = isDark
        ? AppTheme.accentMagenta.withOpacity(0.12)
        : Colors.white.withOpacity(0.10);
    final activeIconColor = Colors.white;
    final inactiveIconColor =
        isDark ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.55);
    final activeTextColor = Colors.white;
    final inactiveTextColor =
        isDark ? Colors.white.withOpacity(0.55) : Colors.white.withOpacity(0.65);

    if (isCollapsed) {
      return Tooltip(
        message: tooltipMessage,
        showDuration: const Duration(seconds: 2),
        child: InkWell(
          onTap: () => onItemSelected(index),
          child: Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? activeBgColor : Colors.transparent,
              border: isActive
                  ? Border(
                      left: BorderSide(color: activeBorderColor, width: 3),
                    )
                  : null,
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(color: activeBorderColor, width: 3),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  fontSize: 12,
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
                  color: AppTheme.accentMagenta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.badgeCount}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
