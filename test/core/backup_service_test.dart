import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario_y_facturacion/core/database.dart';
import 'package:inventario_y_facturacion/core/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return Directory.systemTemp.path;
    });
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.initialize();
  });

  setUp(() async {
    final timeFile = File(p.join(Directory.systemTemp.path, '.last_backup_time'));
    if (await timeFile.exists()) {
      await timeFile.delete();
    }
  });

  test('exportBackup: closeAndReset + copy funciona en Windows', () async {
    await DatabaseHelper.instance.database;
    final dbPath = p.join(Directory.systemTemp.path, 'inventario.db');
    final sourceFile = File(dbPath);
    expect(await sourceFile.exists(), true, reason: 'La DB debe existir');

    await DatabaseHelper.closeAndReset();

    final destPath = p.join(Directory.systemTemp.path, 'respaldo_test.db');
    final destFile = File(destPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    await sourceFile.copy(destPath);

    expect(await destFile.exists(), true, reason: 'El backup debe existir');
    final sourceLen = await sourceFile.length();
    final destLen = await destFile.length();
    expect(destLen, equals(sourceLen),
        reason: 'Debe tener el mismo tamaño que el original');

    await destFile.delete();
  });

  test('_updateLastBackupTimeSync escribe timestamp que persiste al cerrar la app',
      () async {
    await BackupService.instance.initAutoBackupCache();

    final before = DateTime(2025, 1, 1).toIso8601String();
    final timeFile =
        File(p.join(Directory.systemTemp.path, '.last_backup_time'));
    await timeFile.writeAsString(before);

    BackupService.instance.performAutoBackupSync();

    final content = await timeFile.readAsString();
    expect(content, isNot(before), reason: 'Timestamp debe haber cambiado');

    final parsed = DateTime.tryParse(content);
    expect(parsed, isNotNull, reason: 'Debe ser una fecha válida');
  });

  test('_readLastBackupTimeSync lee timestamp escrito sincrónicamente', () async {
    await BackupService.instance.initAutoBackupCache();

    BackupService.instance.performAutoBackupSync();

    final timeFile =
        File(p.join(Directory.systemTemp.path, '.last_backup_time'));
    expect(await timeFile.exists(), true, reason: 'El archivo timestamp debe existir');

    final lastTime = await timeFile.readAsString();
    expect(lastTime.isNotEmpty, true, reason: 'Timestamp no debe estar vacío');
  });

  test('migración desde SharedPreferences al archivo funciona', () async {
    SharedPreferences.setMockInitialValues({
      'auto_backup_last_time': '2024-06-01T12:00:00.000',
    });

    await BackupService.instance.initAutoBackupCache();

    final settings = await BackupService.instance.getAutoBackupSettings();

    expect(settings['lastTime'], '2024-06-01T12:00:00.000',
        reason: 'Debe leer el timestamp migrado');

    final timeFile =
        File(p.join(Directory.systemTemp.path, '.last_backup_time'));
    expect(await timeFile.exists(), true,
        reason: 'Debe haber creado el archivo');
    final fileContent = await timeFile.readAsString();
    expect(fileContent, '2024-06-01T12:00:00.000',
        reason: 'El archivo debe contener el timestamp migrado');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('auto_backup_last_time'), false,
        reason: 'Debe eliminar la clave de SharedPreferences');
  });

  test('closeAndReset + database getter reabre la DB correctamente', () async {
    // 1. Inicializar DB
    final db = await DatabaseHelper.instance.database;
    expect(db, isNotNull, reason: 'La DB debe estar abierta');

    // 2. Hacer una operación para confirmar que funciona
    await db.execute('DROP TABLE IF EXISTS test_table');
    await db.execute('CREATE TABLE test_table (id INTEGER)');
    await db.insert('test_table', {'id': 1});

    // 3. Cerrar y resetear (como hace el backup)
    await DatabaseHelper.closeAndReset();

    // 4. Volver a acceder (esto fallaba porque _dbFuture devolvía la instancia cerrada)
    final reopened = await DatabaseHelper.instance.database;
    expect(reopened, isNotNull, reason: 'La DB debe reabrirse');

    // 5. Verificar que funciona (query real)
    final result = await reopened.query('test_table');
    expect(result.length, 1, reason: 'Los datos deben persistir');

    // 6. Limpiar
    await reopened.execute('DROP TABLE test_table');
  });
}
