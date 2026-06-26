import 'package:flutter/material.dart';

/// Fila reutilizable para mostrar resumen de totales (subtotal, descuento, total)
/// en la vista previa de facturas y cotizaciones.
class DocumentSummaryRow extends StatelessWidget {
  final String label;
  final String formattedAmount;
  final bool isDiscount;
  final bool isTotal;
  final Color textColor;

  const DocumentSummaryRow({
    super.key,
    required this.label,
    required this.formattedAmount,
    required this.textColor,
    this.isDiscount = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDiscount ? const Color(0xFFE24B4A) : textColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: effectiveColor,
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
