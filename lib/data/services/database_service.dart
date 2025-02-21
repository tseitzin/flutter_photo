import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_photo/data/models/image_file_info.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'photo_analyzer.db');
    
    final databaseFactory = databaseFactoryFfi;
    
    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              path TEXT NOT NULL,
              name TEXT NOT NULL,
              size INTEGER NOT NULL,
              modified_at TEXT NOT NULL,
              directory TEXT NOT NULL,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          
          // Create index for faster directory lookups
          await db.execute(
            'CREATE INDEX images_directory_idx ON images(directory)'
          );
        },
      ),
    );
  }

  static Future<void> saveImages(List<ImageFileInfo> images) async {
    final db = await database;
    final batch = db.batch();

    for (final image in images) {
      batch.insert(
        'images',
        {
          'path': image.path,
          'name': image.name,
          'size': image.size,
          'modified_at': image.modified.toIso8601String(),
          'directory': dirname(image.path),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  static Future<List<ImageFileInfo>> getImagesInDirectory(String directory) async {
    final db = await database;
    final results = await db.query(
      'images',
      where: 'directory = ?',
      whereArgs: [directory],
    );

    return results.map((row) => ImageFileInfo(
      row['path'] as String,
      row['name'] as String,
      row['size'] as int,
      DateTime.parse(row['modified_at'] as String),
    )).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllImages() async {
    final db = await database;
    return await db.query(
      'images',
      orderBy: 'created_at DESC',
    );
  }

  static Future<Map<String, int>> getDirectoryStats() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT directory, COUNT(*) as count
      FROM images
      GROUP BY directory
      ORDER BY count DESC
    ''');
    
    return Map.fromEntries(
      results.map((row) => MapEntry(
        row['directory'] as String,
        (row['count'] as num).toInt(),
      )),
    );
  }

  static Future<void> deleteImages(List<String> paths) async {
    final db = await database;
    await db.delete(
      'images',
      where: 'path IN (${List.filled(paths.length, '?').join(',')})',
      whereArgs: paths,
    );
  }

  static Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('images');
  }
}