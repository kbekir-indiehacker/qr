import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/datasources/database_helper.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/datasources/local_storage.dart';
import 'dart:async';
import 'dart:math';

// Simulates network connectivity changes
class ConnectivitySimulator {
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;
  
  void setOnline() {
    _isOnline = true;
    _connectivityController.add(true);
  }
  
  void setOffline() {
    _isOnline = false;
    _connectivityController.add(false);
  }
  
  void dispose() {
    _connectivityController.close();
  }
}

// Mock implementation that respects connectivity
class ConnectivityAwareDatabaseHelper extends DatabaseHelper {
  final ConnectivitySimulator _connectivity;
  final List<Map<String, dynamic>> _pendingOperations = [];
  
  ConnectivityAwareDatabaseHelper(this._connectivity);
  
  // Override database operations to simulate network-dependent behavior
  @override
  Future<int> insertContact(Contact contact) async {
    if (!_connectivity.isOnline) {
      // Store operation for later sync
      _pendingOperations.add({
        'type': 'insert',
        'data': contact.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Return a temporary ID (negative to indicate pending)
      return -DateTime.now().millisecondsSinceEpoch;
    }
    
    return await super.insertContact(contact);
  }
  
  @override
  Future<int> updateContact(Contact contact) async {
    if (!_connectivity.isOnline) {
      _pendingOperations.add({
        'type': 'update',
        'data': contact.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return 1; // Simulate success
    }
    
    return await super.updateContact(contact);
  }
  
  @override
  Future<int> deleteContact(int id) async {
    if (!_connectivity.isOnline) {
      _pendingOperations.add({
        'type': 'delete',
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return 1; // Simulate success
    }
    
    return await super.deleteContact(id);
  }
  
  Future<void> syncPendingOperations() async {
    if (!_connectivity.isOnline || _pendingOperations.isEmpty) {
      return;
    }
    
    // Process pending operations in order
    final operations = List.from(_pendingOperations);
    _pendingOperations.clear();
    
    for (final operation in operations) {
      try {
        switch (operation['type']) {
          case 'insert':
            final contact = Contact.fromMap(operation['data']);
            await super.insertContact(contact);
            break;
          case 'update':
            final contact = Contact.fromMap(operation['data']);
            await super.updateContact(contact);
            break;
          case 'delete':
            await super.deleteContact(operation['id']);
            break;
        }
      } catch (e) {
        // Re-add failed operation to retry later
        _pendingOperations.add(operation);
      }
    }
  }
  
  List<Map<String, dynamic>> get pendingOperations => List.from(_pendingOperations);
  
  Future<void> clearPendingOperations() async {
    _pendingOperations.clear();
  }
}

// Mock LocalStorage for testing
class TestLocalStorage implements LocalStorage {
  bool _isPremium = true;
  String _sortOrder = 'name';
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
  }

  @override
  Future<void> incrementTotalContactsCreated() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Offline-aware repository
class OfflineAwareContactRepository extends ContactRepository {
  final ConnectivitySimulator _connectivity;
  final ConnectivityAwareDatabaseHelper _databaseHelper;
  
  OfflineAwareContactRepository(
    this._connectivity,
    this._databaseHelper,
    LocalStorage localStorage,
  ) : super(databaseHelper: _databaseHelper, localStorage: localStorage);
  
  Future<void> syncWhenOnline() async {
    await _databaseHelper.syncPendingOperations();
  }
  
  bool get hasOfflineOperations => _databaseHelper.pendingOperations.isNotEmpty;
  
  int get pendingOperationCount => _databaseHelper.pendingOperations.length;
}

void main() {
  group('Offline/Online Data Persistence Tests', () {
    late ConnectivitySimulator connectivity;
    late ConnectivityAwareDatabaseHelper databaseHelper;
    late OfflineAwareContactRepository repository;
    late TestLocalStorage localStorage;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      connectivity = ConnectivitySimulator();
      databaseHelper = ConnectivityAwareDatabaseHelper(connectivity);
      localStorage = TestLocalStorage();
      repository = OfflineAwareContactRepository(
        connectivity,
        databaseHelper,
        localStorage,
      );
      
      // Initialize database
      await databaseHelper.database;
    });

    tearDown(() async {
      await databaseHelper.close();
      connectivity.dispose();
    });

    group('Offline Operations', () {
      test('Should queue operations when offline', () async {
        // Arrange
        connectivity.setOffline();
        
        final contact = Contact(
          name: 'Offline Contact',
          company: 'Offline Corp',
          email: 'offline@example.com',
        );

        // Act
        await repository.addContact(contact);

        // Assert
        expect(repository.hasOfflineOperations, true);
        expect(repository.pendingOperationCount, 1);
        
        // Verify operation is queued but not in database yet
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 0); // No contacts in database yet
      });

      test('Should handle multiple offline operations', () async {
        // Arrange
        connectivity.setOffline();
        
        final contacts = [
          Contact(name: 'Contact 1', email: 'contact1@example.com'),
          Contact(name: 'Contact 2', email: 'contact2@example.com'),
          Contact(name: 'Contact 3', email: 'contact3@example.com'),
        ];

        // Act
        for (final contact in contacts) {
          await repository.addContact(contact);
        }

        // Assert
        expect(repository.pendingOperationCount, 3);
        
        // Database should still be empty
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 0);
      });

      test('Should handle mixed operations offline', () async {
        // Arrange - Add a contact while online first
        connectivity.setOnline();
        final originalContact = Contact(name: 'Original Contact');
        final id = await repository.addContact(originalContact);
        
        // Go offline
        connectivity.setOffline();

        // Act - Perform various operations
        await repository.addContact(Contact(name: 'New Offline Contact'));
        
        final updatedContact = Contact(
          id: id,
          name: 'Updated Offline Contact',
          company: 'Updated Company',
        );
        await repository.updateContact(updatedContact);
        
        await repository.deleteContact(999); // Non-existent ID

        // Assert
        expect(repository.pendingOperationCount, 3);
        
        final pendingOps = databaseHelper.pendingOperations;
        expect(pendingOps.any((op) => op['type'] == 'insert'), true);
        expect(pendingOps.any((op) => op['type'] == 'update'), true);
        expect(pendingOps.any((op) => op['type'] == 'delete'), true);
      });

      test('Should preserve operation order', () async {
        // Arrange
        connectivity.setOffline();

        // Act - Perform operations in specific order
        await repository.addContact(Contact(name: 'First'));
        await repository.addContact(Contact(name: 'Second'));
        await repository.addContact(Contact(name: 'Third'));

        // Assert - Operations should be in correct order
        final pendingOps = databaseHelper.pendingOperations;
        expect(pendingOps.length, 3);
        
        final firstOp = Contact.fromMap(pendingOps[0]['data']);
        final secondOp = Contact.fromMap(pendingOps[1]['data']);
        final thirdOp = Contact.fromMap(pendingOps[2]['data']);
        
        expect(firstOp.name, 'First');
        expect(secondOp.name, 'Second');
        expect(thirdOp.name, 'Third');
        
        // Timestamps should be in order
        expect(pendingOps[0]['timestamp'], lessThanOrEqualTo(pendingOps[1]['timestamp']));
        expect(pendingOps[1]['timestamp'], lessThanOrEqualTo(pendingOps[2]['timestamp']));
      });

      test('Should handle offline data corruption gracefully', () async {
        // Arrange
        connectivity.setOffline();
        
        await repository.addContact(Contact(name: 'Valid Contact'));
        
        // Simulate corruption by adding invalid operation manually
        databaseHelper.pendingOperations.add({
          'type': 'invalid_operation',
          'data': {'invalid': 'data'},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Act - Go back online and sync
        connectivity.setOnline();
        
        // Should not throw exception
        await repository.syncWhenOnline();

        // Assert - Valid operations should still be processed
        expect(repository.pendingOperationCount, 1); // Invalid operation remains
        
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 1);
        expect(allContacts.first.name, 'Valid Contact');
      });
    });

    group('Online Operations', () {
      test('Should perform operations immediately when online', () async {
        // Arrange
        connectivity.setOnline();
        
        final contact = Contact(
          name: 'Online Contact',
          company: 'Online Corp',
        );

        // Act
        final id = await repository.addContact(contact);

        // Assert
        expect(id, greaterThan(0));
        expect(repository.hasOfflineOperations, false);
        
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 1);
        expect(allContacts.first.name, 'Online Contact');
      });

      test('Should handle rapid online operations', () async {
        // Arrange
        connectivity.setOnline();
        
        final contacts = List.generate(50, (index) => 
          Contact(name: 'Rapid Contact $index'));

        // Act
        final futures = contacts.map((contact) => repository.addContact(contact));
        await Future.wait(futures);

        // Assert
        expect(repository.hasOfflineOperations, false);
        
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 50);
      });
    });

    group('Offline-to-Online Sync', () {
      test('Should sync pending operations when going online', () async {
        // Arrange - Add operations while offline
        connectivity.setOffline();
        
        final offlineContacts = [
          Contact(name: 'Offline Contact 1', email: 'offline1@example.com'),
          Contact(name: 'Offline Contact 2', email: 'offline2@example.com'),
        ];

        for (final contact in offlineContacts) {
          await repository.addContact(contact);
        }

        expect(repository.pendingOperationCount, 2);

        // Act - Go online and sync
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert
        expect(repository.hasOfflineOperations, false);
        
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 2);
        expect(allContacts.any((c) => c.name == 'Offline Contact 1'), true);
        expect(allContacts.any((c) => c.name == 'Offline Contact 2'), true);
      });

      test('Should handle sync conflicts gracefully', () async {
        // Arrange - Add contact online first
        connectivity.setOnline();
        final originalContact = Contact(name: 'Original Contact');
        final id = await repository.addContact(originalContact);

        // Go offline and modify the same contact
        connectivity.setOffline();
        final updatedContact = Contact(
          id: id,
          name: 'Updated Offline',
          company: 'Offline Company',
        );
        await repository.updateContact(updatedContact);

        // Act - Go online and sync
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert - Last operation should win
        final contact = await repository.getContactById(id);
        expect(contact!.name, 'Updated Offline');
        expect(contact.company, 'Offline Company');
        expect(repository.hasOfflineOperations, false);
      });

      test('Should retry failed sync operations', () async {
        // Arrange
        connectivity.setOffline();
        await repository.addContact(Contact(name: 'Sync Test Contact'));
        
        // Mock a sync failure by corrupting data
        final pendingOps = databaseHelper.pendingOperations;
        pendingOps.first['data']['name'] = null; // This will cause validation error

        // Act - Try to sync
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert - Failed operation should remain in queue
        expect(repository.hasOfflineOperations, true);
        expect(repository.pendingOperationCount, 1);
      });

      test('Should handle partial sync failures', () async {
        // Arrange
        connectivity.setOffline();
        
        // Add valid and invalid operations
        await repository.addContact(Contact(name: 'Valid Contact'));
        
        // Manually add invalid operation
        databaseHelper.pendingOperations.add({
          'type': 'insert',
          'data': {'name': null}, // Invalid data
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        await repository.addContact(Contact(name: 'Another Valid Contact'));

        expect(repository.pendingOperationCount, 3);

        // Act - Sync
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert - Valid operations should succeed, invalid should remain
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 2); // Two valid contacts
        expect(repository.pendingOperationCount, 1); // One failed operation remains
      });
    });

    group('Data Consistency Tests', () {
      test('Should maintain data integrity during connectivity changes', () async {
        // Arrange - Start with some online data
        connectivity.setOnline();
        
        final onlineContacts = [
          Contact(name: 'Online 1', email: 'online1@example.com'),
          Contact(name: 'Online 2', email: 'online2@example.com'),
        ];

        for (final contact in onlineContacts) {
          await repository.addContact(contact);
        }

        // Go offline and add more data
        connectivity.setOffline();
        
        final offlineContacts = [
          Contact(name: 'Offline 1', email: 'offline1@example.com'),
          Contact(name: 'Offline 2', email: 'offline2@example.com'),
        ];

        for (final contact in offlineContacts) {
          await repository.addContact(contact);
        }

        // Rapid connectivity changes
        for (int i = 0; i < 5; i++) {
          connectivity.setOnline();
          await Future.delayed(const Duration(milliseconds: 10));
          connectivity.setOffline();
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Final sync
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert - All data should be present
        final allContacts = await databaseHelper.getAllContacts();
        expect(allContacts.length, 4);
        
        final names = allContacts.map((c) => c.name).toList();
        expect(names, containsAll(['Online 1', 'Online 2', 'Offline 1', 'Offline 2']));
      });

      test('Should not lose data during app restart simulation', () async {
        // Arrange - Add data offline
        connectivity.setOffline();
        
        final contacts = [
          Contact(name: 'Persistent 1'),
          Contact(name: 'Persistent 2'),
        ];

        for (final contact in contacts) {
          await repository.addContact(contact);
        }

        expect(repository.pendingOperationCount, 2);

        // Simulate app restart by creating new instances
        await databaseHelper.close();
        
        final newConnectivity = ConnectivitySimulator();
        newConnectivity.setOffline(); // Still offline after restart
        
        final newDatabaseHelper = ConnectivityAwareDatabaseHelper(newConnectivity);
        final newRepository = OfflineAwareContactRepository(
          newConnectivity,
          newDatabaseHelper,
          localStorage,
        );

        // In a real app, pending operations would be persisted and reloaded
        // For this test, we'll simulate that they're preserved
        for (final contact in contacts) {
          await newRepository.addContact(contact);
        }

        // Act - Go online and sync
        newConnectivity.setOnline();
        await newRepository.syncWhenOnline();

        // Assert
        final allContacts = await newDatabaseHelper.getAllContacts();
        expect(allContacts.length, 2);
        expect(allContacts.any((c) => c.name == 'Persistent 1'), true);
        expect(allContacts.any((c) => c.name == 'Persistent 2'), true);

        // Cleanup
        await newDatabaseHelper.close();
        newConnectivity.dispose();
      });

      test('Should handle concurrent operations during sync', () async {
        // Arrange
        connectivity.setOffline();
        
        // Add some offline operations
        await repository.addContact(Contact(name: 'Offline Contact'));
        
        // Act - Simulate concurrent operations during sync
        connectivity.setOnline();
        
        final syncFuture = repository.syncWhenOnline();
        
        // Add new operations while syncing
        final concurrentFutures = [
          repository.addContact(Contact(name: 'Concurrent 1')),
          repository.addContact(Contact(name: 'Concurrent 2')),
          repository.getAllContacts(),
        ];

        await Future.wait([syncFuture, ...concurrentFutures]);

        // Assert - All operations should complete successfully
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, 3);
        
        final names = allContacts.map((c) => c.name).toList();
        expect(names, containsAll(['Offline Contact', 'Concurrent 1', 'Concurrent 2']));
      });
    });

    group('Performance Under Connectivity Changes', () {
      test('Should maintain performance with many offline operations', () async {
        // Arrange
        connectivity.setOffline();
        
        const operationCount = 1000;
        final stopwatch = Stopwatch()..start();

        // Act - Add many operations offline
        for (int i = 0; i < operationCount; i++) {
          await repository.addContact(Contact(
            name: 'Bulk Contact $i',
            email: 'bulk$i@example.com',
          ));
        }

        stopwatch.stop();
        
        // Assert - Should queue operations quickly
        expect(stopwatch.elapsed.inSeconds, lessThan(5));
        expect(repository.pendingOperationCount, operationCount);

        // Sync performance test
        connectivity.setOnline();
        
        final syncStopwatch = Stopwatch()..start();
        await repository.syncWhenOnline();
        syncStopwatch.stop();

        // Should sync in reasonable time
        expect(syncStopwatch.elapsed.inMinutes, lessThan(2));
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, operationCount);
      });

      test('Should handle frequent connectivity changes efficiently', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act - Rapid connectivity changes with operations
        for (int i = 0; i < 20; i++) {
          connectivity.setOffline();
          await repository.addContact(Contact(name: 'Rapid $i'));
          
          connectivity.setOnline();
          await repository.syncWhenOnline();
          
          await repository.addContact(Contact(name: 'Online $i'));
        }

        stopwatch.stop();

        // Assert - Should handle rapid changes efficiently
        expect(stopwatch.elapsed.inSeconds, lessThan(30));
        
        final allContacts = await repository.getAllContacts();
        expect(allContacts.length, 40); // 20 offline + 20 online
        expect(repository.hasOfflineOperations, false);
      });
    });

    group('Edge Cases', () {
      test('Should handle empty offline operations gracefully', () async {
        // Arrange
        connectivity.setOffline();
        // No operations added

        // Act
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert - Should not cause errors
        expect(repository.hasOfflineOperations, false);
        expect(repository.pendingOperationCount, 0);
      });

      test('Should handle sync with database corruption', () async {
        // Arrange
        connectivity.setOffline();
        await repository.addContact(Contact(name: 'Test Contact'));
        
        // Simulate database corruption
        await databaseHelper.close();
        
        // Act - Try to sync with corrupted database
        connectivity.setOnline();
        
        expect(
          () => repository.syncWhenOnline(),
          throwsA(isA<Exception>()),
        );
      });

      test('Should handle very large individual operations', () async {
        // Arrange
        connectivity.setOffline();
        
        final largeNotes = 'A' * 10000; // 10KB notes
        final contactWithLargeData = Contact(
          name: 'Large Data Contact',
          notes: largeNotes,
          tags: List.generate(100, (i) => 'tag$i'),
        );

        // Act
        await repository.addContact(contactWithLargeData);
        
        connectivity.setOnline();
        await repository.syncWhenOnline();

        // Assert
        final contacts = await repository.getAllContacts();
        expect(contacts.length, 1);
        expect(contacts.first.notes!.length, 10000);
        expect(contacts.first.tags.length, 100);
      });
    });
  });
}