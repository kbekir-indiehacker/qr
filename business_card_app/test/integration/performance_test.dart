import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/datasources/database_helper.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/datasources/local_storage.dart';
import 'dart:math';

// Performance test utility
class PerformanceTest {
  static Future<Duration> measureTime(Future Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  static void printPerformanceResult(String operation, Duration duration, {int? itemCount}) {
    print('$operation: ${duration.inMilliseconds}ms');
    if (itemCount != null) {
      final perItem = duration.inMicroseconds / itemCount;
      print('  Per item: ${perItem.toStringAsFixed(2)}μs');
    }
  }
}

// Test data generator
class TestDataGenerator {
  static final Random _random = Random();
  static final List<String> _firstNames = [
    'John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana', 'Eve', 'Frank',
    'Grace', 'Henry', 'Ivy', 'Jack', 'Kate', 'Liam', 'Mia', 'Noah',
    'Olivia', 'Peter', 'Quinn', 'Ruby', 'Sam', 'Tina', 'Uma', 'Victor',
    'Wendy', 'Xavier', 'Yara', 'Zoe', 'Alex', 'Blake', 'Casey', 'Drew'
  ];
  
  static final List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
    'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark',
    'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young', 'Allen', 'King'
  ];
  
  static final List<String> _companies = [
    'Tech Corp', 'Design Studio', 'Marketing Inc', 'Data Solutions',
    'Creative Agency', 'Software Systems', 'Digital Media', 'Innovation Labs',
    'Cloud Services', 'Mobile Apps', 'Web Development', 'AI Research',
    'Blockchain Tech', 'Cyber Security', 'Game Studio', 'E-commerce',
    'Healthcare Tech', 'Finance Group', 'Education Platform', 'Social Network'
  ];
  
  static final List<String> _titles = [
    'Software Engineer', 'Product Manager', 'UX Designer', 'Data Scientist',
    'Marketing Director', 'Sales Manager', 'DevOps Engineer', 'QA Tester',
    'Business Analyst', 'Project Manager', 'CEO', 'CTO', 'CFO', 'VP Sales',
    'Lead Developer', 'Senior Designer', 'Account Manager', 'Consultant'
  ];
  
  static final List<String> _domains = [
    'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'company.com',
    'business.org', 'startup.io', 'tech.net', 'digital.co', 'innovation.ai'
  ];
  
  static final List<String> _tags = [
    'tech', 'business', 'design', 'marketing', 'sales', 'development',
    'management', 'consulting', 'finance', 'healthcare', 'education',
    'startup', 'enterprise', 'freelance', 'remote', 'client', 'partner'
  ];

  static Contact generateContact({int? id}) {
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    final name = '$firstName $lastName';
    
    final company = _random.nextBool() 
        ? _companies[_random.nextInt(_companies.length)] 
        : null;
    
    final title = _random.nextBool() 
        ? _titles[_random.nextInt(_titles.length)] 
        : null;
    
    final email = _random.nextBool() 
        ? '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${_domains[_random.nextInt(_domains.length)]}'
        : null;
    
    final phone = _random.nextBool() 
        ? '+1${_random.nextInt(900) + 100}${_random.nextInt(900) + 100}${_random.nextInt(10000).toString().padLeft(4, '0')}'
        : null;
    
    final website = _random.nextBool() && company != null
        ? 'https://${company.toLowerCase().replaceAll(' ', '')}.com'
        : null;
    
    final tagCount = _random.nextInt(4);
    final tags = <String>[];
    for (int i = 0; i < tagCount; i++) {
      final tag = _tags[_random.nextInt(_tags.length)];
      if (!tags.contains(tag)) {
        tags.add(tag);
      }
    }
    
    final notes = _random.nextBool() 
        ? 'Random notes for $name - ${_random.nextInt(1000)}'
        : null;
    
    return Contact(
      id: id,
      name: name,
      company: company,
      title: title,
      phone: phone,
      email: email,
      website: website,
      tags: tags,
      notes: notes,
      isStarred: _random.nextDouble() < 0.1, // 10% starred
    );
  }

