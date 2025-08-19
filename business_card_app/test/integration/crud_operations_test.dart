import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/datasources/database_helper.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/datasources/local_storage.dart';
import 'dart:math';

// Mock LocalStorage for testing
class TestLocalStorage implements LocalStorage {
  bool _isPremium = true; // Premium for unlimited contacts
  String _sortOrder = 'name';
  bool _showStarredFirst = false;
  final List<String> _recentSearches = [];
  int _totalContactsCreated = 0;

  @override
  Future<bool> getPremiumStatus() async => _isPremium;

  @override
  Future<String> getSortOrder() async => _sortOrder;

  @override
  Future<bool> getShowStarredFirst() async => _showStarredFirst;

  @override
  Future<void> addRecentSearch(String query) async {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
  }

  @override
  Future<void> incrementTotalContactsCreated() async {
    _totalContactsCreated++;
  }

  @override
  Future<int> getTotalContactsCreated() async => _totalContactsCreated;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CRUD Operations Integration Tests', () {
    late DatabaseHelper databaseHelper;
    late ContactRepository repository;
    late TestLocalStorage localStorage;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      // Set the database factory for testing
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create in-memory database for each test
      databaseHelper = DatabaseHelper();
      localStorage = TestLocalStorage();
      repository = ContactRepository(
        databaseHelper: databaseHelper,
        localStorage: localStorage,
      );
      
