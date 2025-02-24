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
    sqfliteFfiInit();
    
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'photo_analyzer.db');
    
    final databaseFactory = databaseFactoryFfi;
    
    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              path TEXT NOT NULL,
              name TEXT NOT NULL,
              size INTEGER NOT NULL,
              modified_at TEXT NOT NULL,
              directory TEXT NOT NULL,
              exif_data TEXT,
              checksum TEXT,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          
          await db.execute(
            'CREATE INDEX images_directory_idx ON images(directory)'
          );

          await db.execute(
            'CREATE INDEX images_checksum_idx ON images(checksum)'
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE images ADD COLUMN exif_data TEXT');
          }
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE images ADD COLUMN checksum TEXT');
            await db.execute(
              'CREATE INDEX images_checksum_idx ON images(checksum)'
            );
          }
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
        image.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  static Future<List<ImageFileInfo>> getImagesInDirectory(String directory) async {
    final db = await database;
    
    // First, find all checksums that appear more than once
    final duplicateChecksums = await db.rawQuery('''
      SELECT checksum
      FROM images
      WHERE checksum IS NOT NULL
      GROUP BY checksum
      HAVING COUNT(*) > 1
    ''');

    final duplicateSet = duplicateChecksums
        .map((row) => row['checksum'] as String)
        .toSet();

    final results = await db.query(
      'images',
      where: 'directory = ?',
      whereArgs: [directory],
    );

    return results.map((row) {
      final checksum = row['checksum'] as String?;
      final isDuplicate = checksum != null && duplicateSet.contains(checksum);
      
      return ImageFileInfo.fromMap({
        ...row,
        'is_duplicate': isDuplicate ? 1 : 0,
      });
    }).toList();
  }

  static Future<List<ImageFileInfo>> getDuplicateImages() async {
    final db = await database;
    
    final results = await db.rawQuery('''
      SELECT i.*, 
        (SELECT COUNT(*) FROM images i2 WHERE i2.checksum = i.checksum) > 1 as is_duplicate
      FROM images i
      WHERE i.checksum IN (
        SELECT checksum
        FROM images
        WHERE checksum IS NOT NULL
        GROUP BY checksum
        HAVING COUNT(*) > 1
      )
      ORDER BY i.checksum, i.path
    ''');

    return results.map((row) => ImageFileInfo.fromMap(row)).toList();
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