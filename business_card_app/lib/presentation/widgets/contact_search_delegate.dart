import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';
import 'package:business_card_app/presentation/screens/contact_detail_screen.dart';
import 'package:business_card_app/presentation/widgets/contact_list_item.dart';

/// Search delegate for contacts with suggestions and history
class ContactSearchDelegate extends SearchDelegate<Contact?> {
  final WidgetRef ref;

  ContactSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => 'Kişi ara...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHistory();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, child) {
        final contactsState = ref.watch(contactsProvider);
        
        return contactsState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: $error'),
              ],
            ),
          ),
          data: (contacts) {
            final searchResults = _searchContacts(contacts, query);
            
            if (searchResults.isEmpty) {
              return _buildNoResults();
            }
            
            return ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final contact = searchResults[index];
                return ContactListItem(
                  contact: contact,
                  onTap: () {
                    _saveSearchQuery(query);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ContactDetailScreen(
                          contactId: contact.id!,
                        ),
                      ),
                    );
                  },
                  onToggleStarred: () {
                    ref.read(contactsProvider.notifier).toggleStarred(contact.id!);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHistory() {
    return Consumer(
      builder: (context, ref, child) {
        // Get recent searches from local storage
        return FutureBuilder<List<String>>(
          future: _getRecentSearches(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildSearchSuggestions();
            }
            
            final recentSearches = snapshot.data!;
            
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Son Aramalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...recentSearches.map((searchQuery) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(searchQuery),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _removeSearchQuery(searchQuery);
                      },
                    ),
                    onTap: () {
                      query = searchQuery;
                      showResults(context);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Arama geçmişini temizle'),
                  onTap: () {
                    _clearSearchHistory();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return Consumer(
      builder: (context, ref, child) {
        final allTagsAsync = ref.watch(allTagsProvider);
        
        return allTagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (tags) {
            if (tags.isEmpty) {
              return _buildEmptySearchState();
            }
            
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Etiketlere Göre Ara',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          query = tag;
                          showResults(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Arama İpuçları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.person),
                  title: Text('İsme göre ara'),
                  subtitle: Text('Örn: "John", "Ahmet"'),
                ),
                const ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Şirkete göre ara'),
                  subtitle: Text('Örn: "Google", "Microsoft"'),
                ),
                const ListTile(
                  leading: Icon(Icons.email),
                  title: Text('E-posta adresine göre ara'),
                  subtitle: Text('Örn: "gmail", "@company.com"'),
                ),
                const ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Telefon numarasına göre ara'),
                  subtitle: Text('Örn: "555", "+90"'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Arama sonucu bulunamadı',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '"$query" için sonuç bulunamadı',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Farklı arama terimleri deneyin',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Kişi arayın',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'İsim, şirket, e-posta veya telefon numarası ile arayabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<Contact> _searchContacts(List<Contact> contacts, String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    
    return contacts.where((contact) {
      // Search in name
      if (contact.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Search in company
      if (contact.company?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      
      // Search in email
      if (contact.email?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      
      // Search in phone
      if (contact.phone?.contains(lowerQuery) == true) {
        return true;
      }
      
      // Search in title
      if (contact.title?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      
      // Search in tags
      if (contact.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      
      // Search in notes
      if (contact.notes?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      
      return false;
    }).toList();
  }

  Future<List<String>> _getRecentSearches() async {
    // TODO: Implement getting recent searches from local storage
    return [];
  }

  void _saveSearchQuery(String query) {
    if (query.trim().isEmpty) return;
    // TODO: Save search query to local storage
  }

  void _removeSearchQuery(String query) {
    // TODO: Remove specific search query from history
  }

  void _clearSearchHistory() {
    // TODO: Clear all search history
  }
}