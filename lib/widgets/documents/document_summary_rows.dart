import 'package:flutter/material.dart';

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

class TaxToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  final String? formattedAmount;

  const TaxToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
    this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: color,
              side: BorderSide(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 11, color: color)),
          ),
          if (value && formattedAmount != null)
            Text(
              formattedAmount!,
              style: TextStyle(fontSize: 11, color: color),
            ),
        ],
      ),
    );
  }
}
