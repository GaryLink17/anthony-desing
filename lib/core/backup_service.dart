import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_selector/file_selector.dart';
import 'app_exception.dart';
import 'database.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Copia la BD a una carpeta elegida por el usuario.
  /// Retorna la ruta del archivo creado, o null si el usuario canceló.
  Future<String?> exportBackup() async {
    final dbDir = await getDatabasesPath();
    final sourcePath = p.join(dbDir, 'control_gastos.db');
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const AppException('No se encontró la base de datos para respaldar.');
    }

    final String? selectedDir = await getDirectoryPath(
      confirmButtonText: 'Guardar aquí',
    );
    if (selectedDir == null) return null;

    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';
    final destPath = p.join(selectedDir, 'respaldo_$stamp.db');

    try {
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      throw AppException('No se pudo guardar el respaldo.', technical: e.toString());
    }
  }

  /// El usuario elige un archivo .db, se cierra la BD actual,
  /// se reemplaza en disco y se reabre.
  /// Retorna true en éxito, null si el usuario canceló.
  Future<bool?> restoreBackup() async {
    const typeGroup = XTypeGroup(label: 'Base de datos', extensions: ['db']);
    final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked == null) return null;

    final sourceFile = File(picked.path);
    if (!await sourceFile.exists()) {
      throw const AppException('El archivo seleccionado no existe.');
    }
    if (await sourceFile.length() < 100) {
      throw const AppException('El archivo no parece ser una base de datos válida.');
    }

    final dbDir = await getDatabasesPath();
    final destPath = p.join(dbDir, 'control_gastos.db');

    // Copia de seguridad automática antes de sobreescribir
    final currentDb = File(destPath);
    final safetyPath = p.join(dbDir, 'control_gastos_pre_restore.db');
    if (await currentDb.exists()) {
      await currentDb.copy(safetyPath);
    }

    await DatabaseHelper.closeAndReset();

    try {
      await sourceFile.copy(destPath);
    } catch (e) {
      // Rollback
      if (await File(safetyPath).exists()) {
        await File(safetyPath).copy(destPath);
        await DatabaseHelper.closeAndReset();
      }
      throw AppException('No se pudo restaurar la base de datos.', technical: e.toString());
    }

    try {
      await DatabaseHelper.instance.database;
    } catch (e) {
      throw AppException(
        'La base de datos fue reemplazada pero no se pudo abrir. Reinicia la aplicación.',
        technical: e.toString(),
      );
    }

    return true;
  }
}
