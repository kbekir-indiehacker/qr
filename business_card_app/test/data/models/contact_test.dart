import 'package:flutter_test/flutter_test.dart';
import 'package:business_card_app/data/models/contact.dart';

void main() {
  group('Contact Model Tests', () {
    late Contact testContact;

    setUp(() {
      testContact = Contact(
        id: 1,
        name: 'John Doe',
        company: 'Tech Corp',
        title: 'Software Engineer',
        phone: '+1234567890',
        email: 'john.doe@techcorp.com',
        website: 'https://johndoe.com',
        tags: ['developer', 'tech'],
        notes: 'Met at tech conference',
        isStarred: true,
        socialMedia: {'linkedin': 'johndoe', 'twitter': '@johndoe'},
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('should create a contact with required fields', () {
      final contact = Contact(name: 'Jane Doe');
      
      expect(contact.name, 'Jane Doe');
      expect(contact.id, isNull);
      expect(contact.isStarred, false);
      expect(contact.tags, isEmpty);
      expect(contact.createdAt, isNotNull);
    });

    test('should convert contact to JSON correctly', () {
      final json = testContact.toJson();
      
      expect(json['id'], 1);
      expect(json['name'], 'John Doe');
      expect(json['company'], 'Tech Corp');
      expect(json['title'], 'Software Engineer');
      expect(json['phone'], '+1234567890');
      expect(json['email'], 'john.doe@techcorp.com');
      expect(json['website'], 'https://johndoe.com');
      expect(json['tags'], ['developer', 'tech']);
      expect(json['notes'], 'Met at tech conference');
      expect(json['isStarred'], true);
      expect(json['socialMedia'], {'linkedin': 'johndoe', 'twitter': '@johndoe'});
      expect(json['createdAt'], isA<String>());
    });

    test('should create contact from JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'John Doe',
        'company': 'Tech Corp',
        'title': 'Software Engineer',
        'phone': '+1234567890',
        'email': 'john.doe@techcorp.com',
        'website': 'https://johndoe.com',
        'tags': ['developer', 'tech'],
        'notes': 'Met at tech conference',
        'createdAt': '2024-01-01T00:00:00.000',
        'isStarred': true,
        'socialMedia': {'linkedin': 'johndoe', 'twitter': '@johndoe'},
      };

      final contact = Contact.fromJson(json);
      
      expect(contact.id, 1);
      expect(contact.name, 'John Doe');
      expect(contact.company, 'Tech Corp');
      expect(contact.title, 'Software Engineer');
      expect(contact.phone, '+1234567890');
      expect(contact.email, 'john.doe@techcorp.com');
      expect(contact.website, 'https://johndoe.com');
      expect(contact.tags, ['developer', 'tech']);
      expect(contact.notes, 'Met at tech conference');
      expect(contact.isStarred, true);
      expect(contact.socialMedia, {'linkedin': 'johndoe', 'twitter': '@johndoe'});
      expect(contact.createdAt, DateTime(2024, 1, 1));
    });

    test('should convert contact to map for SQLite correctly', () {
      final map = testContact.toMap();
      
      expect(map['id'], 1);
      expect(map['name'], 'John Doe');
      expect(map['company'], 'Tech Corp');
      expect(map['title'], 'Software Engineer');
      expect(map['phone'], '+1234567890');
      expect(map['email'], 'john.doe@techcorp.com');
      expect(map['website'], 'https://johndoe.com');
      expect(map['tags'], '["developer","tech"]');
      expect(map['notes'], 'Met at tech conference');
      expect(map['is_starred'], 1);
      expect(map['social_media'], '{"linkedin":"johndoe","twitter":"@johndoe"}');
      expect(map['created_at'], isA<int>());
    });

    test('should create contact from map correctly', () {
      final map = {
        'id': 1,
        'name': 'John Doe',
        'company': 'Tech Corp',
        'title': 'Software Engineer',
        'phone': '+1234567890',
        'email': 'john.doe@techcorp.com',
        'website': 'https://johndoe.com',
        'tags': '["developer","tech"]',
        'notes': 'Met at tech conference',
        'created_at': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'is_starred': 1,
        'social_media': '{"linkedin":"johndoe","twitter":"@johndoe"}',
      };

      final contact = Contact.fromMap(map);
      
      expect(contact.id, 1);
      expect(contact.name, 'John Doe');
      expect(contact.company, 'Tech Corp');
      expect(contact.title, 'Software Engineer');
      expect(contact.phone, '+1234567890');
      expect(contact.email, 'john.doe@techcorp.com');
      expect(contact.website, 'https://johndoe.com');
      expect(contact.tags, ['developer', 'tech']);
      expect(contact.notes, 'Met at tech conference');
      expect(contact.isStarred, true);
      expect(contact.socialMedia, {'linkedin': 'johndoe', 'twitter': '@johndoe'});
      expect(contact.createdAt, DateTime(2024, 1, 1));
    });

    test('should create copy with updated fields', () {
      final updatedContact = testContact.copyWith(
        name: 'Jane Doe',
        isStarred: false,
      );
      
      expect(updatedContact.name, 'Jane Doe');
      expect(updatedContact.isStarred, false);
      expect(updatedContact.company, 'Tech Corp'); // Unchanged
      expect(updatedContact.id, 1); // Unchanged
    });

    test('should check equality correctly', () {
      final contact1 = Contact(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );
      
      final contact2 = Contact(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );
      
      final contact3 = Contact(
        id: 2,
        name: 'John Doe',
        email: 'john@example.com',
      );
      
      expect(contact1 == contact2, true);
      expect(contact1 == contact3, false);
      expect(contact1.hashCode == contact2.hashCode, true);
    });

    test('should generate correct display name', () {
      expect(testContact.displayName, 'John Doe, Software Engineer at Tech Corp');
      
      final contactWithoutTitle = testContact.copyWith(title: null);
      expect(contactWithoutTitle.displayName, 'John Doe at Tech Corp');
      
      final contactWithoutCompany = testContact.copyWith(company: null);
      expect(contactWithoutCompany.displayName, 'John Doe, Software Engineer');
      
      final contactNameOnly = testContact.copyWith(company: null, title: null);
      expect(contactNameOnly.displayName, 'John Doe');
    });

    test('should generate correct initials', () {
      expect(testContact.initials, 'JD');
      
      final singleName = Contact(name: 'John');
      expect(singleName.initials, 'J');
      
      final multipleName = Contact(name: 'John Michael Doe');
      expect(multipleName.initials, 'JD');
      
      final emptyName = Contact(name: '');
      expect(emptyName.initials, '');
    });

    test('should check utility properties correctly', () {
      expect(testContact.hasPhoneNumber, true);
      expect(testContact.hasEmail, true);
      expect(testContact.hasWebsite, true);
      expect(testContact.hasCompany, true);
      expect(testContact.hasTitle, true);
      expect(testContact.hasSocialMedia, true);
      
      final emptyContact = Contact(name: 'Test');
      expect(emptyContact.hasPhoneNumber, false);
      expect(emptyContact.hasEmail, false);
      expect(emptyContact.hasWebsite, false);
      expect(emptyContact.hasCompany, false);
      expect(emptyContact.hasTitle, false);
      expect(emptyContact.hasSocialMedia, false);
    });

    test('should handle null and empty values correctly', () {
      final contactWithNulls = Contact.fromJson({
        'name': 'Test User',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      expect(contactWithNulls.name, 'Test User');
      expect(contactWithNulls.company, isNull);
      expect(contactWithNulls.tags, isEmpty);
      expect(contactWithNulls.isStarred, false);
      expect(contactWithNulls.socialMedia, isNull);
    });

    test('should handle toString correctly', () {
      final toString = testContact.toString();
      expect(toString, contains('Contact('));
      expect(toString, contains('name: John Doe'));
      expect(toString, contains('id: 1'));
    });
  });
}