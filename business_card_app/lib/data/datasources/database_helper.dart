import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/database_constants.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await db.execute(DatabaseConstants.createContactsTable);
    await db.execute(DatabaseConstants.createUserSettingsTable);
    await db.execute(DatabaseConstants.createBackupHistoryTable);

    // Create indexes
    await db.execute(DatabaseConstants.createContactsNameIndex);
    await db.execute(DatabaseConstants.createContactsCreatedAtIndex);
    await db.execute(DatabaseConstants.createContactsIsStarredIndex);
    await db.execute(DatabaseConstants.createUserSettingsKeyIndex);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // For now, we'll just recreate tables
    if (oldVersion < newVersion) {
      // Add migration logic here for future versions
    }
  }

  Future<void> _onOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final defaultSettings = [
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingThemeMode,
        DatabaseConstants.settingsValue: 'system',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeString,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingLanguage,
        DatabaseConstants.settingsValue: 'en',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeString,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingSortOrder,
        DatabaseConstants.settingsValue: DatabaseConstants.sortByName,
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeString,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingAutoBackup,
        DatabaseConstants.settingsValue: 'true',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeBool,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingOcrUsageCount,
        DatabaseConstants.settingsValue: '0',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeInt,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingPremiumStatus,
        DatabaseConstants.settingsValue: 'false',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeBool,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      {
        DatabaseConstants.settingsKey: DatabaseConstants.settingFirstLaunch,
        DatabaseConstants.settingsValue: 'true',
        DatabaseConstants.settingsType: DatabaseConstants.settingTypeBool,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (final setting in defaultSettings) {
      await db.insert(
        DatabaseConstants.userSettingsTable,
        setting,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // CRUD Operations for Contacts
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert(
      DatabaseConstants.contactsTable,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Contact>> getAllContacts({String? sortBy}) async {
    final db = await database;
    String orderBy = DatabaseConstants.contactsName;

    switch (sortBy) {
      case DatabaseConstants.sortByCompany:
        orderBy = '${DatabaseConstants.contactsCompany} ASC, ${DatabaseConstants.contactsName} ASC';
        break;
      case DatabaseConstants.sortByCreatedAt:
        orderBy = '${DatabaseConstants.contactsCreatedAt} DESC';
        break;
      case DatabaseConstants.sortByUpdatedAt:
        orderBy = '${DatabaseConstants.contactsUpdatedAt} DESC';
        break;
      case DatabaseConstants.sortByStarred:
        orderBy = '${DatabaseConstants.contactsIsStarred} DESC, ${DatabaseConstants.contactsName} ASC';
        break;
      default:
        orderBy = '${DatabaseConstants.contactsName} ASC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.contactsTable,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
  }

  Future<Contact?> getContactById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.contactsTable,
      where: '${DatabaseConstants.contactsId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Contact>> searchContacts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.contactsTable,
      where: '''
        ${DatabaseConstants.contactsName} LIKE ? OR 
        ${DatabaseConstants.contactsCompany} LIKE ? OR 
        ${DatabaseConstants.contactsTitle} LIKE ? OR 
        ${DatabaseConstants.contactsEmail} LIKE ? OR 
        ${DatabaseConstants.contactsPhone} LIKE ?
      ''',
      whereArgs: List.filled(5, '%$query%'),
      orderBy: DatabaseConstants.contactsName,
    );

    return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
  }

  Future<List<Contact>> getStarredContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.contactsTable,
      where: '${DatabaseConstants.contactsIsStarred} = ?',
      whereArgs: [1],
      orderBy: DatabaseConstants.contactsName,
    );

    return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(
      DatabaseConstants.contactsTable,
      contact.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DatabaseConstants.contactsId} = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.contactsTable,
      where: '${DatabaseConstants.contactsId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> getContactCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.contactsTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Settings Operations
  Future<void> setSetting(String key, dynamic value, String type) async {
    final db = await database;
    await db.insert(
      DatabaseConstants.userSettingsTable,
      {
        DatabaseConstants.settingsKey: key,
        DatabaseConstants.settingsValue: value.toString(),
        DatabaseConstants.settingsType: type,
        DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<T?> getSetting<T>(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.userSettingsTable,
      where: '${DatabaseConstants.settingsKey} = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;

    final setting = maps.first;
    final value = setting[DatabaseConstants.settingsValue] as String;
    final type = setting[DatabaseConstants.settingsType] as String;

    switch (type) {
      case DatabaseConstants.settingTypeString:
        return value as T;
      case DatabaseConstants.settingTypeInt:
        return int.parse(value) as T;
      case DatabaseConstants.settingTypeBool:
        return (value.toLowerCase() == 'true') as T;
      case DatabaseConstants.settingTypeDouble:
        return double.parse(value) as T;
      default:
        return value as T;
    }
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.userSettingsTable,
    );

    final settings = <String, dynamic>{};
    for (final map in maps) {
      final key = map[DatabaseConstants.settingsKey] as String;
      final value = map[DatabaseConstants.settingsValue] as String;
      final type = map[DatabaseConstants.settingsType] as String;

      switch (type) {
        case DatabaseConstants.settingTypeString:
          settings[key] = value;
          break;
        case DatabaseConstants.settingTypeInt:
          settings[key] = int.parse(value);
          break;
        case DatabaseConstants.settingTypeBool:
          settings[key] = value.toLowerCase() == 'true';
          break;
        case DatabaseConstants.settingTypeDouble:
          settings[key] = double.parse(value);
          break;
        default:
          settings[key] = value;
      }
    }

    return settings;
  }

  // Backup Operations
  Future<String> createBackup() async {
    final contacts = await getAllContacts();
    final settings = await getAllSettings();

    final backupData = {
      'version': DatabaseConstants.databaseVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'settings': settings,
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'backup_$timestamp${DatabaseConstants.backupFileExtension}';
    
    // Save backup to backup history
    await _saveBackupHistory(fileName, contacts.length, 0); // File size will be calculated separately

    return jsonEncode(backupData);
  }

  Future<void> restoreFromBackup(String backupJson) async {
    final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
    
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete(DatabaseConstants.contactsTable);
      await txn.delete(DatabaseConstants.userSettingsTable);

      // Restore contacts
      final contactsData = backupData['contacts'] as List;
      for (final contactJson in contactsData) {
        final contact = Contact.fromJson(contactJson as Map<String, dynamic>);
        await txn.insert(DatabaseConstants.contactsTable, contact.toMap());
      }

      // Restore settings
      final settingsData = backupData['settings'] as Map<String, dynamic>;
      for (final entry in settingsData.entries) {
        String type = DatabaseConstants.settingTypeString;
        if (entry.value is int) {
          type = DatabaseConstants.settingTypeInt;
        } else if (entry.value is bool) {
          type = DatabaseConstants.settingTypeBool;
        } else if (entry.value is double) {
          type = DatabaseConstants.settingTypeDouble;
        }

        await txn.insert(DatabaseConstants.userSettingsTable, {
          DatabaseConstants.settingsKey: entry.key,
          DatabaseConstants.settingsValue: entry.value.toString(),
          DatabaseConstants.settingsType: type,
          DatabaseConstants.settingsUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<void> _saveBackupHistory(String fileName, int contactCount, int fileSize) async {
    final db = await database;
    await db.insert(DatabaseConstants.backupHistoryTable, {
      DatabaseConstants.backupFileName: fileName,
      DatabaseConstants.backupFilePath: '', // Will be set externally
      DatabaseConstants.backupContactCount: contactCount,
      DatabaseConstants.backupFileSize: fileSize,
      DatabaseConstants.backupCreatedAt: DateTime.now().millisecondsSinceEpoch,
      DatabaseConstants.backupType: DatabaseConstants.backupTypeManual,
    });

    // Clean old backup history (keep only last 50)
    await _cleanOldBackupHistory();
  }

  Future<void> _cleanOldBackupHistory() async {
    final db = await database;
    await db.delete(
      DatabaseConstants.backupHistoryTable,
      where: '''
        ${DatabaseConstants.backupId} NOT IN (
          SELECT ${DatabaseConstants.backupId} 
          FROM ${DatabaseConstants.backupHistoryTable} 
          ORDER BY ${DatabaseConstants.backupCreatedAt} DESC 
          LIMIT ${DatabaseConstants.maxBackupHistory}
        )
      ''',
    );
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}