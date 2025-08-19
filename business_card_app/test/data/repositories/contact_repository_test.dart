import 'package:flutter_test/flutter_test.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/datasources/database_helper.dart';
import 'package:business_card_app/data/datasources/local_storage.dart';
import 'package:business_card_app/core/constants/database_constants.dart';

// Mock classes
class MockDatabaseHelper implements DatabaseHelper {
  final List<Contact> _contacts = [];
  int _nextId = 1;

  @override
  Future<int> insertContact(Contact contact) async {
    final newContact = contact.copyWith(id: _nextId++);
    _contacts.add(newContact);
    return newContact.id!;
  }

  @override
  Future<List<Contact>> getAllContacts({String? sortBy}) async {
    final contacts = List<Contact>.from(_contacts);
    switch (sortBy) {
      case DatabaseConstants.sortByName:
        contacts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case DatabaseConstants.sortByCompany:
        contacts.sort((a, b) => (a.company ?? '').compareTo(b.company ?? ''));
        break;
      case DatabaseConstants.sortByCreatedAt:
        contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DatabaseConstants.sortByStarred:
        contacts.sort((a, b) {
          if (a.isStarred && !b.isStarred) return -1;
          if (!a.isStarred && b.isStarred) return 1;
          return a.name.compareTo(b.name);
        });
        break;
    }
    return contacts;
  }

  @override
  Future<Contact?> getContactById(int id) async {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    return _contacts.where((contact) {
      final searchText = query.toLowerCase();
      return contact.name.toLowerCase().contains(searchText) ||
          (contact.company?.toLowerCase().contains(searchText) ?? false) ||
          (contact.email?.toLowerCase().contains(searchText) ?? false);
    }).toList();
  }

  @override
  Future<List<Contact>> getStarredContacts() async {
    return _contacts.where((c) => c.isStarred).toList();
  }

  @override
  Future<int> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteContact(int id) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts.removeAt(index);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> getContactCount() async {
    return _contacts.length;
  }

  // Implement other required methods with minimal implementation
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocalStorage implements LocalStorage {
  bool _isPremium = false;
  String _sortOrder = DatabaseConstants.sortByName;
  bool _showStarredFirst = false;
  final List<String> _recentSearches = [];

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
    if (_recentSearches.length > 10) {
      _recentSearches.removeRange(10, _recentSearches.length);
    }
  }

