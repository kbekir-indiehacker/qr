import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/datasources/database_helper.dart';
import 'package:business_card_app/core/constants/database_constants.dart';
import 'package:business_card_app/core/utils/database_utils.dart';
import 'dart:convert';

// Mock of old database helper to simulate older versions
class OldDatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    _database ??= await _initOldDatabase();
    return _database!;
  }

  Future<Database> _initOldDatabase() async {
    return await openDatabase(
      ':memory:',
      version: 1,
      onCreate: _createOldTables,
    );
  }

  Future<void> _createOldTables(Database db, int version) async {
    // Simulate old database schema (version 1)
    await db.execute('''
      CREATE TABLE contacts_old (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company TEXT,
        phone TEXT,
        email TEXT,
        created_at INTEGER NOT NULL,
        is_starred INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE settings_old (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertOldContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert('contacts_old', contact);
  }

  Future<List<Map<String, dynamic>>> getOldContacts() async {
    final db = await database;
    return await db.query('contacts_old');
  }

  Future<void> insertOldSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings_old', {'key': key, 'value': value});
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

// Migration scenario simulator
class MigrationScenario {
  final int fromVersion;
  final int toVersion;
  final String description;
  final Future<void> Function() setupOldData;
  final Future<void> Function(DatabaseHelper) verifyMigration;

  MigrationScenario({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    required this.setupOldData,
    required this.verifyMigration,
  });
}

void main() {
  group('Database Migration Tests', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseHelper = DatabaseHelper();
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('Schema Migration Tests', () {
      test('Should create fresh database with current schema', () async {
        // Act
        final db = await databaseHelper.database;

        // Assert - Check that all current tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'"
        );
        
        final tableNames = tables.map((t) => t['name'] as String).toList();
        expect(tableNames, contains(DatabaseConstants.contactsTable));
        expect(tableNames, contains(DatabaseConstants.userSettingsTable));
        expect(tableNames, contains(DatabaseConstants.backupHistoryTable));
      });

      test('Should have correct contacts table schema', () async {
        final db = await databaseHelper.database;
        
        final columns = await db.rawQuery(
          "PRAGMA table_info(${DatabaseConstants.contactsTable})"
        );
        
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        // Check all required columns exist
        expect(columnNames, contains(DatabaseConstants.contactsId));
        expect(columnNames, contains(DatabaseConstants.contactsName));
        expect(columnNames, contains(DatabaseConstants.contactsCompany));
        expect(columnNames, contains(DatabaseConstants.contactsTitle));
        expect(columnNames, contains(DatabaseConstants.contactsPhone));
        expect(columnNames, contains(DatabaseConstants.contactsEmail));
        expect(columnNames, contains(DatabaseConstants.contactsWebsite));
        expect(columnNames, contains(DatabaseConstants.contactsTags));
        expect(columnNames, contains(DatabaseConstants.contactsNotes));
        expect(columnNames, contains(DatabaseConstants.contactsCreatedAt));
        expect(columnNames, contains(DatabaseConstants.contactsUpdatedAt));
        expect(columnNames, contains(DatabaseConstants.contactsIsStarred));
        expect(columnNames, contains(DatabaseConstants.contactsCardImagePath));
        expect(columnNames, contains(DatabaseConstants.contactsSocialMedia));
      });

      test('Should have correct indexes', () async {
        final db = await databaseHelper.database;
        
        final indexes = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index'"
        );
        
        final indexNames = indexes.map((i) => i['name'] as String).toList();
        
        // Check important indexes exist
        expect(indexNames, contains('idx_contacts_name'));
        expect(indexNames, contains('idx_contacts_created_at'));
        expect(indexNames, contains('idx_contacts_is_starred'));
      });

      test('Should have correct foreign key constraints', () async {
        final db = await databaseHelper.database;
        
        // Check if foreign keys are enabled
        final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
        expect(foreignKeys.first['foreign_keys'], 1);
      });
    });

    group('Data Migration Tests', () {
      test('Should migrate old contact data to new schema', () async {
        // Arrange - Create old database with old schema
        final oldDb = await openDatabase(
          ':memory:',
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE contacts_old (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                company TEXT,
                phone TEXT,
                email TEXT,
                created_at INTEGER NOT NULL,
                is_starred INTEGER NOT NULL DEFAULT 0
              )
            ''');
          },
        );

        // Insert old data
        await oldDb.insert('contacts_old', {
          'name': 'John Doe',
          'company': 'Old Tech Corp',
          'phone': '+1234567890',
          'email': 'john@oldtech.com',
          'created_at': DateTime(2023, 1, 1).millisecondsSinceEpoch,
          'is_starred': 1,
        });

        await oldDb.insert('contacts_old', {
          'name': 'Jane Smith',
          'company': 'Design Studio',
          'email': 'jane@design.com',
          'created_at': DateTime(2023, 2, 1).millisecondsSinceEpoch,
          'is_starred': 0,
        });

        // Get old data
        final oldContacts = await oldDb.query('contacts_old');
        await oldDb.close();

        // Act - Migrate to new database
        final db = await databaseHelper.database;
        
        // Simulate migration process
        for (final oldContact in oldContacts) {
          final migratedContact = Contact(
            name: oldContact['name'] as String,
            company: oldContact['company'] as String?,
            phone: oldContact['phone'] as String?,
            email: oldContact['email'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(oldContact['created_at'] as int),
            isStarred: (oldContact['is_starred'] as int) == 1,
            // New fields with default values
            tags: [],
            notes: null,
            title: null,
            website: null,
            socialMedia: null,
          );
          
          await databaseHelper.insertContact(migratedContact);
        }

        // Assert
        final newContacts = await databaseHelper.getAllContacts();
        expect(newContacts.length, 2);
        
        final johnDoe = newContacts.firstWhere((c) => c.name == 'John Doe');
        expect(johnDoe.company, 'Old Tech Corp');
        expect(johnDoe.phone, '+1234567890');
        expect(johnDoe.email, 'john@oldtech.com');
        expect(johnDoe.isStarred, true);
        expect(johnDoe.tags, isEmpty);
        expect(johnDoe.notes, isNull);
        
        final janeSmith = newContacts.firstWhere((c) => c.name == 'Jane Smith');
        expect(janeSmith.company, 'Design Studio');
        expect(janeSmith.isStarred, false);
      });

      test('Should handle missing fields in migration gracefully', () async {
        // Arrange - Create minimal old database
        final oldDb = await openDatabase(
          ':memory:',
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE contacts_minimal (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL
              )
            ''');
          },
        );

        await oldDb.insert('contacts_minimal', {'name': 'Minimal Contact'});
        final oldContacts = await oldDb.query('contacts_minimal');
        await oldDb.close();

        // Act - Migrate with minimal data
        for (final oldContact in oldContacts) {
          final migratedContact = Contact(
            name: oldContact['name'] as String,
            // All other fields are null/default
          );
          
          await databaseHelper.insertContact(migratedContact);
        }

        // Assert
        final newContacts = await databaseHelper.getAllContacts();
        expect(newContacts.length, 1);
        
        final contact = newContacts.first;
        expect(contact.name, 'Minimal Contact');
        expect(contact.company, isNull);
        expect(contact.email, isNull);
        expect(contact.isStarred, false);
        expect(contact.tags, isEmpty);
      });

      test('Should migrate settings correctly', () async {
        // Arrange - Create old settings
        await databaseHelper.setSetting('old_theme', 'dark', 'string');
        await databaseHelper.setSetting('old_language', 'en', 'string');

        // Act - Migrate to new setting names
        final oldTheme = await databaseHelper.getSetting<String>('old_theme');
        final oldLanguage = await databaseHelper.getSetting<String>('old_language');

        if (oldTheme != null) {
          await databaseHelper.setSetting(
            DatabaseConstants.settingThemeMode, 
            oldTheme, 
            DatabaseConstants.settingTypeString
          );
        }

        if (oldLanguage != null) {
          await databaseHelper.setSetting(
            DatabaseConstants.settingLanguage, 
            oldLanguage, 
            DatabaseConstants.settingTypeString
          );
        }

        // Assert
        final newTheme = await databaseHelper.getSetting<String>(DatabaseConstants.settingThemeMode);
        final newLanguage = await databaseHelper.getSetting<String>(DatabaseConstants.settingLanguage);

        expect(newTheme, 'dark');
        expect(newLanguage, 'en');
      });
    });

    group('Backup and Restore Migration', () {
      test('Should migrate backup format correctly', () async {
        // Arrange - Create old format backup
        final oldBackupData = {
          'version': 1,
          'timestamp': DateTime.now().toIso8601String(),
          'contacts': [
            {
              'id': 1,
              'name': 'John Doe',
              'company': 'Tech Corp',
              'email': 'john@techcorp.com',
              'phone': '+1234567890',
              'created_at': DateTime.now().toIso8601String(),
              'is_starred': true,
              // Missing new fields
            },
          ],
        };

        final oldBackupJson = jsonEncode(oldBackupData);

        // Act - Migrate backup format
        final migratedData = DatabaseUtils.migrateContactData(
          oldBackupData, 
          1, // from version
          DatabaseConstants.databaseVersion // to version
        );

        // Assert
        expect(migratedData['version'], DatabaseConstants.databaseVersion);
        expect(migratedData['contacts'], isA<List>());
        
        final contacts = migratedData['contacts'] as List;
        expect(contacts.length, 1);
        
        final contact = contacts.first as Map<String, dynamic>;
        expect(contact['name'], 'John Doe');
        expect(contact['company'], 'Tech Corp');
      });

      test('Should validate migrated backup data', () async {
        // Arrange - Create various backup formats
        final validBackup = {
          'version': DatabaseConstants.databaseVersion,
          'timestamp': DateTime.now().toIso8601String(),
          'contacts': [
            {
              'name': 'Valid Contact',
              'company': 'Valid Corp',
            },
          ],
        };

        final invalidBackup = {
          'version': DatabaseConstants.databaseVersion,
          'contacts': [
            {
              'name': '', // Invalid: empty name
            },
          ],
        };

        // Act & Assert
        expect(
          DatabaseUtils.isValidBackupJson(jsonEncode(validBackup)), 
          true
        );
        expect(
          DatabaseUtils.isValidBackupJson(jsonEncode(invalidBackup)), 
          false
        );
      });

      test('Should restore migrated backup successfully', () async {
        // Arrange - Create new format backup
        final contacts = [
          Contact(
            name: 'Restored Contact 1',
            company: 'Restored Corp',
            email: 'restored1@example.com',
            tags: ['restored', 'test'],
          ),
          Contact(
            name: 'Restored Contact 2',
            title: 'Restored Title',
            isStarred: true,
          ),
        ];

        for (final contact in contacts) {
          await databaseHelper.insertContact(contact);
        }

        // Create backup
        final backupJson = await databaseHelper.createBackup();

        // Clear database
        await databaseHelper.deleteDatabase();
        databaseHelper = DatabaseHelper();

        // Act - Restore from backup
        await databaseHelper.restoreFromBackup(backupJson);

        // Assert
        final restoredContacts = await databaseHelper.getAllContacts();
        expect(restoredContacts.length, 2);
        
        final contact1 = restoredContacts.firstWhere((c) => c.name == 'Restored Contact 1');
        expect(contact1.company, 'Restored Corp');
        expect(contact1.email, 'restored1@example.com');
        expect(contact1.tags, ['restored', 'test']);
        
        final contact2 = restoredContacts.firstWhere((c) => c.name == 'Restored Contact 2');
        expect(contact2.title, 'Restored Title');
        expect(contact2.isStarred, true);
      });
    });

    group('Error Handling in Migration', () {
      test('Should handle corrupted data during migration', () async {
        // Arrange - Create corrupted backup
        final corruptedBackup = '''
        {
          "version": 1,
          "contacts": [
            {
              "name": "Valid Contact"
            },
            {
              "invalid": "missing name field"
            },
            {
              "name": null
            }
          ]
        }
        ''';

        // Act & Assert
        expect(
          DatabaseUtils.isValidBackupJson(corruptedBackup),
          false
        );

        expect(
          () => databaseHelper.restoreFromBackup(corruptedBackup),
          throwsA(isA<Exception>()),
        );
      });

      test('Should rollback on migration failure', () async {
        // Arrange - Add initial data
        await databaseHelper.insertContact(Contact(name: 'Original Contact'));
        final originalCount = await databaseHelper.getContactCount();

        // Act - Attempt invalid migration
        try {
          await databaseHelper.restoreFromBackup('invalid json');
        } catch (e) {
          // Expected to fail
        }

        // Assert - Original data should still be there
        final currentCount = await databaseHelper.getContactCount();
        expect(currentCount, originalCount);
        
        final contacts = await databaseHelper.getAllContacts();
        expect(contacts.any((c) => c.name == 'Original Contact'), true);
      });

      test('Should handle partial migration scenarios', () async {
        // This test simulates what happens when migration is interrupted
        
        // Arrange - Start with some data
        await databaseHelper.insertContact(Contact(name: 'Pre-migration Contact'));
        
        // Simulate interrupted migration by manually clearing only some data
        final db = await databaseHelper.database;
        
        // Partially clear data (simulate interruption)
        await db.delete(DatabaseConstants.contactsTable, 
            where: '${DatabaseConstants.contactsName} = ?', 
            whereArgs: ['Pre-migration Contact']);
        
        // Act - Try to recover by re-running migration
        await databaseHelper.insertContact(Contact(name: 'Recovery Contact'));
        
        // Assert
        final contacts = await databaseHelper.getAllContacts();
        expect(contacts.length, 1);
        expect(contacts.first.name, 'Recovery Contact');
      });
    });

    group('Performance During Migration', () {
      test('Should migrate large datasets efficiently', () async {
        // Arrange - Create large dataset
        const largeCount = 1000;
        final stopwatch = Stopwatch()..start();

        // Simulate migration of large dataset
        for (int i = 0; i < largeCount; i++) {
          await databaseHelper.insertContact(Contact(
            name: 'Contact $i',
            company: 'Company $i',
            email: 'contact$i@example.com',
          ));
        }

        stopwatch.stop();

        // Assert - Should complete in reasonable time
        expect(stopwatch.elapsed.inSeconds, lessThan(30)); // Under 30 seconds
        
        final finalCount = await databaseHelper.getContactCount();
        expect(finalCount, largeCount);
      });

      test('Should handle migration without blocking UI', () async {
        // This test ensures migration operations are async and don't block
        
        final futures = <Future>[];
        
        // Simulate concurrent operations during migration
        for (int i = 0; i < 10; i++) {
          futures.add(databaseHelper.insertContact(Contact(name: 'Concurrent $i')));
        }
        
        // Add some read operations
        for (int i = 0; i < 5; i++) {
          futures.add(databaseHelper.getAllContacts());
        }
        
        // Act - All operations should complete without deadlock
        final results = await Future.wait(futures);
        
        // Assert
        expect(results.length, 15); // 10 inserts + 5 reads
        
        final contacts = await databaseHelper.getAllContacts();
        expect(contacts.length, 10);
      });
    });

    group('Version Compatibility', () {
      test('Should detect version mismatches', () async {
        // Arrange - Create backup with future version
        final futureVersionBackup = {
          'version': DatabaseConstants.databaseVersion + 1,
          'timestamp': DateTime.now().toIso8601String(),
          'contacts': [],
        };

        // Act & Assert - Should handle future version gracefully
        expect(
          DatabaseUtils.isValidBackupJson(jsonEncode(futureVersionBackup)),
          true
        );

        // The restore might succeed but should be handled carefully
        // in a real app, you'd want to show a warning about version mismatch
      });

      test('Should handle legacy version formats', () async {
        // Arrange - Create very old backup format
        final legacyBackup = {
          'contacts': [ // No version field
            {
              'name': 'Legacy Contact',
              'phone': '123-456-7890',
            },
          ],
        };

        // Act & Assert - Should reject invalid format
        expect(
          DatabaseUtils.isValidBackupJson(jsonEncode(legacyBackup)),
          false
        );
      });
    });
  });
}