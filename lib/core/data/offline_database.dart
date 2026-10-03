import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../Model/product_model.dart';

/// Single local persistence boundary for the offline-first application.
///
/// Product aggregates are stored as JSON inside SQLite so the existing domain
/// model stays simple while writes remain transactional and indexable.
class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();

  static const _databaseName = 'nextpos.sqlite';
  static const _version = 1;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      path.join(directory.path, _databaseName),
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
        await db.execute('PRAGMA busy_timeout = 5000');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT,
            payload TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            modified_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX products_name_idx ON products(name COLLATE NOCASE)',
        );
        await db.execute(
          'CREATE INDEX products_modified_idx ON products(modified_at)',
        );

        await db.execute('''
          CREATE TABLE sync_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX sync_outbox_created_idx ON sync_outbox(created_at)',
        );

        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Map<String, Object?> _productRow(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'category': product.category,
      'payload': jsonEncode(product.toMap()),
      'is_deleted': product.isSoftDeleted ? 1 : 0,
      'modified_at': product.lastModified.toUtc().toIso8601String(),
    };
  }

  Future<void> upsertProduct(Product product, {bool queueSync = true}) async {
    final db = await database;
    final payload = jsonEncode(product.toMap());

    await db.transaction((txn) async {
      await txn.insert(
        'products',
        _productRow(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (queueSync) {
        await txn.insert('sync_outbox', {
          'entity': 'product',
          'entity_id': product.id,
          'operation': 'upsert',
          'payload': payload,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  Future<List<Product>> readProducts({bool includeDeleted = true}) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'modified_at DESC',
    );

    return rows
        .map(
          (row) => Product.fromMap(
            Map<String, dynamic>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
          ),
        )
        .toList();
  }

  Future<void> clearProducts() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      await txn.delete('sync_outbox');
    });
  }

  Future<List<Map<String, Object?>>> pendingSync({int limit = 100}) async {
    final db = await database;
    return db.query('sync_outbox', orderBy: 'created_at ASC', limit: limit);
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<Map<String, String>> readAllMetadata() async {
    final db = await database;
    final rows = await db.query('app_metadata', orderBy: 'key ASC');
    return {
      for (final row in rows)
        row['key']! as String: row['value']! as String,
    };
  }

  Future<void> markSyncAttempt(int id, {String? error}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_outbox '
      'SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<File> exportBackup(File destination) async {
    final products = await readProducts();
    final outbox = await pendingSync(limit: 1000000);
    final metadata = await readAllMetadata();

    final backup = {
      'format': 'nextpos-offline-backup',
      'version': 2,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'products': products.map((product) => product.toMap()).toList(),
      'syncOutbox': outbox,
      'metadata': metadata,
    };

    await destination.parent.create(recursive: true);
    return destination.writeAsString(jsonEncode(backup), flush: true);
  }

  Future<int> importBackup(File source) async {
    final decoded = jsonDecode(await source.readAsString());

    if (decoded is! Map || decoded['format'] != 'nextpos-offline-backup') {
      throw const FormatException('This file is not a NextPOS backup.');
    }

    final products = (decoded['products'] as List? ?? const [])
        .map(
          (item) => Product.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final metadata = decoded['metadata'] is Map
        ? Map<String, dynamic>.from(decoded['metadata'] as Map)
        : const <String, dynamic>{};

    final outbox = decoded['syncOutbox'] is List
        ? List<dynamic>.from(decoded['syncOutbox'] as List)
        : const <dynamic>[];

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      await txn.delete('sync_outbox');
      await txn.delete('app_metadata');

      for (final product in products) {
        await txn.insert(
          'products',
          _productRow(product),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final entry in outbox) {
        if (entry is! Map) continue;
        final row = Map<String, dynamic>.from(entry);
        final entity = row['entity'];
        final entityId = row['entity_id'];
        final operation = row['operation'];
        final payload = row['payload'];
        final createdAt = row['created_at'];

        if (entity is! String ||
            entityId is! String ||
            operation is! String ||
            payload is! String ||
            createdAt is! String) {
          continue;
        }

        await txn.insert('sync_outbox', {
          'entity': entity,
          'entity_id': entityId,
          'operation': operation,
          'payload': payload,
          'created_at': createdAt,
          'attempts': row['attempts'] is int ? row['attempts'] : 0,
          'last_error': row['last_error'],
        });
      }

      for (final entry in metadata.entries) {
        await txn.insert(
          'app_metadata',
          {'key': entry.key, 'value': entry.value.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return products.length;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
