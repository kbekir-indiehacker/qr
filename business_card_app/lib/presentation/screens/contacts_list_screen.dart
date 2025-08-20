import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';
import 'package:business_card_app/presentation/screens/main_screen.dart';
import 'package:business_card_app/presentation/screens/contact_detail_screen.dart';
import 'package:business_card_app/presentation/widgets/contact_list_item.dart';
import 'package:business_card_app/presentation/widgets/contact_search_delegate.dart';

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected tag filter provider
final selectedTagProvider = StateProvider<String?>((ref) => null);

/// Sort mode provider
final sortModeProvider = StateProvider<String>((ref) => 'name');

/// Contacts list screen with search, filter and sort functionality
class ContactsListScreen extends ConsumerStatefulWidget {
  const ContactsListScreen({super.key});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Load contacts on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final contactsState = ref.watch(contactsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final sortMode = ref.watch(sortModeProvider);
    final allTagsAsync = ref.watch(allTagsProvider);

    return MainScreenWrapper(
      title: 'Kişiler',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(
              context: context,
              delegate: ContactSearchDelegate(ref: ref),
            );
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'sort':
                _showSortOptions();
                break;
              case 'filter':
                _showFilterOptions();
                break;
              case 'refresh':
                ref.read(contactsProvider.notifier).loadContacts();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('Sırala'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('Filtrele'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Yenile'),
                ],
              ),
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          // Search bar
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kişi ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Sort chip
                FilterChip(
                  label: Text(_getSortLabel(sortMode)),
                  avatar: const Icon(Icons.sort, size: 16),
                  selected: sortMode != 'name',
                  onSelected: (_) => _showSortOptions(),
                ),
                const SizedBox(width: 8),
                // Tag filter chips
                Expanded(
                  child: allTagsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (tags) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag),
                            selected: selectedTag == tag,
                            onSelected: (selected) {
                              ref.read(selectedTagProvider.notifier).state = 
                                  selected ? tag : null;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Clear filters
                if (selectedTag != null || sortMode != 'name')
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () {
                      ref.read(selectedTagProvider.notifier).state = null;
                      ref.read(sortModeProvider.notifier).state = 'name';
                    },
                    tooltip: 'Filtreleri temizle',
                  ),
              ],
            ),
          ),
          // Contacts list
          Expanded(
            child: contactsState.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Kişiler yükleniyor...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Hata: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(contactsProvider.notifier).loadContacts();
                      },
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (contacts) {
                final filteredContacts = _filterContacts(contacts, searchQuery, selectedTag);
                final sortedContacts = _sortContacts(filteredContacts, sortMode);
                
                if (sortedContacts.isEmpty) {
                  return _buildEmptyState(searchQuery.isNotEmpty || selectedTag != null);
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(contactsProvider.notifier).loadContacts();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = sortedContacts[index];
                      return ContactListItem(
                        contact: contact,
                        onTap: () => _navigateToContactDetail(contact),
                        onToggleStarred: () => _toggleStarred(contact.id!),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Contact> _filterContacts(List<Contact> contacts, String query, String? tag) {
    var filtered = contacts;
    
    // Text search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((contact) {
        return contact.name.toLowerCase().contains(query.toLowerCase()) ||
               (contact.company?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               (contact.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               (contact.phone?.contains(query) ?? false);
      }).toList();
    }
    
    // Tag filter
    if (tag != null) {
      filtered = filtered.where((contact) {
        return contact.tags.contains(tag);
      }).toList();
    }
    
    return filtered;
  }

  List<Contact> _sortContacts(List<Contact> contacts, String sortMode) {
    final sorted = List<Contact>.from(contacts);
    
    switch (sortMode) {
      case 'name':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'company':
        sorted.sort((a, b) {
          final aCompany = a.company?.toLowerCase() ?? '';
          final bCompany = b.company?.toLowerCase() ?? '';
          return aCompany.compareTo(bCompany);
        });
        break;
      case 'date_added':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_modified':
        sorted.sort((a, b) {
          final aDate = a.updatedAt ?? a.createdAt;
          final bDate = b.updatedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        break;
      case 'starred':
        sorted.sort((a, b) {
          if (a.isStarred && !b.isStarred) return -1;
          if (!a.isStarred && b.isStarred) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }
    
    return sorted;
  }

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.contacts,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered 
                ? 'Arama kriterlerinize uygun kişi bulunamadı'
                : 'Henüz hiç kişi eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Farklı arama terimleri deneyin'
                : 'QR kod tarayarak veya manuel olarak kişi ekleyin',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(selectedTagProvider.notifier).state = null;
                _searchController.clear();
              },
              child: const Text('Filtreleri Temizle'),
            ),
          ],
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSort = ref.watch(sortModeProvider);
            
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sıralama Seçenekleri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...{
                    'name': 'İsme göre (A-Z)',
                    'company': 'Şirkete göre',
                    'date_added': 'Eklenme tarihine göre',
                    'date_modified': 'Değiştirilme tarihine göre',
                    'starred': 'Favoriler önce',
                  }.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: currentSort,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(sortModeProvider.notifier).state = value;
                          Navigator.pop(context);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterOptions() {
    // Filter options implementasyonu - gelişmiş filtreleme seçenekleri
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtreleme Seçenekleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Gelişmiş filtreleme seçenekleri yakında eklenecek'),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSortLabel(String sortMode) {
    switch (sortMode) {
      case 'name':
        return 'İsim';
      case 'company':
        return 'Şirket';
      case 'date_added':
        return 'Tarih';
      case 'date_modified':
        return 'Güncelleme';
      case 'starred':
        return 'Favoriler';
      default:
        return 'İsim';
    }
  }

  void _navigateToContactDetail(Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contactId: contact.id!),
      ),
    );
  }

  void _toggleStarred(int contactId) {
    ref.read(contactsProvider.notifier).toggleStarred(contactId);
  }
}