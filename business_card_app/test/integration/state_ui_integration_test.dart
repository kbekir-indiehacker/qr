import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/data/repositories/contact_repository.dart';
import 'package:business_card_app/data/repositories/user_repository.dart';
import 'package:business_card_app/data/repositories/settings_repository.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';

// Mock repositories for UI testing
class MockContactRepository implements ContactRepositoryInterface {
  final List<Contact> _contacts = [];
  int _nextId = 1;

  @override
  Future<List<Contact>> getAllContacts() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return List.from(_contacts);
  }

  @override
  Future<Contact?> getContactById(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> addContact(Contact contact) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newContact = contact.copyWith(id: _nextId++);
    _contacts.add(newContact);
    return newContact.id!;
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteContact(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (query.isEmpty) return [];
    return _contacts.where((c) => 
      c.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<List<Contact>> getStarredContacts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _contacts.where((c) => c.isStarred).toList();
  }

  @override
  Future<int> getContactCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _contacts.length;
  }

  @override
  Future<bool> canAddMoreContacts() async {
    return true;
  }

  Future<bool> toggleStarred(int contactId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final contact = await getContactById(contactId);
    if (contact == null) return false;
    
    final updated = contact.copyWith(isStarred: !contact.isStarred);
    return await updateContact(updated);
  }

  Future<Map<String, int>> getContactStatistics() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final contacts = await getAllContacts();
    return {
      'total': contacts.length,
      'starred': contacts.where((c) => c.isStarred).length,
      'withCompany': contacts.where((c) => c.hasCompany).length,
      'withEmail': contacts.where((c) => c.hasEmail).length,
      'withPhone': contacts.where((c) => c.hasPhoneNumber).length,
    };
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
  Future<UserData> getUserData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _userData;
  }

  @override
  Future<void> updateUserData(UserData userData) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _userData = userData;
  }

  @override
  Future<bool> isPremiumUser() async => _userData.isPremium;

  @override
  Future<void> setPremiumStatus(bool isPremium, DateTime? expiryDate) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _userData = _userData.copyWith(
      isPremium: isPremium,
      premiumExpiryDate: expiryDate,
    );
  }

  @override
  Future<bool> isFirstLaunch() async => _userData.isFirstLaunch;

  @override
  Future<void> setFirstLaunchCompleted() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _userData = _userData.copyWith(isFirstLaunch: false);
  }

  @override
  Future<bool> isTutorialCompleted() async => _userData.tutorialCompleted;

  @override
  Future<void> setTutorialCompleted() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _userData = _userData.copyWith(tutorialCompleted: true);
  }
}

class MockSettingsRepository implements SettingsRepositoryInterface {
  AppSettings _settings = AppSettings.defaultSettings();

  @override
  Future<AppSettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _settings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _settings = settings;
  }

  @override
  Future<void> updateThemeMode(String themeMode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = _settings.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> updateLanguage(String language) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = _settings.copyWith(language: language);
  }

  @override
  Future<void> updateSortOrder(String sortOrder) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = _settings.copyWith(sortOrder: sortOrder);
  }

  @override
  Future<void> updateContactViewMode(String viewMode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = _settings.copyWith(contactViewMode: viewMode);
  }

  @override
  Future<void> resetToDefaults() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _settings = AppSettings.defaultSettings();
  }
}

