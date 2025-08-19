import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/local_storage.dart';

// Base providers for data sources
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

// Repository providers
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final localStorage = ref.watch(localStorageProvider);
  return ContactRepository(
    databaseHelper: databaseHelper,
    localStorage: localStorage,
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final localStorage = ref.watch(localStorageProvider);
  return UserRepository(
    databaseHelper: databaseHelper,
    localStorage: localStorage,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final localStorage = ref.watch(localStorageProvider);
  return SettingsRepository(
    databaseHelper: databaseHelper,
    localStorage: localStorage,
  );
});

// Contacts State Notifier
class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  final ContactRepository _contactRepository;

  ContactsNotifier(this._contactRepository) : super(const AsyncValue.loading()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      state = const AsyncValue.loading();
      final contacts = await _contactRepository.getAllContacts();
      state = AsyncValue.data(contacts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addContact(Contact contact) async {
    try {
      await _contactRepository.addContact(contact);
      await loadContacts(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateContact(Contact contact) async {
    try {
      await _contactRepository.updateContact(contact);
      await loadContacts(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteContact(int contactId) async {
    try {
      await _contactRepository.deleteContact(contactId);
      await loadContacts(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleStarred(int contactId) async {
    try {
      await _contactRepository.toggleStarred(contactId);
      await loadContacts(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Contact>> searchContacts(String query) async {
    try {
      return await _contactRepository.searchContacts(query);
    } catch (error) {
      throw error;
    }
  }

  Future<List<Contact>> getStarredContacts() async {
    try {
      return await _contactRepository.getStarredContacts();
    } catch (error) {
      throw error;
    }
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return ContactsNotifier(contactRepository);
});

// User Data State Notifier
class UserNotifier extends StateNotifier<AsyncValue<UserData>> {
  final UserRepository _userRepository;

  UserNotifier(this._userRepository) : super(const AsyncValue.loading()) {
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      state = const AsyncValue.loading();
      final userData = await _userRepository.getUserData();
      state = AsyncValue.data(userData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUserData(UserData userData) async {
    try {
      await _userRepository.updateUserData(userData);
      state = AsyncValue.data(userData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setPremiumStatus(bool isPremium, DateTime? expiryDate) async {
    try {
      await _userRepository.setPremiumStatus(isPremium, expiryDate);
      await loadUserData(); // Refresh user data
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setFirstLaunchCompleted() async {
    try {
      await _userRepository.setFirstLaunchCompleted();
      await loadUserData(); // Refresh user data
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setTutorialCompleted() async {
    try {
      await _userRepository.setTutorialCompleted();
      await loadUserData(); // Refresh user data
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserData>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserNotifier(userRepository);
});

// Settings State Notifier
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _settingsRepository;

  SettingsNotifier(this._settingsRepository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _settingsRepository.getSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _settingsRepository.updateSettings(settings);
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    try {
      await _settingsRepository.updateThemeMode(themeMode);
      await loadSettings(); // Refresh settings
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLanguage(String language) async {
    try {
      await _settingsRepository.updateLanguage(language);
      await loadSettings(); // Refresh settings
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSortOrder(String sortOrder) async {
    try {
      await _settingsRepository.updateSortOrder(sortOrder);
      await loadSettings(); // Refresh settings
      // Also refresh contacts to apply new sort order
      // This will be handled by the contacts provider listening to settings changes
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateContactViewMode(String viewMode) async {
    try {
      await _settingsRepository.updateContactViewMode(viewMode);
      await loadSettings(); // Refresh settings
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetToDefaults() async {
    try {
      await _settingsRepository.resetToDefaults();
      await loadSettings(); // Refresh settings
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(settingsRepository);
});

// Premium Status Provider
final premiumStatusProvider = Provider<AsyncValue<bool>>((ref) {
  final userAsyncValue = ref.watch(userProvider);
  return userAsyncValue.when(
    data: (userData) => AsyncValue.data(userData.isPremium),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Contact Statistics Provider
final contactStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return await contactRepository.getContactStatistics();
});

// Search Provider for contacts
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Contact>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final contactRepository = ref.watch(contactRepositoryProvider);
  
  if (query.isEmpty) {
    return [];
  }
  
  return await contactRepository.searchContacts(query);
});

// Tags Provider
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return await contactRepository.getAllTags();
});

// Starred Contacts Provider
final starredContactsProvider = FutureProvider<List<Contact>>((ref) async {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return await contactRepository.getStarredContacts();
});

// Contact Count Provider
final contactCountProvider = FutureProvider<int>((ref) async {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return await contactRepository.getContactCount();
});

// Can Add More Contacts Provider
final canAddMoreContactsProvider = FutureProvider<bool>((ref) async {
  final contactRepository = ref.watch(contactRepositoryProvider);
  return await contactRepository.canAddMoreContacts();
});

// Recent Searches Provider
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return await settingsRepository.getRecentSearches();
});

// OCR Usage Provider
class OcrUsageNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final LocalStorage _localStorage;

  OcrUsageNotifier(this._localStorage) : super(const AsyncValue.loading()) {
    loadOcrUsage();
  }

  Future<void> loadOcrUsage() async {
    try {
      state = const AsyncValue.loading();
      final usageCount = await _localStorage.getOcrUsageCount();
      final canUse = await _localStorage.canUseOcr();
      final resetDate = await _localStorage.getOcrResetDate();
      
      state = AsyncValue.data({
        'usageCount': usageCount,
        'canUse': canUse,
        'resetDate': resetDate,
        'maxUsage': 10, // From constants
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> incrementUsage() async {
    try {
      final canUse = await _localStorage.canUseOcr();
      if (!canUse) return false;

      await _localStorage.incrementOcrUsage();
      await loadOcrUsage(); // Refresh the state
      return true;
    } catch (error) {
      return false;
    }
  }
}

final ocrUsageProvider = StateNotifierProvider<OcrUsageNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return OcrUsageNotifier(localStorage);
});

// Auto Backup Check Provider
final shouldAutoBackupProvider = FutureProvider<bool>((ref) async {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return await settingsRepository.shouldAutoBackup();
});

// Combined App State Provider (for debugging and monitoring)
final appStateProvider = Provider<Map<String, dynamic>>((ref) {
  final contactsState = ref.watch(contactsProvider);
  final userState = ref.watch(userProvider);
  final settingsState = ref.watch(settingsProvider);
  final premiumState = ref.watch(premiumStatusProvider);

  return {
    'contacts': contactsState,
    'user': userState,
    'settings': settingsState,
    'premium': premiumState,
    'timestamp': DateTime.now().toIso8601String(),
  };
});

// Refresh All Data Provider (for pull-to-refresh functionality)
final refreshAllDataProvider = Provider<Future<void>>((ref) async {
  final contactsNotifier = ref.read(contactsProvider.notifier);
  final userNotifier = ref.read(userProvider.notifier);
  final settingsNotifier = ref.read(settingsProvider.notifier);

  await Future.wait([
    contactsNotifier.loadContacts(),
    userNotifier.loadUserData(),
    settingsNotifier.loadSettings(),
  ]);
});

// Selected Contact Provider (for detail view)
final selectedContactIdProvider = StateProvider<int?>((ref) => null);

final selectedContactProvider = Provider<AsyncValue<Contact?>>((ref) {
  final selectedId = ref.watch(selectedContactIdProvider);
  if (selectedId == null) {
    return const AsyncValue.data(null);
  }

  final contactsState = ref.watch(contactsProvider);
  return contactsState.when(
    data: (contacts) {
      try {
        final contact = contacts.firstWhere((c) => c.id == selectedId);
        return AsyncValue.data(contact);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Theme Mode Provider (derived from settings)
final themeModeProvider = Provider<String>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.when(
    data: (settings) => settings.themeMode,
    loading: () => 'system',
    error: (_, __) => 'system',
  );
});

// Contact View Mode Provider (derived from settings)
final contactViewModeProvider = Provider<String>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.when(
    data: (settings) => settings.contactViewMode,
    loading: () => 'grid',
    error: (_, __) => 'grid',
  );
});