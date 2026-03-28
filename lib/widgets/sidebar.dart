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
    final sidebarWidth = isCollapsed ? 60.0 : 210.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      color: AppTheme.primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCollapsed) _buildHeader(context),
          _buildGroup(
            'Principal',
            _mainItems,
            startIndex: 0,
            isCollapsed: isCollapsed,
          ),
          _buildGroup(
            'Análisis',
            _analysisItems,
            startIndex: 4,
            isCollapsed: isCollapsed,
          ),
          const Spacer(),
          _buildGroup(
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
    SidebarItem item,
    int index,
    bool isActive, {
    bool isCollapsed = false,
    String? sectionName,
  }) {
    final tooltipMessage = sectionName != null
        ? '$sectionName - ${item.label}'
        : item.label;

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
              color: isActive
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
              border: isActive
                  ? const Border(
                      left: BorderSide(color: AppTheme.accentMagenta, width: 3),
                    )
                  : null,
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 20,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
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
          color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
          border: isActive
              ? const Border(
                  left: BorderSide(color: AppTheme.accentMagenta, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 17,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                ),
              ),
            ),
            if (item.badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.badgeCount}',
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
