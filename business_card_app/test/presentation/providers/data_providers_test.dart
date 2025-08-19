import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/repositories/user_repository.dart';
import 'package:business_card_app/data/repositories/settings_repository.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';

// Mock repositories
class MockContactRepository implements ContactRepositoryInterface {
  final List<Contact> _contacts = [];
  int _nextId = 1;

  @override
  Future<List<Contact>> getAllContacts() async {
    return List.from(_contacts);
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
  Future<int> addContact(Contact contact) async {
    final newContact = contact.copyWith(id: _nextId++);
    _contacts.add(newContact);
    return newContact.id!;
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteContact(int id) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return getAllContacts();
    return _contacts.where((c) => 
      c.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<List<Contact>> getStarredContacts() async {
    return _contacts.where((c) => c.isStarred).toList();
  }

  @override
  Future<int> getContactCount() async {
    return _contacts.length;
  }

  @override
  Future<bool> canAddMoreContacts() async {
    return true; // Always allow for testing
  }

  Future<bool> toggleStarred(int contactId) async {
    final contact = await getContactById(contactId);
    if (contact == null) return false;
    
    final updated = contact.copyWith(isStarred: !contact.isStarred);
    return await updateContact(updated);
  }

  Future<Map<String, int>> getContactStatistics() async {
    final contacts = await getAllContacts();
    return {
      'total': contacts.length,
      'starred': contacts.where((c) => c.isStarred).length,
      'withCompany': contacts.where((c) => c.hasCompany).length,
      'withEmail': contacts.where((c) => c.hasEmail).length,
      'withPhone': contacts.where((c) => c.hasPhoneNumber).length,
    };
  }

  Future<List<String>> getAllTags() async {
    final contacts = await getAllContacts();
    final allTags = <String>{};
    for (final contact in contacts) {
      allTags.addAll(contact.tags);
    }
    return allTags.toList()..sort();
  }
}

class MockUserRepository implements UserRepositoryInterface {
  UserData _userData = UserData(
    name: 'Test User',
    email: 'test@example.com',
    isPremium: false,
    isFirstLaunch: true,
    tutorialCompleted: false,
    appVersion: '1.0.0',
  );

  @override
  Future<UserData> getUserData() async => _userData;

  @override
  Future<void> updateUserData(UserData userData) async {
    _userData = userData;
  }

  @override
  Future<bool> isPremiumUser() async => _userData.isPremium;

  @override
  Future<void> setPremiumStatus(bool isPremium, DateTime? expiryDate) async {
    _userData = _userData.copyWith(
      isPremium: isPremium,
      premiumExpiryDate: expiryDate,
    );
  }

  @override
  Future<bool> isFirstLaunch() async => _userData.isFirstLaunch;

  @override
  Future<void> setFirstLaunchCompleted() async {
    _userData = _userData.copyWith(isFirstLaunch: false);
  }

  @override
  Future<bool> isTutorialCompleted() async => _userData.tutorialCompleted;

  @override
  Future<void> setTutorialCompleted() async {
    _userData = _userData.copyWith(tutorialCompleted: true);
  }
}

class MockSettingsRepository implements SettingsRepositoryInterface {
  AppSettings _settings = AppSettings.defaultSettings();

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> updateThemeMode(String themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
  }

  @override
  Future<void> updateSortOrder(String sortOrder) async {
    _settings = _settings.copyWith(sortOrder: sortOrder);
  }

  @override
  Future<void> updateContactViewMode(String viewMode) async {
    _settings = _settings.copyWith(contactViewMode: viewMode);
  }

  @override
  Future<void> resetToDefaults() async {
    _settings = AppSettings.defaultSettings();
  }

  Future<List<String>> getRecentSearches() async => [];

  Future<bool> shouldAutoBackup() async => _settings.autoBackup;
}

void main() {
  group('Data Providers Tests', () {
    late ProviderContainer container;
    late MockContactRepository mockContactRepository;
    late MockUserRepository mockUserRepository;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockContactRepository = MockContactRepository();
      mockUserRepository = MockUserRepository();
      mockSettingsRepository = MockSettingsRepository();

      container = ProviderContainer(
        overrides: [
          contactRepositoryProvider.overrideWithValue(mockContactRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('ContactsProvider', () {
      test('should load contacts on initialization', () async {
        // Add test contacts
        await mockContactRepository.addContact(Contact(name: 'John Doe'));
        await mockContactRepository.addContact(Contact(name: 'Jane Smith'));

        final contactsNotifier = container.read(contactsProvider.notifier);
        await contactsNotifier.loadContacts();

        final contactsState = container.read(contactsProvider);
        expect(contactsState.hasValue, true);
        expect(contactsState.value!.length, 2);
        expect(contactsState.value![0].name, 'John Doe');
        expect(contactsState.value![1].name, 'Jane Smith');
      });

      test('should add contact and refresh list', () async {
        final contactsNotifier = container.read(contactsProvider.notifier);
        
        final newContact = Contact(name: 'New Contact');
        await contactsNotifier.addContact(newContact);

        final contactsState = container.read(contactsProvider);
        expect(contactsState.hasValue, true);
        expect(contactsState.value!.length, 1);
        expect(contactsState.value![0].name, 'New Contact');
      });

      test('should update contact and refresh list', () async {
        // Add initial contact
        await mockContactRepository.addContact(Contact(name: 'Original Name'));
        
        final contactsNotifier = container.read(contactsProvider.notifier);
        await contactsNotifier.loadContacts();

        // Update contact
        final contacts = container.read(contactsProvider).value!;
        final updatedContact = contacts[0].copyWith(name: 'Updated Name');
        await contactsNotifier.updateContact(updatedContact);

        final contactsState = container.read(contactsProvider);
        expect(contactsState.value![0].name, 'Updated Name');
      });

      test('should delete contact and refresh list', () async {
        // Add initial contact
        final id = await mockContactRepository.addContact(Contact(name: 'To Delete'));
        
        final contactsNotifier = container.read(contactsProvider.notifier);
        await contactsNotifier.loadContacts();

        expect(container.read(contactsProvider).value!.length, 1);

        // Delete contact
        await contactsNotifier.deleteContact(id);

        final contactsState = container.read(contactsProvider);
        expect(contactsState.value!.length, 0);
      });

      test('should toggle starred status', () async {
        // Add initial contact
        final id = await mockContactRepository.addContact(
          Contact(name: 'Test', isStarred: false)
        );
        
        final contactsNotifier = container.read(contactsProvider.notifier);
        await contactsNotifier.loadContacts();

        expect(container.read(contactsProvider).value![0].isStarred, false);

        // Toggle starred
        await contactsNotifier.toggleStarred(id);

        final contactsState = container.read(contactsProvider);
        expect(contactsState.value![0].isStarred, true);
      });
    });

    group('UserProvider', () {
      test('should load user data on initialization', () async {
        final userNotifier = container.read(userProvider.notifier);
        await userNotifier.loadUserData();

        final userState = container.read(userProvider);
        expect(userState.hasValue, true);
        expect(userState.value!.name, 'Test User');
        expect(userState.value!.email, 'test@example.com');
        expect(userState.value!.isPremium, false);
      });

      test('should update user data', () async {
        final userNotifier = container.read(userProvider.notifier);
        
        final updatedUserData = UserData(
          name: 'Updated User',
          email: 'updated@example.com',
          isPremium: true,
          isFirstLaunch: false,
          tutorialCompleted: true,
          appVersion: '1.0.1',
        );

        await userNotifier.updateUserData(updatedUserData);

        final userState = container.read(userProvider);
        expect(userState.value!.name, 'Updated User');
        expect(userState.value!.email, 'updated@example.com');
        expect(userState.value!.isPremium, true);
      });

      test('should set premium status', () async {
        final userNotifier = container.read(userProvider.notifier);
        
        final expiryDate = DateTime.now().add(const Duration(days: 365));
        await userNotifier.setPremiumStatus(true, expiryDate);

        final userState = container.read(userProvider);
        expect(userState.value!.isPremium, true);
        expect(userState.value!.premiumExpiryDate, expiryDate);
      });

      test('should complete first launch', () async {
        final userNotifier = container.read(userProvider.notifier);
        
        expect(container.read(userProvider).value!.isFirstLaunch, true);
        
        await userNotifier.setFirstLaunchCompleted();

        final userState = container.read(userProvider);
        expect(userState.value!.isFirstLaunch, false);
      });

      test('should complete tutorial', () async {
        final userNotifier = container.read(userProvider.notifier);
        
        expect(container.read(userProvider).value!.tutorialCompleted, false);
        
        await userNotifier.setTutorialCompleted();

        final userState = container.read(userProvider);
        expect(userState.value!.tutorialCompleted, true);
      });
    });

    group('SettingsProvider', () {
      test('should load settings on initialization', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.loadSettings();

        final settingsState = container.read(settingsProvider);
        expect(settingsState.hasValue, true);
        expect(settingsState.value!.themeMode, 'system');
        expect(settingsState.value!.language, 'en');
        expect(settingsState.value!.autoBackup, true);
      });

      test('should update theme mode', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        
        await settingsNotifier.updateThemeMode('dark');

        final settingsState = container.read(settingsProvider);
        expect(settingsState.value!.themeMode, 'dark');
      });

      test('should update language', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        
        await settingsNotifier.updateLanguage('tr');

        final settingsState = container.read(settingsProvider);
        expect(settingsState.value!.language, 'tr');
      });

      test('should update sort order', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        
        await settingsNotifier.updateSortOrder('company');

        final settingsState = container.read(settingsProvider);
        expect(settingsState.value!.sortOrder, 'company');
      });

      test('should update contact view mode', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        
        await settingsNotifier.updateContactViewMode('list');

        final settingsState = container.read(settingsProvider);
        expect(settingsState.value!.contactViewMode, 'list');
      });

      test('should reset to defaults', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        
        // First change some settings
        await settingsNotifier.updateThemeMode('dark');
        await settingsNotifier.updateLanguage('tr');
        
        // Then reset
        await settingsNotifier.resetToDefaults();

        final settingsState = container.read(settingsProvider);
        expect(settingsState.value!.themeMode, 'system');
        expect(settingsState.value!.language, 'en');
      });
    });

    group('Derived Providers', () {
      test('premiumStatusProvider should derive from user data', () async {
        final userNotifier = container.read(userProvider.notifier);
        await userNotifier.loadUserData();

        final premiumStatus = container.read(premiumStatusProvider);
        expect(premiumStatus.hasValue, true);
        expect(premiumStatus.value, false);

        // Update premium status
        await userNotifier.setPremiumStatus(true, null);

        final updatedPremiumStatus = container.read(premiumStatusProvider);
        expect(updatedPremiumStatus.value, true);
      });

      test('themeModeProvider should derive from settings', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.loadSettings();

        final themeMode = container.read(themeModeProvider);
        expect(themeMode, 'system');

        await settingsNotifier.updateThemeMode('dark');

        final updatedThemeMode = container.read(themeModeProvider);
        expect(updatedThemeMode, 'dark');
      });

      test('contactViewModeProvider should derive from settings', () async {
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.loadSettings();

        final viewMode = container.read(contactViewModeProvider);
        expect(viewMode, 'grid');

        await settingsNotifier.updateContactViewMode('list');

        final updatedViewMode = container.read(contactViewModeProvider);
        expect(updatedViewMode, 'list');
      });
    });

    group('Search Provider', () {
      test('should update search results when query changes', () async {
        // Add test contacts
        await mockContactRepository.addContact(Contact(name: 'John Doe'));
        await mockContactRepository.addContact(Contact(name: 'Jane Smith'));
        await mockContactRepository.addContact(Contact(name: 'Bob Johnson'));

        // Set search query
        container.read(searchQueryProvider.notifier).state = 'John';

        final searchResults = await container.read(searchResultsProvider.future);
        expect(searchResults.length, 2); // John Doe and Bob Johnson
        expect(searchResults.any((c) => c.name == 'John Doe'), true);
        expect(searchResults.any((c) => c.name == 'Bob Johnson'), true);
      });

      test('should return empty results for empty query', () async {
        container.read(searchQueryProvider.notifier).state = '';

        final searchResults = await container.read(searchResultsProvider.future);
        expect(searchResults.length, 0);
      });
    });

    group('Statistics Providers', () {
      test('contactStatisticsProvider should return correct statistics', () async {
        // Add test contacts
        await mockContactRepository.addContact(Contact(
          name: 'John Doe',
          company: 'Tech Corp',
          email: 'john@example.com',
          phone: '1234567890',
          isStarred: true,
        ));
        await mockContactRepository.addContact(Contact(
          name: 'Jane Smith',
          email: 'jane@example.com',
        ));

        final stats = await container.read(contactStatisticsProvider.future);
        expect(stats['total'], 2);
        expect(stats['starred'], 1);
        expect(stats['withCompany'], 1);
        expect(stats['withEmail'], 2);
        expect(stats['withPhone'], 1);
      });

      test('contactCountProvider should return correct count', () async {
        await mockContactRepository.addContact(Contact(name: 'Contact 1'));
        await mockContactRepository.addContact(Contact(name: 'Contact 2'));
        await mockContactRepository.addContact(Contact(name: 'Contact 3'));

        final count = await container.read(contactCountProvider.future);
        expect(count, 3);
      });

      test('starredContactsProvider should return only starred contacts', () async {
        await mockContactRepository.addContact(Contact(name: 'Normal', isStarred: false));
        await mockContactRepository.addContact(Contact(name: 'Starred 1', isStarred: true));
        await mockContactRepository.addContact(Contact(name: 'Starred 2', isStarred: true));

        final starredContacts = await container.read(starredContactsProvider.future);
        expect(starredContacts.length, 2);
        expect(starredContacts.every((c) => c.isStarred), true);
      });
    });

    group('Selected Contact Provider', () {
      test('should return null when no contact selected', () {
        final selectedContact = container.read(selectedContactProvider);
        expect(selectedContact.hasValue, true);
        expect(selectedContact.value, isNull);
      });

      test('should return selected contact when id is set', () async {
        // Add test contact
        final id = await mockContactRepository.addContact(Contact(name: 'Selected Contact'));
        
        // Load contacts
        final contactsNotifier = container.read(contactsProvider.notifier);
        await contactsNotifier.loadContacts();

        // Select contact
        container.read(selectedContactIdProvider.notifier).state = id;

        final selectedContact = container.read(selectedContactProvider);
        expect(selectedContact.hasValue, true);
        expect(selectedContact.value!.name, 'Selected Contact');
      });
    });
  });
}