      // Initialize database
      await databaseHelper.database;
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('Contact CRUD Operations', () {
      test('Should create contact successfully', () async {
        // Arrange
        final contact = Contact(
          name: 'John Doe',
          company: 'Tech Corp',
          title: 'Software Engineer',
          phone: '+1234567890',
          email: 'john.doe@techcorp.com',
          website: 'https://johndoe.com',
          tags: ['developer', 'tech'],
          notes: 'Met at tech conference',
          isStarred: true,
        );

        // Act
        final id = await repository.addContact(contact);

        // Assert
        expect(id, greaterThan(0));
        final retrievedContact = await repository.getContactById(id);
        expect(retrievedContact, isNotNull);
        expect(retrievedContact!.name, 'John Doe');
        expect(retrievedContact.company, 'Tech Corp');
        expect(retrievedContact.email, 'john.doe@techcorp.com');
        expect(retrievedContact.isStarred, true);
        expect(retrievedContact.tags, ['developer', 'tech']);
      });

      test('Should read all contacts', () async {
        // Arrange - Add multiple contacts
        final contacts = [
          Contact(name: 'Alice Johnson', company: 'ABC Corp'),
          Contact(name: 'Bob Smith', company: 'XYZ Inc'),
          Contact(name: 'Charlie Brown', company: 'DEF Ltd'),
        ];

        for (final contact in contacts) {
          await repository.addContact(contact);
        }

        // Act
        final allContacts = await repository.getAllContacts();

        // Assert
        expect(allContacts.length, 3);
        expect(allContacts.map((c) => c.name).toList(), 
               containsAll(['Alice Johnson', 'Bob Smith', 'Charlie Brown']));
      });

      test('Should update contact successfully', () async {
        // Arrange
        final originalContact = Contact(
          name: 'Original Name',
          email: 'original@example.com',
        );
        final id = await repository.addContact(originalContact);

        // Act
        final updatedContact = Contact(
          id: id,
          name: 'Updated Name',
          email: 'updated@example.com',
          company: 'New Company',
          isStarred: true,
        );
        final result = await repository.updateContact(updatedContact);

        // Assert
        expect(result, true);
        final retrievedContact = await repository.getContactById(id);
        expect(retrievedContact!.name, 'Updated Name');
        expect(retrievedContact.email, 'updated@example.com');
        expect(retrievedContact.company, 'New Company');
        expect(retrievedContact.isStarred, true);
        expect(retrievedContact.updatedAt, isNotNull);
      });

      test('Should delete contact successfully', () async {
        // Arrange
        final contact = Contact(name: 'To Be Deleted');
        final id = await repository.addContact(contact);
        
        // Verify contact exists
        expect(await repository.getContactById(id), isNotNull);

        // Act
        final result = await repository.deleteContact(id);

        // Assert
        expect(result, true);
        expect(await repository.getContactById(id), isNull);
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.any((c) => c.id == id), false);
      });

      test('Should toggle starred status', () async {
        // Arrange
        final contact = Contact(name: 'Test Contact', isStarred: false);
        final id = await repository.addContact(contact);

        // Act & Assert - Toggle to starred
        await repository.toggleStarred(id);
        var retrievedContact = await repository.getContactById(id);
        expect(retrievedContact!.isStarred, true);

        // Act & Assert - Toggle back to unstarred
        await repository.toggleStarred(id);
        retrievedContact = await repository.getContactById(id);
        expect(retrievedContact!.isStarred, false);
      });
    });

    group('Search Operations', () {
      setUp(() async {
        // Add test data for search
        final testContacts = [
          Contact(name: 'John Doe', company: 'Tech Corp', email: 'john@techcorp.com'),
          Contact(name: 'Jane Smith', company: 'Design Studio', email: 'jane@design.com'),
          Contact(name: 'Bob Johnson', company: 'Tech Solutions', email: 'bob@techsol.com'),
          Contact(name: 'Alice Williams', company: 'Marketing Inc', email: 'alice@marketing.com'),
        ];

        for (final contact in testContacts) {
          await repository.addContact(contact);
        }
      });

      test('Should search by name', () async {
        final results = await repository.searchContacts('John');
        expect(results.length, 2); // John Doe and Bob Johnson
        expect(results.any((c) => c.name.contains('John')), true);
      });

      test('Should search by company', () async {
        final results = await repository.searchContacts('Tech');
        expect(results.length, 2); // Tech Corp and Tech Solutions
        expect(results.every((c) => c.company!.contains('Tech')), true);
      });

      test('Should search by email', () async {
        final results = await repository.searchContacts('design');
        expect(results.length, 1);
        expect(results.first.email, 'jane@design.com');
      });

      test('Should be case insensitive', () async {
        final results = await repository.searchContacts('TECH');
        expect(results.length, 2);
      });

      test('Should return empty for no matches', () async {
        final results = await repository.searchContacts('nonexistent');
        expect(results.isEmpty, true);
      });
    });

    group('Sorting Operations', () {
      setUp(() async {
        // Add contacts with different dates for sorting test
        await repository.addContact(Contact(name: 'Charlie', company: 'ABC Corp'));
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.addContact(Contact(name: 'Alice', company: 'XYZ Inc'));
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.addContact(Contact(name: 'Bob', company: 'DEF Ltd', isStarred: true));
      });

      test('Should sort by name', () async {
        localStorage._sortOrder = 'name';
        final contacts = await repository.getAllContacts();
        expect(contacts.map((c) => c.name).toList(), ['Alice', 'Bob', 'Charlie']);
      });

      test('Should sort starred first when enabled', () async {
        localStorage._showStarredFirst = true;
        final contacts = await repository.getAllContacts();
        expect(contacts.first.isStarred, true);
        expect(contacts.first.name, 'Bob');
      });
    });

    group('Statistics Operations', () {
      setUp(() async {
        await repository.addContact(Contact(
          name: 'Complete Contact',
          company: 'Tech Corp',
          email: 'complete@example.com',
          phone: '1234567890',
          website: 'https://example.com',
          isStarred: true,
        ));
        await repository.addContact(Contact(
          name: 'Minimal Contact',
          email: 'minimal@example.com',
        ));
        await repository.addContact(Contact(
          name: 'Another Contact',
          company: 'Another Corp',
          isStarred: true,
        ));
      });

      test('Should calculate correct statistics', () async {
        final stats = await repository.getContactStatistics();
        
        expect(stats['total'], 3);
        expect(stats['starred'], 2);
        expect(stats['withCompany'], 2);
        expect(stats['withEmail'], 2);
        expect(stats['withPhone'], 1);
      });

      test('Should get correct contact count', () async {
        final count = await repository.getContactCount();
        expect(count, 3);
      });

      test('Should get starred contacts only', () async {
        final starredContacts = await repository.getStarredContacts();
        expect(starredContacts.length, 2);
        expect(starredContacts.every((c) => c.isStarred), true);
      });
    });

    group('Tags Operations', () {
      setUp(() async {
        await repository.addContact(Contact(
          name: 'Developer 1',
          tags: ['tech', 'programming', 'flutter'],
        ));
        await repository.addContact(Contact(
          name: 'Developer 2',
          tags: ['tech', 'web', 'react'],
        ));
        await repository.addContact(Contact(
          name: 'Designer',
          tags: ['design', 'ui', 'ux'],
        ));
      });

      test('Should get all unique tags', () async {
        final tags = await repository.getAllTags();
        expect(tags.length, 7);
        expect(tags.contains('tech'), true);
        expect(tags.contains('programming'), true);
        expect(tags.contains('design'), true);
      });

      test('Should get contacts by tag', () async {
        final techContacts = await repository.getContactsByTag('tech');
        expect(techContacts.length, 2);
        expect(techContacts.every((c) => c.tags.contains('tech')), true);

        final designContacts = await repository.getContactsByTag('design');
        expect(designContacts.length, 1);
        expect(designContacts.first.name, 'Designer');
      });
    });

    group('Validation Tests', () {
      test('Should reject empty contact name', () async {
        final contact = Contact(name: '');
        expect(
          () => repository.addContact(contact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('Should reject invalid email format', () async {
        final contact = Contact(
          name: 'Test User',
          email: 'invalid-email',
        );
        expect(
          () => repository.addContact(contact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('Should reject invalid phone format', () async {
        final contact = Contact(
          name: 'Test User',
          phone: '123', // Too short
        );
        expect(
          () => repository.addContact(contact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('Should reject invalid website URL', () async {
        final contact = Contact(
          name: 'Test User',
          website: 'not-a-url',
        );
        expect(
          () => repository.addContact(contact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('Should accept valid contact data', () async {
        final contact = Contact(
          name: 'Valid User',
          email: 'valid@example.com',
          phone: '+1234567890',
          website: 'https://example.com',
        );
        
        final id = await repository.addContact(contact);
        expect(id, greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('Should handle special characters in names', () async {
        final contact = Contact(
          name: 'José García-Martínez',
          company: 'Çelik & Söhne',
        );
        
        final id = await repository.addContact(contact);
        final retrieved = await repository.getContactById(id);
        expect(retrieved!.name, 'José García-Martínez');
        expect(retrieved.company, 'Çelik & Söhne');
      });

      test('Should handle long text fields', () async {
        final longNotes = 'A' * 500; // 500 characters
        final contact = Contact(
          name: 'Test User',
          notes: longNotes,
        );
        
        final id = await repository.addContact(contact);
        final retrieved = await repository.getContactById(id);
        expect(retrieved!.notes, longNotes);
      });

      test('Should handle empty optional fields', () async {
        final contact = Contact(
          name: 'Minimal Contact',
          // All other fields are null/empty
        );
        
        final id = await repository.addContact(contact);
        final retrieved = await repository.getContactById(id);
        expect(retrieved!.name, 'Minimal Contact');
        expect(retrieved.company, isNull);
        expect(retrieved.email, isNull);
        expect(retrieved.tags, isEmpty);
      });

      test('Should handle contact with only name', () async {
        final contact = Contact(name: 'Only Name');
        
        final id = await repository.addContact(contact);
        final retrieved = await repository.getContactById(id);
        expect(retrieved!.name, 'Only Name');
        expect(retrieved.hasEmail, false);
        expect(retrieved.hasPhoneNumber, false);
        expect(retrieved.hasCompany, false);
      });
    });

    group('Concurrent Operations', () {
      test('Should handle multiple simultaneous operations', () async {
        // Create multiple contacts concurrently
        final futures = List.generate(10, (index) =>
          repository.addContact(Contact(name: 'Contact $index'))
        );
        
        final ids = await Future.wait(futures);
        expect(ids.length, 10);
        expect(ids.every((id) => id > 0), true);
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, 10);
      });

      test('Should handle concurrent read/write operations', () async {
        // Add initial contact
        final initialId = await repository.addContact(Contact(name: 'Initial'));
        
        // Perform concurrent operations
        final futures = [
          repository.addContact(Contact(name: 'New 1')),
          repository.addContact(Contact(name: 'New 2')),
          repository.getContactById(initialId),
          repository.getAllContacts(),
          repository.searchContacts('Initial'),
        ];
        
        final results = await Future.wait(futures);
        expect(results[0], greaterThan(0)); // New contact 1 ID
        expect(results[1], greaterThan(0)); // New contact 2 ID
        expect(results[2], isNotNull); // Retrieved contact
        expect((results[3] as List).length, 3); // All contacts
        expect((results[4] as List).length, 1); // Search results
      });
    });
  });
}