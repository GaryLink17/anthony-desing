import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../models/invoice.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final Invoice invoice;

  const InvoicePreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: PdfPreview(
              build: (_) => pdfBytes,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName:
                  'factura_${invoice.id.toString().padLeft(4, '0')}.pdf',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.07), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            color: const Color(0xFF444441),
            tooltip: 'Volver',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          Text(
            'Vista previa — Factura #${invoice.id.toString().padLeft(4, '0')}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const Spacer(),
          // Botón imprimir
          ElevatedButton.icon(
            onPressed: () async {
              await Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Botón guardar PDF
          OutlinedButton.icon(
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    'factura_${invoice.id.toString().padLeft(4, '0')}.pdf',
              );
            },
            icon: const Icon(Icons.save_alt_rounded, size: 16),
            label: const Text('Guardar PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