  static List<Contact> generateContacts(int count) {
    return List.generate(count, (index) => generateContact());
  }
}

// Mock LocalStorage for testing
class TestLocalStorage implements LocalStorage {
  @override
  Future<bool> getPremiumStatus() async => true;

  @override
  Future<String> getSortOrder() async => 'name';

  @override
  Future<bool> getShowStarredFirst() async => false;

  @override
  Future<void> addRecentSearch(String query) async {}

  @override
  Future<void> incrementTotalContactsCreated() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Performance Tests', () {
    late DatabaseHelper databaseHelper;
    late ContactRepository repository;
    late TestLocalStorage localStorage;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseHelper = DatabaseHelper();
      localStorage = TestLocalStorage();
      repository = ContactRepository(
        databaseHelper: databaseHelper,
        localStorage: localStorage,
      );
      await databaseHelper.database;
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('Bulk Insert Performance', () {
      test('Should insert 1000 contacts efficiently', () async {
        const contactCount = 1000;
        final contacts = TestDataGenerator.generateContacts(contactCount);
        
        print('\n=== BULK INSERT TEST (1000 contacts) ===');
        
        // Measure individual inserts
        final duration = await PerformanceTest.measureTime(() async {
          for (final contact in contacts) {
            await repository.addContact(contact);
          }
        });
        
        PerformanceTest.printPerformanceResult(
          'Individual inserts', duration, itemCount: contactCount);
        
        // Verify all contacts were inserted
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, contactCount);
        
        // Performance expectations
        expect(duration.inSeconds, lessThan(30)); // Should complete in under 30 seconds
        expect(duration.inMilliseconds / contactCount, lessThan(30)); // Under 30ms per contact
      });

      test('Should handle batch inserts efficiently', () async {
        const batchSize = 100;
        const batchCount = 10;
        final contacts = TestDataGenerator.generateContacts(batchSize * batchCount);
        
        print('\n=== BATCH INSERT TEST (10 batches of 100) ===');
        
        final duration = await PerformanceTest.measureTime(() async {
          for (int i = 0; i < batchCount; i++) {
            final batch = contacts.skip(i * batchSize).take(batchSize);
            final futures = batch.map((contact) => repository.addContact(contact));
            await Future.wait(futures);
          }
        });
        
        PerformanceTest.printPerformanceResult(
          'Batch inserts', duration, itemCount: contacts.length);
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, contacts.length);
      });
    });

    group('Query Performance', () {
      late List<Contact> testContacts;

      setUp(() async {
        // Insert test data
        testContacts = TestDataGenerator.generateContacts(1000);
        for (final contact in testContacts) {
          await repository.addContact(contact);
        }
      });

      test('Should retrieve all contacts efficiently', () async {
        print('\n=== RETRIEVE ALL TEST (1000 contacts) ===');
        
        final duration = await PerformanceTest.measureTime(() async {
          final contacts = await repository.getAllContacts();
          expect(contacts.length, 1000);
        });
        
        PerformanceTest.printPerformanceResult('Get all contacts', duration);
        expect(duration.inMilliseconds, lessThan(500)); // Under 500ms
      });

      test('Should search contacts efficiently', () async {
        print('\n=== SEARCH TEST ===');
        
        final searchQueries = ['John', 'Tech', 'gmail', 'Manager', 'Smith'];
        
        for (final query in searchQueries) {
          final duration = await PerformanceTest.measureTime(() async {
            final results = await repository.searchContacts(query);
            expect(results, isA<List<Contact>>());
          });
          
          PerformanceTest.printPerformanceResult('Search "$query"', duration);
          expect(duration.inMilliseconds, lessThan(200)); // Under 200ms per search
        }
      });

      test('Should get contact by ID efficiently', () async {
        print('\n=== GET BY ID TEST ===');
        
        final allContacts = await repository.getAllContacts();
        final randomIds = List.generate(100, (index) => 
          allContacts[Random().nextInt(allContacts.length)].id!);
        
        final duration = await PerformanceTest.measureTime(() async {
          for (final id in randomIds) {
            final contact = await repository.getContactById(id);
            expect(contact, isNotNull);
          }
        });
        
        PerformanceTest.printPerformanceResult('Get by ID (100 queries)', duration, itemCount: 100);
        expect(duration.inMilliseconds / 100, lessThan(5)); // Under 5ms per query
      });

      test('Should get starred contacts efficiently', () async {
        print('\n=== GET STARRED TEST ===');
        
        final duration = await PerformanceTest.measureTime(() async {
          final starredContacts = await repository.getStarredContacts();
          expect(starredContacts, isA<List<Contact>>());
        });
        
        PerformanceTest.printPerformanceResult('Get starred contacts', duration);
        expect(duration.inMilliseconds, lessThan(100)); // Under 100ms
      });

      test('Should calculate statistics efficiently', () async {
        print('\n=== STATISTICS TEST ===');
        
        final duration = await PerformanceTest.measureTime(() async {
          final stats = await repository.getContactStatistics();
          expect(stats['total'], 1000);
        });
        
        PerformanceTest.printPerformanceResult('Calculate statistics', duration);
        expect(duration.inMilliseconds, lessThan(200)); // Under 200ms
      });
    });

    group('Update Performance', () {
      late List<Contact> testContacts;

      setUp(() async {
        testContacts = TestDataGenerator.generateContacts(100);
        for (final contact in testContacts) {
          await repository.addContact(contact);
        }
      });

      test('Should update contacts efficiently', () async {
        print('\n=== UPDATE TEST (100 contacts) ===');
        
        final allContacts = await repository.getAllContacts();
        
        final duration = await PerformanceTest.measureTime(() async {
          for (final contact in allContacts) {
            final updatedContact = contact.copyWith(
              notes: 'Updated at ${DateTime.now()}',
              isStarred: !contact.isStarred,
            );
            await repository.updateContact(updatedContact);
          }
        });
        
        PerformanceTest.printPerformanceResult('Update contacts', duration, itemCount: 100);
        expect(duration.inMilliseconds / 100, lessThan(20)); // Under 20ms per update
      });

      test('Should toggle starred status efficiently', () async {
        print('\n=== TOGGLE STARRED TEST (100 contacts) ===');
        
        final allContacts = await repository.getAllContacts();
        
        final duration = await PerformanceTest.measureTime(() async {
          for (final contact in allContacts) {
            await repository.toggleStarred(contact.id!);
          }
        });
        
        PerformanceTest.printPerformanceResult('Toggle starred', duration, itemCount: 100);
        expect(duration.inMilliseconds / 100, lessThan(15)); // Under 15ms per toggle
      });
    });

    group('Delete Performance', () {
      test('Should delete contacts efficiently', () async {
        // Insert test data
        final contacts = TestDataGenerator.generateContacts(100);
        final ids = <int>[];
        
        for (final contact in contacts) {
          final id = await repository.addContact(contact);
          ids.add(id);
        }
        
        print('\n=== DELETE TEST (100 contacts) ===');
        
        final duration = await PerformanceTest.measureTime(() async {
          for (final id in ids) {
            await repository.deleteContact(id);
          }
        });
        
        PerformanceTest.printPerformanceResult('Delete contacts', duration, itemCount: 100);
        expect(duration.inMilliseconds / 100, lessThan(10)); // Under 10ms per delete
        
        // Verify all contacts were deleted
        final remainingContacts = await repository.getAllContacts();
        expect(remainingContacts.length, 0);
      });
    });

    group('Memory Performance', () {
      test('Should handle large datasets without memory issues', () async {
        print('\n=== MEMORY TEST (5000 contacts) ===');
        
        const largeCount = 5000;
        
        // Insert large dataset
        final insertDuration = await PerformanceTest.measureTime(() async {
          final contacts = TestDataGenerator.generateContacts(largeCount);
          
          // Insert in batches to avoid overwhelming the system
          const batchSize = 100;
          for (int i = 0; i < contacts.length; i += batchSize) {
            final batch = contacts.skip(i).take(batchSize);
            final futures = batch.map((contact) => repository.addContact(contact));
            await Future.wait(futures);
          }
        });
        
        PerformanceTest.printPerformanceResult('Large insert', insertDuration, itemCount: largeCount);
        
        // Test retrieval
        final retrievalDuration = await PerformanceTest.measureTime(() async {
          final allContacts = await repository.getAllContacts();
          expect(allContacts.length, largeCount);
        });
        
        PerformanceTest.printPerformanceResult('Large retrieval', retrievalDuration);
        
        // Performance expectations for large dataset
        expect(insertDuration.inMinutes, lessThan(5)); // Under 5 minutes
        expect(retrievalDuration.inSeconds, lessThan(10)); // Under 10 seconds
      });
    });

    group('Concurrent Performance', () {
      test('Should handle concurrent operations efficiently', () async {
        print('\n=== CONCURRENT TEST ===');
        
        const operationCount = 50;
        
        final duration = await PerformanceTest.measureTime(() async {
          final futures = <Future>[];
          
          // Concurrent inserts
          for (int i = 0; i < operationCount; i++) {
            final contact = TestDataGenerator.generateContact();
            futures.add(repository.addContact(contact));
          }
          
          // Concurrent reads (after some data exists)
          if (futures.length > 10) {
            for (int i = 0; i < 10; i++) {
              futures.add(repository.getAllContacts());
            }
          }
          
          await Future.wait(futures);
        });
        
        PerformanceTest.printPerformanceResult('Concurrent operations', duration, itemCount: operationCount + 10);
        expect(duration.inSeconds, lessThan(15)); // Under 15 seconds for all operations
      });
    });

    group('Edge Case Performance', () {
      test('Should handle contacts with large data efficiently', () async {
        print('\n=== LARGE DATA TEST ===');
        
        // Create contact with large fields
        final largeNotes = 'A' * 5000; // 5KB notes
        final largeTags = List.generate(10, (i) => 'very-long-tag-name-$i-with-lots-of-characters');
        final largeSocialMedia = Map.fromEntries(
          List.generate(20, (i) => MapEntry('platform$i', 'user$i')),
        );
        
        final largeContact = Contact(
          name: 'Large Data Contact',
          company: 'Very Long Company Name That Goes On And On',
          title: 'Senior Executive Vice President of Large Data Management',
          notes: largeNotes,
          tags: largeTags,
          socialMedia: largeSocialMedia,
        );
        
        final duration = await PerformanceTest.measureTime(() async {
          final id = await repository.addContact(largeContact);
          final retrieved = await repository.getContactById(id);
          expect(retrieved!.notes!.length, 5000);
          expect(retrieved.tags.length, 10);
          expect(retrieved.socialMedia!.length, 20);
        });
        
        PerformanceTest.printPerformanceResult('Large data contact', duration);
        expect(duration.inMilliseconds, lessThan(100)); // Under 100ms
      });

      test('Should handle empty and null data efficiently', () async {
        print('\n=== EMPTY DATA TEST ===');
        
        final emptyContacts = List.generate(100, (i) => Contact(
          name: 'Empty Contact $i',
          // All other fields are null/empty
        ));
        
        final duration = await PerformanceTest.measureTime(() async {
          for (final contact in emptyContacts) {
            await repository.addContact(contact);
          }
          
          final allContacts = await repository.getAllContacts();
          expect(allContacts.length, 100);
        });
        
        PerformanceTest.printPerformanceResult('Empty data contacts', duration, itemCount: 100);
        expect(duration.inSeconds, lessThan(5)); // Under 5 seconds
      });
    });
  });
}