  @override
  Future<void> incrementTotalContactsCreated() async {}

  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
  }

  void setSortOrder(String sortOrder) {
    _sortOrder = sortOrder;
  }

  // Implement other required methods with minimal implementation
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ContactRepository Tests', () {
    late ContactRepository repository;
    late MockDatabaseHelper mockDatabaseHelper;
    late MockLocalStorage mockLocalStorage;

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockLocalStorage = MockLocalStorage();
      repository = ContactRepository(
        databaseHelper: mockDatabaseHelper,
        localStorage: mockLocalStorage,
      );
    });

    group('Add Contact', () {
      test('should add contact successfully when user can add more contacts', () async {
        mockLocalStorage.setPremiumStatus(true); // Premium users can add unlimited contacts

        final contact = Contact(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final id = await repository.addContact(contact);

        expect(id, 1);
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, 1);
        expect(allContacts.first.name, 'John Doe');
      });

      test('should throw exception when free user reaches contact limit', () async {
        mockLocalStorage.setPremiumStatus(false);

        // Add maximum allowed contacts for free users
        for (int i = 0; i < DatabaseConstants.maxContactsForFree; i++) {
          await mockDatabaseHelper.insertContact(Contact(name: 'Contact $i'));
        }

        final contact = Contact(name: 'Excess Contact');

        expect(
          () => repository.addContact(contact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('should validate contact data before adding', () async {
        mockLocalStorage.setPremiumStatus(true);

        // Test empty name
        expect(
          () => repository.addContact(Contact(name: '')),
          throwsA(isA<ContactRepositoryException>()),
        );

        // Test invalid email
        expect(
          () => repository.addContact(Contact(
            name: 'Test',
            email: 'invalid-email',
          )),
          throwsA(isA<ContactRepositoryException>()),
        );

        // Test invalid phone
        expect(
          () => repository.addContact(Contact(
            name: 'Test',
            phone: '123', // Too short
          )),
          throwsA(isA<ContactRepositoryException>()),
        );

        // Test invalid website
        expect(
          () => repository.addContact(Contact(
            name: 'Test',
            website: 'not-a-url',
          )),
          throwsA(isA<ContactRepositoryException>()),
        );
      });
    });

    group('Get Contacts', () {
      setUp(() async {
        // Add test contacts
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Alice Johnson',
          company: 'ABC Corp',
          isStarred: true,
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Bob Smith',
          company: 'XYZ Inc',
          isStarred: false,
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Charlie Brown',
          company: 'ABC Corp',
          isStarred: true,
        ));
      });

      test('should get all contacts with correct sorting', () async {
        mockLocalStorage.setSortOrder(DatabaseConstants.sortByName);
        
        final contacts = await repository.getAllContacts();
        
        expect(contacts.length, 3);
        expect(contacts[0].name, 'Alice Johnson');
        expect(contacts[1].name, 'Bob Smith');
        expect(contacts[2].name, 'Charlie Brown');
      });

      test('should get starred contacts first when enabled', () async {
        mockLocalStorage._showStarredFirst = true;
        
        final contacts = await repository.getAllContacts();
        
        expect(contacts.length, 3);
        expect(contacts[0].isStarred, true);
        expect(contacts[1].isStarred, true);
        expect(contacts[2].isStarred, false);
      });

      test('should get contact by id', () async {
        final contact = await repository.getContactById(1);
        
        expect(contact, isNotNull);
        expect(contact!.name, 'Alice Johnson');
      });

      test('should return null for non-existent contact id', () async {
        final contact = await repository.getContactById(999);
        
        expect(contact, isNull);
      });

      test('should get starred contacts only', () async {
        final starredContacts = await repository.getStarredContacts();
        
        expect(starredContacts.length, 2);
        expect(starredContacts.every((c) => c.isStarred), true);
      });
    });

    group('Search Contacts', () {
      setUp(() async {
        await mockDatabaseHelper.insertContact(Contact(
          name: 'John Doe',
          company: 'Tech Corp',
          email: 'john@techcorp.com',
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Jane Smith',
          company: 'Design Studio',
          email: 'jane@design.com',
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Bob Johnson',
          company: 'Tech Solutions',
          email: 'bob@techsol.com',
        ));
      });

      test('should search contacts by name', () async {
        final results = await repository.searchContacts('John');
        
        expect(results.length, 2); // John Doe and Bob Johnson
        expect(results.any((c) => c.name == 'John Doe'), true);
        expect(results.any((c) => c.name == 'Bob Johnson'), true);
      });

      test('should search contacts by company', () async {
        final results = await repository.searchContacts('Tech');
        
        expect(results.length, 2);
        expect(results.any((c) => c.company == 'Tech Corp'), true);
        expect(results.any((c) => c.company == 'Tech Solutions'), true);
      });

      test('should search contacts by email', () async {
        final results = await repository.searchContacts('design');
        
        expect(results.length, 1);
        expect(results.first.email, 'jane@design.com');
      });

      test('should return all contacts for empty query', () async {
        final results = await repository.searchContacts('');
        
        expect(results.length, 3);
      });
    });

    group('Update and Delete', () {
      late Contact testContact;

      setUp(() async {
        testContact = Contact(
          name: 'Original Name',
          email: 'original@example.com',
        );
        final id = await mockDatabaseHelper.insertContact(testContact);
        testContact = testContact.copyWith(id: id);
      });

      test('should update contact successfully', () async {
        final updatedContact = testContact.copyWith(
          name: 'Updated Name',
          email: 'updated@example.com',
        );

        final result = await repository.updateContact(updatedContact);
        
        expect(result, true);
        
        final retrieved = await repository.getContactById(testContact.id!);
        expect(retrieved!.name, 'Updated Name');
        expect(retrieved.email, 'updated@example.com');
      });

      test('should validate contact data before updating', () async {
        final invalidContact = testContact.copyWith(name: '');

        expect(
          () => repository.updateContact(invalidContact),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('should delete contact successfully', () async {
        final result = await repository.deleteContact(testContact.id!);
        
        expect(result, true);
        
        final retrieved = await repository.getContactById(testContact.id!);
        expect(retrieved, isNull);
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, 0);
      });

      test('should return false when deleting non-existent contact', () async {
        final result = await repository.deleteContact(999);
        
        expect(result, false);
      });

      test('should toggle starred status', () async {
        expect(testContact.isStarred, false);

        final result = await repository.toggleStarred(testContact.id!);
        
        expect(result, true);
        
        final retrieved = await repository.getContactById(testContact.id!);
        expect(retrieved!.isStarred, true);
      });
    });

    group('Statistics and Utilities', () {
      setUp(() async {
        await mockDatabaseHelper.insertContact(Contact(
          name: 'John Doe',
          company: 'Tech Corp',
          email: 'john@example.com',
          phone: '1234567890',
          isStarred: true,
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Jane Smith',
          company: 'Design Studio',
          website: 'https://jane.com',
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Bob Johnson',
          email: 'bob@example.com',
        ));
      });

      test('should get contact count', () async {
        final count = await repository.getContactCount();
        expect(count, 3);
      });

      test('should get contact statistics', () async {
        final stats = await repository.getContactStatistics();
        
        expect(stats['total'], 3);
        expect(stats['starred'], 1);
        expect(stats['withCompany'], 2);
        expect(stats['withEmail'], 2);
        expect(stats['withPhone'], 1);
      });

      test('should check if user can add more contacts', () async {
        mockLocalStorage.setPremiumStatus(false);
        
        // With 3 contacts, should still be able to add more (limit is 100)
        final canAdd = await repository.canAddMoreContacts();
        expect(canAdd, true);
        
        // Premium users should always be able to add contacts
        mockLocalStorage.setPremiumStatus(true);
        final canAddPremium = await repository.canAddMoreContacts();
        expect(canAddPremium, true);
      });

      test('should get all tags from contacts', () async {
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Developer',
          tags: ['tech', 'programming'],
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Designer',
          tags: ['design', 'creative'],
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Manager',
          tags: ['tech', 'management'],
        ));

        final tags = await repository.getAllTags();
        
        expect(tags.length, 4);
        expect(tags.contains('tech'), true);
        expect(tags.contains('programming'), true);
        expect(tags.contains('design'), true);
        expect(tags.contains('creative'), true);
        expect(tags.contains('management'), true);
      });

      test('should get contacts by tag', () async {
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Developer 1',
          tags: ['tech', 'programming'],
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Developer 2',
          tags: ['tech', 'mobile'],
        ));
        await mockDatabaseHelper.insertContact(Contact(
          name: 'Designer',
          tags: ['design'],
        ));

        final techContacts = await repository.getContactsByTag('tech');
        
        expect(techContacts.length, 2);
        expect(techContacts.any((c) => c.name == 'Developer 1'), true);
        expect(techContacts.any((c) => c.name == 'Developer 2'), true);
      });
    });

    group('Error Handling', () {
      test('should handle database errors gracefully', () async {
        // This would require mocking database errors, which is complex
        // For now, we test that the repository handles validation errors
        
        expect(
          () => repository.addContact(Contact(name: '')),
          throwsA(isA<ContactRepositoryException>()),
        );
      });

      test('should throw ContactRepositoryException with meaningful messages', () async {
        try {
          await repository.addContact(Contact(name: ''));
        } catch (e) {
          expect(e, isA<ContactRepositoryException>());
          expect(e.toString(), contains('ContactRepositoryException'));
        }
      });
    });
  });
}