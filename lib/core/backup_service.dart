import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_exception.dart';
import 'database.dart';

/// Servicio singleton para exportar e importar copias de seguridad
/// de la base de datos SQLite usando el selector de archivos nativo.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  // --- Claves SharedPreferences para backup automático ---
  static const String _keyAutoEnabled = 'auto_backup_enabled';
  static const String _keyAutoFrequency = 'auto_backup_frequency';
  static const String _keyAutoLastTime = 'auto_backup_last_time';
  static const String _keyAutoBackupPath = 'auto_backup_path';
  static const int maxAutoBackups = 10;

  // Caché en memoria para usar en AppLifecycleListener (donde no se puede await)
  bool _cachedEnabled = false;
  String _cachedFrequency = 'daily';
  String _cachedPath = '';
  String _cachedDbPath = '';
  String _lastBackupTimePath = '';

  /// Getter para la caché (usado desde AppLifecycleListener).
  bool get cachedEnabled => _cachedEnabled;
  String get cachedFrequency => _cachedFrequency;

  /// Inicializa la caché interna desde SharedPreferences.
  /// Debe llamarse una vez al iniciar la app.
  Future<void> initAutoBackupCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedEnabled = prefs.getBool(_keyAutoEnabled) ?? false;
    _cachedFrequency = prefs.getString(_keyAutoFrequency) ?? 'daily';
    _cachedPath = prefs.getString(_keyAutoBackupPath) ?? '';
    final appDir = await getApplicationSupportDirectory();
    _cachedDbPath = p.join(appDir.path, DatabaseHelper.dbName);
    _lastBackupTimePath = p.join(appDir.path, '.last_backup_time');
  }

  /// Lee la configuración de backup automático desde SharedPreferences.
  Future<Map<String, dynamic>> getAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrar timestamp desde SharedPreferences al archivo (solo la primera vez)
    String? lastTime = await _readLastBackupTime();
    if (lastTime == null) {
      lastTime = prefs.getString(_keyAutoLastTime);
      if (lastTime != null) {
        await File(_lastBackupTimePath).writeAsString(lastTime);
        await prefs.remove(_keyAutoLastTime);
      }
    }

    final settings = {
      'enabled': prefs.getBool(_keyAutoEnabled) ?? false,
      'frequency': prefs.getString(_keyAutoFrequency) ?? 'daily',
      'lastTime': lastTime,
      'path': prefs.getString(_keyAutoBackupPath),
    };
    // Actualizar caché
    _cachedEnabled = settings['enabled'] as bool;
    _cachedFrequency = settings['frequency'] as String;
    _cachedPath = (settings['path'] as String?) ?? '';
    if (_cachedDbPath.isEmpty) {
      final appDir = await getApplicationSupportDirectory();
      _cachedDbPath = p.join(appDir.path, DatabaseHelper.dbName);
    }
    return settings;
  }

  /// Guarda la configuración de backup automático en SharedPreferences.
  Future<void> saveAutoBackupSettings({
    required bool enabled,
    required String frequency,
    String? path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoEnabled, enabled);
    await prefs.setString(_keyAutoFrequency, frequency);
    if (path != null) {
      await prefs.setString(_keyAutoBackupPath, path);
    }
    _cachedEnabled = enabled;
    _cachedFrequency = frequency;
    if (path != null) _cachedPath = path;
  }

  /// Retorna el directorio donde se almacenan los backups automáticos.
  /// Usa la ruta personalizada si el usuario la configuró, si no la ruta por defecto.
  Future<Directory> getAutoBackupsFolder() async {
    final settings = await getAutoBackupSettings();
    final customPath = settings['path'] as String?;
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Abre un selector de carpeta para que el usuario elija dónde guardar los backups.
  /// Retorna la ruta seleccionada o null si canceló.
  Future<String?> pickAutoBackupFolder() async {
    final String? selectedDir = await getDirectoryPath(
      confirmButtonText: 'Seleccionar carpeta',
    );
    if (selectedDir == null) return null;
    return selectedDir;
  }

  /// Retorna la ruta actual de backups automáticos (personalizada o por defecto).
  Future<String> getAutoBackupPath() async {
    final settings = await getAutoBackupSettings();
    final customPath = settings['path'] as String?;
    if (customPath != null && customPath.isNotEmpty) return customPath;
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'backups');
  }

  /// Retorna la lista de archivos de backup automático ordenados del más reciente al más antiguo.
  Future<List<FileSystemEntity>> getExistingAutoBackups() async {
    final dir = await getAutoBackupsFolder();
    final files = await dir.list().where((entity) {
      return entity is File &&
          p.basename(entity.path).startsWith('auto_backup_');
    }).toList();
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }

  /// Retorna la fecha formateada del último backup automático o null si nunca se hizo.
  Future<String?> getLastAutoBackupTimeFormatted() async {
    final lastTime = await _readLastBackupTime();
    if (lastTime == null) return null;
    try {
      final dt = DateTime.parse(lastTime);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  /// Determina si debe ejecutarse un backup según la frecuencia configurada.
  Future<bool> shouldRunBackup({
    required bool enabled,
    required String frequency,
    String? lastTime,
  }) async {
    if (!enabled) return false;
    if (frequency == 'on_close') return false;
    if (lastTime == null) return true;

    try {
      final last = DateTime.parse(lastTime);
      final now = DateTime.now();
      switch (frequency) {
        case 'hourly':
          return now.difference(last).inHours >= 1;
        case 'daily':
          return now.difference(last).inHours >= 24;
        case 'weekly':
          return now.difference(last).inDays >= 7;
        default:
          return false;
      }
    } catch (_) {
      return true;
    }
  }

  /// Lee la marca de tiempo del último backup desde el archivo.
  Future<String?> _readLastBackupTime() async {
    if (_lastBackupTimePath.isEmpty) return null;
    final file = File(_lastBackupTimePath);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Actualiza la marca de tiempo del último backup automático.
  Future<void> _updateLastBackupTime() async {
    if (_lastBackupTimePath.isEmpty) return;
    final file = File(_lastBackupTimePath);
    await file.writeAsString(DateTime.now().toIso8601String());
  }

  /// Versión síncrona para usar al cerrar la app.
  void _updateLastBackupTimeSync() {
    if (_lastBackupTimePath.isEmpty) return;
    final file = File(_lastBackupTimePath);
    file.writeAsStringSync(DateTime.now().toIso8601String());
  }

  /// Realiza una copia de seguridad automática en la carpeta backups/.
  /// Usa checkpoint + copy para no interrumpir las operaciones de la BD.
  /// Retorna la ruta del archivo creado o null si falló.
  Future<String?> performAutoBackup() async {
    final backupDir = await getAutoBackupsFolder();
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';
    final destPath = p.join(backupDir.path, 'auto_backup_$stamp.db');

    final ok = await DatabaseHelper.copyDatabaseFile(destPath);
    if (!ok) return null;

    try {
      await _updateLastBackupTime();
      await enforceRetentionPolicy();
      return destPath;
    } catch (e) {
      debugPrint('performAutoBackup: $e');
      return null;
    }
  }

  /// Versión sincrónica para usar al cerrar la app.
  /// Cierra la BD antes de copiar para liberar cualquier bloqueo del archivo,
  /// luego la reabre para mantener el estado consistente.
  /// Retorna la ruta del archivo creado o null si falló.
  String? performAutoBackupSync() {
    if (_cachedDbPath.isEmpty) return null;
    final sourceFile = File(_cachedDbPath);
    if (!sourceFile.existsSync()) return null;

    // Cerrar la BD para liberar el archivo en Windows y poder copiarlo
    try {
      DatabaseHelper.closeAndReset();
    } catch (_) {}

    final backupDir = _cachedPath.isNotEmpty
        ? Directory(_cachedPath)
        : Directory(p.join(Directory(_cachedDbPath).parent.path, 'backups'));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';
    final destPath = p.join(backupDir.path, 'auto_backup_$stamp.db');

    try {
      sourceFile.copySync(destPath);
      _enforceRetentionPolicySync(backupDir);
      _updateLastBackupTimeSync();
      return destPath;
    } catch (e) {
      debugPrint('performAutoBackupSync: $e');
      return null;
    }
  }

  /// Versión sincrónica de la retención.
  void _enforceRetentionPolicySync(Directory backupDir) {
    if (!backupDir.existsSync()) return;
    final files = backupDir.listSync().where((entity) {
      return entity is File &&
          p.basename(entity.path).startsWith('auto_backup_');
    }).toList();
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    if (files.length <= maxAutoBackups) return;
    for (final entity in files.sublist(maxAutoBackups)) {
      try {
        entity.deleteSync();
      } catch (e) {
        debugPrint('_enforceRetentionPolicySync: $e');
      }
    }
  }

  /// Elimina los backups automáticos más antiguos para conservar solo los últimos [maxAutoBackups].
  Future<void> enforceRetentionPolicy() async {
    final backups = await getExistingAutoBackups();
    if (backups.length <= maxAutoBackups) return;
    final toDelete = backups.sublist(maxAutoBackups);
    for (final entity in toDelete) {
      try {
        await entity.delete();
      } catch (e) {
        debugPrint('enforceRetentionPolicy: $e');
      }
    }
  }

  /// Copia la BD a una carpeta elegida por el usuario.
  /// Usa checkpoint + copy para no interrumpir las operaciones de la BD.
  /// Retorna la ruta del archivo creado, o null si el usuario canceló.
  Future<String?> exportBackup() async {
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

    final ok = await DatabaseHelper.copyDatabaseFile(destPath);
    if (!ok) {
      throw const AppException(
        'No se encontró la base de datos para respaldar.',
      );
    }

    return destPath;
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
      throw const AppException(
        'El archivo no parece ser una base de datos válida.',
      );
    }

    final appDir = await getApplicationSupportDirectory();
    final destPath = p.join(appDir.path, DatabaseHelper.dbName);

    // Copia de seguridad automática antes de sobreescribir
    final currentDb = File(destPath);
    final safetyPath = p.join(appDir.path, '${DatabaseHelper.dbName}_pre_restore');
    if (await currentDb.exists()) {
      await currentDb.copy(safetyPath);
    }

    await DatabaseHelper.closeAndReset();

    try {
      await sourceFile.copy(destPath);
    } catch (e) {
      // Rollback: si falla la copia, restauramos la copia de seguridad
      if (await File(safetyPath).exists()) {
        await File(safetyPath).copy(destPath);
        await DatabaseHelper.closeAndReset();
      }
      throw AppException(
        'No se pudo restaurar la base de datos.',
        technical: e.toString(),
      );
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
