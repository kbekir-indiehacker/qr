import '../models/contact.dart';
import '../datasources/database_helper.dart';
import '../datasources/local_storage.dart';
import '../../core/constants/database_constants.dart';

abstract class ContactRepositoryInterface {
  Future<List<Contact>> getAllContacts();
  Future<Contact?> getContactById(int id);
  Future<List<Contact>> searchContacts(String query);
  Future<List<Contact>> getStarredContacts();
  Future<int> addContact(Contact contact);
  Future<bool> updateContact(Contact contact);
  Future<bool> deleteContact(int id);
  Future<int> getContactCount();
  Future<bool> canAddMoreContacts();
}

class ContactRepository implements ContactRepositoryInterface {
  final DatabaseHelper _databaseHelper;
  final LocalStorage _localStorage;

  ContactRepository({
    DatabaseHelper? databaseHelper,
    LocalStorage? localStorage,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _localStorage = localStorage ?? LocalStorage();

  @override
  Future<List<Contact>> getAllContacts() async {
    try {
      final sortOrder = await _localStorage.getSortOrder();
      final showStarredFirst = await _localStorage.getShowStarredFirst();
      
      if (showStarredFirst) {
        return await _databaseHelper.getAllContacts(sortBy: DatabaseConstants.sortByStarred);
      }
      
      return await _databaseHelper.getAllContacts(sortBy: sortOrder);
    } catch (e) {
      throw ContactRepositoryException('Kişiler alınırken hata oluştu: $e');
    }
  }

  @override
  Future<Contact?> getContactById(int id) async {
    try {
      return await _databaseHelper.getContactById(id);
    } catch (e) {
      throw ContactRepositoryException('Kişi bulunurken hata oluştu: $e');
    }
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllContacts();
      }
      
      // Add to recent searches
      await _localStorage.addRecentSearch(query.trim());
      
      return await _databaseHelper.searchContacts(query.trim());
    } catch (e) {
      throw ContactRepositoryException('Kişi aranırken hata oluştu: $e');
    }
  }

  @override
  Future<List<Contact>> getStarredContacts() async {
    try {
      return await _databaseHelper.getStarredContacts();
    } catch (e) {
      throw ContactRepositoryException('Favoriler alınırken hata oluştu: $e');
    }
  }

