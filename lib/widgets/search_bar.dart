import 'package:flutter/material.dart';

/// Widget reutilizable para búsqueda con opciones de filtrado
class SearchBar extends StatefulWidget {
  /// Callback cuando el texto de búsqueda cambia
  final ValueChanged<String> onChanged;

  /// Placeholder del campo de búsqueda
  final String hintText;

  /// Icono a mostrar antes del campo
  final IconData? prefixIcon;

  /// Callback cuando se presiona el botón de buscar
  final VoidCallback? onSearchPressed;

  /// Lista de filtros disponibles (ej: ["Activos", "Inactivos"])
  final List<String>? filterOptions;

  /// Callback cuando se selecciona un filtro
  final ValueChanged<String>? onFilterChanged;

  /// Opciones de ordenamiento (ej: ["A-Z", "Más reciente"])
  final List<String>? sortOptions;

  /// Callback cuando se selecciona ordenamiento
  final ValueChanged<String>? onSortChanged;

  /// Mostrar botones de filtro y ordenamiento
  final bool showAdvancedOptions;

  const SearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Buscar...',
    this.prefixIcon = Icons.search_rounded,
    this.onSearchPressed,
    this.filterOptions,
    this.onFilterChanged,
    this.sortOptions,
    this.onSortChanged,
    this.showAdvancedOptions = true,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  String? _selectedFilter;
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de búsqueda principal
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.07),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: const Color(0xFFB4B2A9),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB4B2A9),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              // Botón limpiar búsqueda
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFFB4B2A9),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Opciones avanzadas (filtros y ordenamiento)
        if (widget.showAdvancedOptions &&
            (widget.filterOptions != null || widget.sortOptions != null))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                // Selector de filtro
                if (widget.filterOptions != null &&
                    widget.filterOptions!.isNotEmpty)
                  Expanded(
                    child: _buildFilterButton(
                      'Filtrar',
                      Icons.filter_list_rounded,
                      widget.filterOptions!,
                      _selectedFilter,
                      (value) {
                        setState(() => _selectedFilter = value);
                        widget.onFilterChanged?.call(value);
                      },
                    ),
                  ),
                if (widget.filterOptions != null &&
                    widget.filterOptions!.isNotEmpty)
                  const SizedBox(width: 8),
                // Selector de ordenamiento
                if (widget.sortOptions != null &&
                    widget.sortOptions!.isNotEmpty)
                  Expanded(
                    child: _buildFilterButton(
                      'Ordenar',
                      Icons.sort_rounded,
                      widget.sortOptions!,
                      _selectedSort,
                      (value) {
                        setState(() => _selectedSort = value);
                        widget.onSortChanged?.call(value);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterButton(
    String label,
    IconData icon,
    List<String> options,
    String? selected,
    ValueChanged<String> onSelect,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelect,
        position: PopupMenuPosition.under,
        itemBuilder: (context) => options
            .map(
              (option) => PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (selected == option)
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFFE8147A),
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              ),
            )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected != null
                    ? const Color(0xFFE8147A)
                    : const Color(0xFFB4B2A9),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected != null
                      ? const Color(0xFFE8147A)
                      : const Color(0xFFB4B2A9),
                  fontWeight: selected != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
              if (selected != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8147A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    selected,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE8147A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
