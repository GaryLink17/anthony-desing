import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/core/database.dart';
import 'package:inventario_y_facturacion/core/invoice_repository.dart';
import 'package:inventario_y_facturacion/core/product_repository.dart';
import 'package:inventario_y_facturacion/models/invoice.dart';
import 'package:inventario_y_facturacion/models/invoice_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductRepository productRepository;
  late InvoiceRepository invoiceRepository;

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          return '.';
        });
    await DatabaseHelper.initialize();
    productRepository = ProductRepository();
    invoiceRepository = InvoiceRepository();
  });

  test('save y update preservan customerRnc y paymentStatus', () async {
    final productId = await productRepository.insertRaw(
      name: 'Producto Test Repo',
      category: 'Test',
      purchasePrice: 10,
      salePrice: 30,
      stock: 100,
      minStock: 5,
    );

    final created = Invoice(
      customerName: 'Cliente Repo',
      customerRnc: '101010101',
      subtotal: 30,
      discountGlobal: 0,
      itbis: 5.4,
      isr: 0,
      total: 35.4,
      paymentStatus: 'paid',
      createdAt: DateTime.now().toIso8601String(),
    );

    final item = InvoiceItem(
      invoiceId: 0,
      productId: productId,
      productName: 'Producto Test Repo',
      quantity: 1,
      unitPrice: 30,
      subtotal: 30,
    );

    final invoiceId = await invoiceRepository.save(created, [item]);
    final saved = await invoiceRepository.getById(invoiceId);
    expect(saved, isNotNull);
    expect(saved!.customerRnc, '101010101');
    expect(saved.paymentStatus, 'paid');

    final updated = saved.copyWith(
      subtotal: 60,
      total: 70.8,
      itbis: 10.8,
      customerRnc: '202020202',
      paymentStatus: 'pending',
    );
    final updatedItem = InvoiceItem(
      invoiceId: invoiceId,
      productId: productId,
      productName: 'Producto Test Repo',
      quantity: 2,
      unitPrice: 30,
      subtotal: 60,
    );

    await invoiceRepository.update(updated, [updatedItem]);
    final reloaded = await invoiceRepository.getById(invoiceId);
    expect(reloaded, isNotNull);
    expect(reloaded!.customerRnc, '202020202');
    expect(reloaded.paymentStatus, 'pending');
  });
}
