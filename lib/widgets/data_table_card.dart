import 'package:flutter/material.dart';
import '../theme/theme_helper.dart';

/// Widget reutilizable para mostrar tablas de datos con estilos consistentes
/// Maneja automáticamente header, filas, loading y estados vacíos
class DataTableCard extends StatelessWidget {
  /// Columnas de la tabla con: ancho, acmenoetiqueta
  final List<DataTableColumn> columns;

  /// Número de filas a mostrar
  final int rowCount;

  /// Builder para construir cada fila
  final Widget Function(BuildContext context, int rowIndex) rowBuilder;

  /// Si true, muestra loading indicator
  final bool isLoading;

  /// Si true, muestra estado vacío
  final bool isEmpty;

  /// Icono a mostrar cuando está vacío
  final IconData? emptyIcon;

  /// Mensaje a mostrar cuando está vacío
  final String? emptyMessage;

  /// Color alternativo para filas pares (para mejor legibilidad)
  final bool alternateRowColors;

  const DataTableCard({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyIcon,
    this.emptyMessage,
    this.alternateRowColors = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emptyIcon != null)
                  Icon(emptyIcon, size: 48, color: ThemeHelper.getBorderColor(context)),
                if (emptyIcon != null) const SizedBox(height: 12),
                if (emptyMessage != null)
                  Text(
                    emptyMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeHelper.getTextLightColor(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: rowCount,
              itemBuilder: (context, index) {
                return Container(
                  color: alternateRowColors && index % 2 != 0
                      ? ThemeHelper.getAltRowColor(context)
                      : Colors.transparent,
                  child: rowBuilder(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeHelper.getBorderColor(context))),
      ),
      child: Row(
        children: columns.map((col) {
          final labelWidget = Text(
            col.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextLightColor(context),
            ),
          );
          if (col.width == null) {
            return Expanded(flex: col.flex ?? 1, child: labelWidget);
          }
          return SizedBox(width: col.width, child: labelWidget);
        }).toList(),
      ),
    );
  }
}

/// Definición de una columna en la tabla
class DataTableColumn {
  /// Etiqueta del header
  final String label;

  /// Ancho fijo de la columna (si es null, usa flex)
  final double? width;

  /// Factor flex cuando no hay ancho fijo
  final int? flex;

  const DataTableColumn({required this.label, this.width, this.flex = 1});
}