  @override
  Future<int> addContact(Contact contact) async {
    try {
      // Check if user can add more contacts
      final canAdd = await canAddMoreContacts();
      if (!canAdd) {
        throw ContactRepositoryException(
          'Maksimum kişi sayısına ulaştınız. Premium üyeliğe geçin.',
        );
      }

      // Validate contact data
      _validateContact(contact);

      final id = await _databaseHelper.insertContact(contact);
      
      // Update statistics
      await _localStorage.incrementTotalContactsCreated();
      
      return id;
    } catch (e) {
      if (e is ContactRepositoryException) rethrow;
      throw ContactRepositoryException('Kişi eklenirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    try {
      if (contact.id == null) {
        throw ContactRepositoryException('Güncellenecek kişinin ID\'si bulunamadı');
      }

      _validateContact(contact);

      final result = await _databaseHelper.updateContact(contact);
      return result > 0;
    } catch (e) {
      if (e is ContactRepositoryException) rethrow;
      throw ContactRepositoryException('Kişi güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> deleteContact(int id) async {
    try {
      final result = await _databaseHelper.deleteContact(id);
      return result > 0;
    } catch (e) {
      throw ContactRepositoryException('Kişi silinirken hata oluştu: $e');
    }
  }

  @override
  Future<int> getContactCount() async {
    try {
      return await _databaseHelper.getContactCount();
    } catch (e) {
      throw ContactRepositoryException('Kişi sayısı alınırken hata oluştu: $e');
    }
  }

  @override
  Future<bool> canAddMoreContacts() async {
    try {
      final isPremium = await _localStorage.getPremiumStatus();
      if (isPremium) return true;

      final contactCount = await getContactCount();
      return contactCount < DatabaseConstants.maxContactsForFree;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleStarred(int contactId) async {
    try {
      final contact = await getContactById(contactId);
      if (contact == null) {
        throw ContactRepositoryException('Kişi bulunamadı');
      }

      final updatedContact = contact.copyWith(
        isStarred: !contact.isStarred,
        updatedAt: DateTime.now(),
      );

      return await updateContact(updatedContact);
    } catch (e) {
      if (e is ContactRepositoryException) rethrow;
      throw ContactRepositoryException('Favori durumu değiştirilirken hata oluştu: $e');
    }
  }

  Future<List<Contact>> getContactsByTag(String tag) async {
    try {
      final allContacts = await getAllContacts();
      return allContacts.where((contact) => contact.tags.contains(tag)).toList();
    } catch (e) {
      throw ContactRepositoryException('Etiketli kişiler alınırken hata oluştu: $e');
    }
  }

  Future<List<String>> getAllTags() async {
    try {
      final allContacts = await getAllContacts();
      final allTags = <String>{};
      
      for (final contact in allContacts) {
        allTags.addAll(contact.tags);
      }
      
      return allTags.toList()..sort();
    } catch (e) {
      throw ContactRepositoryException('Etiketler alınırken hata oluştu: $e');
    }
  }

  Future<Map<String, int>> getContactStatistics() async {
    try {
      final allContacts = await getAllContacts();
      final starredContacts = allContacts.where((c) => c.isStarred).length;
      final contactsWithCompany = allContacts.where((c) => c.hasCompany).length;
      final contactsWithEmail = allContacts.where((c) => c.hasEmail).length;
      final contactsWithPhone = allContacts.where((c) => c.hasPhoneNumber).length;

      return {
        'total': allContacts.length,
        'starred': starredContacts,
        'withCompany': contactsWithCompany,
        'withEmail': contactsWithEmail,
        'withPhone': contactsWithPhone,
      };
    } catch (e) {
      throw ContactRepositoryException('İstatistikler alınırken hata oluştu: $e');
    }
  }

  void _validateContact(Contact contact) {
    if (contact.name.trim().isEmpty) {
      throw ContactRepositoryException('Kişi adı boş olamaz');
    }

    if (contact.name.length > DatabaseConstants.maxContactNameLength) {
      throw ContactRepositoryException(
        'Kişi adı ${DatabaseConstants.maxContactNameLength} karakterden uzun olamaz',
      );
    }

    if (contact.company != null && 
        contact.company!.length > DatabaseConstants.maxCompanyNameLength) {
      throw ContactRepositoryException(
        'Şirket adı ${DatabaseConstants.maxCompanyNameLength} karakterden uzun olamaz',
      );
    }

    if (contact.notes != null && 
        contact.notes!.length > DatabaseConstants.maxNotesLength) {
      throw ContactRepositoryException(
        'Notlar ${DatabaseConstants.maxNotesLength} karakterden uzun olamaz',
      );
    }

    if (contact.tags.length > DatabaseConstants.maxTagsPerContact) {
      throw ContactRepositoryException(
        'Maksimum ${DatabaseConstants.maxTagsPerContact} etiket ekleyebilirsiniz',
      );
    }

    // Validate email format if provided
    if (contact.email != null && contact.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(contact.email!)) {
        throw ContactRepositoryException('Geçersiz e-posta formatı');
      }
    }

    // Validate phone format if provided
    if (contact.phone != null && contact.phone!.isNotEmpty) {
      final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$');
      if (!phoneRegex.hasMatch(contact.phone!)) {
        throw ContactRepositoryException('Geçersiz telefon numarası formatı');
      }
    }

    // Validate website URL if provided
    if (contact.website != null && contact.website!.isNotEmpty) {
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      );
      if (!urlRegex.hasMatch(contact.website!)) {
        throw ContactRepositoryException('Geçersiz website URL formatı');
      }
    }
  }
}

class ContactRepositoryException implements Exception {
  final String message;
  ContactRepositoryException(this.message);

  @override
  String toString() => 'ContactRepositoryException: $message';
}