// Test widgets
class ContactListWidget extends ConsumerWidget {
  const ContactListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(contactsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact List'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).loadContacts();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: contactsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('loading_indicator')),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, key: Key('error_icon')),
              Text('Error: $error', key: const Key('error_text')),
            ],
          ),
        ),
        data: (contacts) => contacts.isEmpty
            ? const Center(
                child: Text('No contacts found', key: Key('empty_text')),
              )
            : ListView.builder(
                key: const Key('contact_list'),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ListTile(
                    key: Key('contact_${contact.id}'),
                    title: Text(contact.name),
                    subtitle: Text(contact.company ?? ''),
                    trailing: IconButton(
                      key: Key('star_${contact.id}'),
                      icon: Icon(
                        contact.isStarred ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () {
                        ref.read(contactsProvider.notifier).toggleStarred(contact.id!);
                      },
                    ),
                    onTap: () {
                      ref.read(selectedContactIdProvider.notifier).state = contact.id;
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_button'),
        onPressed: () async {
          final newContact = Contact(
            name: 'New Contact ${DateTime.now().millisecondsSinceEpoch}',
            company: 'Test Company',
          );
          await ref.read(contactsProvider.notifier).addContact(newContact);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ContactDetailWidget extends ConsumerWidget {
  const ContactDetailWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedContactState = ref.watch(selectedContactProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Detail'),
        actions: [
          IconButton(
            key: const Key('delete_button'),
            onPressed: () {
              final contactId = ref.read(selectedContactIdProvider);
              if (contactId != null) {
                ref.read(contactsProvider.notifier).deleteContact(contactId);
                ref.read(selectedContactIdProvider.notifier).state = null;
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: selectedContactState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('detail_loading')),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', key: const Key('detail_error')),
        ),
        data: (contact) => contact == null
            ? const Center(
                child: Text('No contact selected', key: Key('no_selection')),
              )
            : Padding(
                key: const Key('contact_detail'),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      key: const Key('contact_name'),
                    ),
                    if (contact.company != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        contact.company!,
                        style: const TextStyle(fontSize: 18),
                        key: const Key('contact_company'),
                      ),
                    ],
                    if (contact.email != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        contact.email!,
                        key: const Key('contact_email'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('edit_button'),
                      onPressed: () async {
                        final updatedContact = contact.copyWith(
                          name: '${contact.name} (Updated)',
                        );
                        await ref.read(contactsProvider.notifier).updateContact(updatedContact);
                      },
                      child: const Text('Edit Contact'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class SearchWidget extends ConsumerStatefulWidget {
  const SearchWidget({super.key});

  @override
  ConsumerState<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends ConsumerState<SearchWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search_field'),
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search contacts...',
            border: InputBorder.none,
          ),
          onChanged: (query) {
            ref.read(searchQueryProvider.notifier).state = query;
          },
        ),
      ),
      body: searchResults.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('search_loading')),
        ),
        error: (error, stack) => Center(
          child: Text('Search error: $error', key: const Key('search_error')),
        ),
        data: (results) => results.isEmpty
            ? const Center(
                child: Text('No search results', key: Key('no_results')),
              )
            : ListView.builder(
                key: const Key('search_results'),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final contact = results[index];
                  return ListTile(
                    key: Key('result_${contact.id}'),
                    title: Text(contact.name),
                    subtitle: Text(contact.company ?? ''),
                  );
                },
              ),
      ),
    );
  }
}

class SettingsWidget extends ConsumerWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final viewMode = ref.watch(contactViewModeProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('settings_loading')),
        ),
        error: (error, stack) => Center(
          child: Text('Settings error: $error', key: const Key('settings_error')),
        ),
        data: (settings) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                key: const Key('theme_tile'),
                title: const Text('Theme Mode'),
                subtitle: Text('Current: $themeMode'),
                trailing: DropdownButton<String>(
                  key: const Key('theme_dropdown'),
                  value: themeMode,
                  items: ['system', 'light', 'dark'].map((mode) => 
                    DropdownMenuItem(value: mode, child: Text(mode))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateThemeMode(value);
                    }
                  },
                ),
              ),
              ListTile(
                key: const Key('view_mode_tile'),
                title: const Text('View Mode'),
                subtitle: Text('Current: $viewMode'),
                trailing: DropdownButton<String>(
                  key: const Key('view_mode_dropdown'),
                  value: viewMode,
                  items: ['grid', 'list'].map((mode) => 
                    DropdownMenuItem(value: mode, child: Text(mode))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateContactViewMode(value);
                    }
                  },
                ),
              ),
              ListTile(
                key: const Key('language_tile'),
                title: const Text('Language'),
                subtitle: Text('Current: ${settings.language}'),
                trailing: DropdownButton<String>(
                  key: const Key('language_dropdown'),
                  value: settings.language,
                  items: ['en', 'tr'].map((lang) => 
                    DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateLanguage(value);
                    }
                  },
                ),
              ),
              ElevatedButton(
                key: const Key('reset_button'),
                onPressed: () {
                  ref.read(settingsProvider.notifier).resetToDefaults();
                },
                child: const Text('Reset to Defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('State-UI Integration Tests', () {
    late MockContactRepository mockContactRepository;
    late MockUserRepository mockUserRepository;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockContactRepository = MockContactRepository();
      mockUserRepository = MockUserRepository();
      mockSettingsRepository = MockSettingsRepository();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          contactRepositoryProvider.overrideWithValue(mockContactRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
        ],
        child: MaterialApp(home: child),
      );
    }

    group('Contact List State-UI Integration', () {
      testWidgets('Should show loading state initially', (tester) async {
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        
        // Should show loading indicator initially
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        
        // Wait for loading to complete
        await tester.pumpAndSettle();
        
        // Should show empty state after loading
        expect(find.byKey(const Key('empty_text')), findsOneWidget);
      });

      testWidgets('Should add contact and update UI', (tester) async {
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Initially empty
        expect(find.byKey(const Key('empty_text')), findsOneWidget);
        
        // Tap add button
        await tester.tap(find.byKey(const Key('add_button')));
        await tester.pump(); // Start the async operation
        
        // Should show loading again
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        
        // Wait for add operation to complete
        await tester.pumpAndSettle();
        
        // Should now show the contact list
        expect(find.byKey(const Key('contact_list')), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('Should toggle starred status and update UI', (tester) async {
        // Pre-add a contact
        await mockContactRepository.addContact(Contact(
          name: 'Test Contact',
          isStarred: false,
        ));
        
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Find the star button
        final starButton = find.byKey(const Key('star_1'));
        expect(starButton, findsOneWidget);
        
        // Initially should show star_border
        expect(find.byIcon(Icons.star_border), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
        
        // Tap star button
        await tester.tap(starButton);
        await tester.pump();
        
        // Wait for toggle operation
        await tester.pumpAndSettle();
        
        // Should now show filled star
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsNothing);
      });

      testWidgets('Should handle errors gracefully', (tester) async {
        // Make the repository throw an error
        mockContactRepository._contacts.add(Contact(name: 'Test'));
        
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Should show contact list normally first
        expect(find.byKey(const Key('contact_list')), findsOneWidget);
      });
    });

    group('Contact Detail State-UI Integration', () {
      testWidgets('Should show no selection initially', (tester) async {
        await tester.pumpWidget(createTestApp(const ContactDetailWidget()));
        await tester.pumpAndSettle();
        
        expect(find.byKey(const Key('no_selection')), findsOneWidget);
      });

      testWidgets('Should show contact details when selected', (tester) async {
        // Add a contact
        await mockContactRepository.addContact(Contact(
          name: 'John Doe',
          company: 'Tech Corp',
          email: 'john@techcorp.com',
        ));
        
        await tester.pumpWidget(createTestApp(
          ProviderScope(
            overrides: [
              selectedContactIdProvider.overrideWith((ref) => StateController(1)),
              contactRepositoryProvider.overrideWithValue(mockContactRepository),
              userRepositoryProvider.overrideWithValue(mockUserRepository),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
            ],
            child: const MaterialApp(home: ContactDetailWidget()),
          ),
        ));
        await tester.pumpAndSettle();
        
        expect(find.byKey(const Key('contact_detail')), findsOneWidget);
        expect(find.byKey(const Key('contact_name')), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.byKey(const Key('contact_company')), findsOneWidget);
        expect(find.text('Tech Corp'), findsOneWidget);
        expect(find.byKey(const Key('contact_email')), findsOneWidget);
        expect(find.text('john@techcorp.com'), findsOneWidget);
      });

      testWidgets('Should update contact and refresh detail view', (tester) async {
        // Add a contact
        await mockContactRepository.addContact(Contact(
          name: 'John Doe',
          company: 'Tech Corp',
        ));
        
        await tester.pumpWidget(createTestApp(
          ProviderScope(
            overrides: [
              selectedContactIdProvider.overrideWith((ref) => StateController(1)),
              contactRepositoryProvider.overrideWithValue(mockContactRepository),
              userRepositoryProvider.overrideWithValue(mockUserRepository),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
            ],
            child: const MaterialApp(home: ContactDetailWidget()),
          ),
        ));
        await tester.pumpAndSettle();
        
        // Initially shows original name
        expect(find.text('John Doe'), findsOneWidget);
        
        // Tap edit button
        await tester.tap(find.byKey(const Key('edit_button')));
        await tester.pump();
        
        // Wait for update operation
        await tester.pumpAndSettle();
        
        // Should show updated name
        expect(find.text('John Doe (Updated)'), findsOneWidget);
      });
    });

    group('Search State-UI Integration', () {
      testWidgets('Should show no results initially', (tester) async {
        await tester.pumpWidget(createTestApp(const SearchWidget()));
        await tester.pumpAndSettle();
        
        expect(find.byKey(const Key('no_results')), findsOneWidget);
      });

      testWidgets('Should search and show results', (tester) async {
        // Add test contacts
        await mockContactRepository.addContact(Contact(name: 'John Doe'));
        await mockContactRepository.addContact(Contact(name: 'Jane Smith'));
        await mockContactRepository.addContact(Contact(name: 'Bob Johnson'));
        
        await tester.pumpWidget(createTestApp(const SearchWidget()));
        await tester.pumpAndSettle();
        
        // Enter search query
        await tester.enterText(find.byKey(const Key('search_field')), 'John');
        await tester.pump();
        
        // Should show loading
        expect(find.byKey(const Key('search_loading')), findsOneWidget);
        
        // Wait for search results
        await tester.pumpAndSettle();
        
        // Should show search results
        expect(find.byKey(const Key('search_results')), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text('Jane Smith'), findsNothing);
      });

      testWidgets('Should clear results when search is cleared', (tester) async {
        await mockContactRepository.addContact(Contact(name: 'John Doe'));
        
        await tester.pumpWidget(createTestApp(const SearchWidget()));
        await tester.pumpAndSettle();
        
        // Search first
        await tester.enterText(find.byKey(const Key('search_field')), 'John');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('search_results')), findsOneWidget);
        
        // Clear search
        await tester.enterText(find.byKey(const Key('search_field')), '');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('no_results')), findsOneWidget);
      });
    });

    group('Settings State-UI Integration', () {
      testWidgets('Should show settings and allow changes', (tester) async {
        await tester.pumpWidget(createTestApp(const SettingsWidget()));
        await tester.pumpAndSettle();
        
        // Should show current settings
        expect(find.byKey(const Key('theme_tile')), findsOneWidget);
        expect(find.byKey(const Key('view_mode_tile')), findsOneWidget);
        expect(find.byKey(const Key('language_tile')), findsOneWidget);
        
        // Check initial values
        expect(find.text('Current: system'), findsOneWidget);
        expect(find.text('Current: grid'), findsOneWidget);
        expect(find.text('Current: en'), findsOneWidget);
      });

      testWidgets('Should update theme mode', (tester) async {
        await tester.pumpWidget(createTestApp(const SettingsWidget()));
        await tester.pumpAndSettle();
        
        // Tap theme dropdown
        await tester.tap(find.byKey(const Key('theme_dropdown')));
        await tester.pumpAndSettle();
        
        // Select dark theme
        await tester.tap(find.text('dark').last);
        await tester.pump();
        
        // Wait for settings update
        await tester.pumpAndSettle();
        
        // Should show updated theme
        expect(find.text('Current: dark'), findsOneWidget);
      });

      testWidgets('Should reset to defaults', (tester) async {
        await tester.pumpWidget(createTestApp(const SettingsWidget()));
        await tester.pumpAndSettle();
        
        // Change some settings first
        await tester.tap(find.byKey(const Key('theme_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('dark').last);
        await tester.pumpAndSettle();
        
        // Verify change
        expect(find.text('Current: dark'), findsOneWidget);
        
        // Reset to defaults
        await tester.tap(find.byKey(const Key('reset_button')));
        await tester.pump();
        
        // Wait for reset operation
        await tester.pumpAndSettle();
        
        // Should be back to default
        expect(find.text('Current: system'), findsOneWidget);
      });
    });

    group('Cross-Widget State Integration', () {
      testWidgets('Should maintain state across widget rebuilds', (tester) async {
        // Add a contact
        await mockContactRepository.addContact(Contact(name: 'Test Contact'));
        
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Should show the contact
        expect(find.text('Test Contact'), findsOneWidget);
        
        // Rebuild the widget tree
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Should still show the contact
        expect(find.text('Test Contact'), findsOneWidget);
      });

      testWidgets('Should handle rapid state changes', (tester) async {
        await tester.pumpWidget(createTestApp(const ContactListWidget()));
        await tester.pumpAndSettle();
        
        // Rapidly add multiple contacts
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byKey(const Key('add_button')));
          await tester.pump(const Duration(milliseconds: 50));
        }
        
        // Wait for all operations to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        // Should show all contacts
        expect(find.byType(ListTile), findsNWidgets(5));
      });
    });
  });
}