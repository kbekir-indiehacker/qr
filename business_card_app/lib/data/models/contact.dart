import 'dart:convert';

class Contact {
  int? id;
  String name;
  String? company;
  String? title;
  String? phone;
  String? email;
  String? website;
  List<String> tags;
  String? notes;
  DateTime createdAt;
  DateTime? updatedAt;
  bool isStarred;
  String? cardImagePath;
  Map<String, String>? socialMedia;

  Contact({
    this.id,
    required this.name,
    this.company,
    this.title,
    this.phone,
    this.email,
    this.website,
    this.tags = const [],
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.isStarred = false,
    this.cardImagePath,
    this.socialMedia,
  }) : createdAt = createdAt ?? DateTime.now();

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'title': title,
      'phone': phone,
      'email': email,
      'website': website,
      'tags': tags,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStarred': isStarred,
      'cardImagePath': cardImagePath,
      'socialMedia': socialMedia,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      name: json['name'] as String,
      company: json['company'] as String?,
      title: json['title'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isStarred: json['isStarred'] as bool? ?? false,
      cardImagePath: json['cardImagePath'] as String?,
      socialMedia: json['socialMedia'] != null
          ? Map<String, String>.from(json['socialMedia'])
          : null,
    );
  }

  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'title': title,
      'phone': phone,
      'email': email,
      'website': website,
      'tags': jsonEncode(tags),
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_starred': isStarred ? 1 : 0,
      'card_image_path': cardImagePath,
      'social_media': socialMedia != null ? jsonEncode(socialMedia) : null,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String,
      company: map['company'] as String?,
      title: map['title'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      isStarred: (map['is_starred'] as int) == 1,
      cardImagePath: map['card_image_path'] as String?,
      socialMedia: map['social_media'] != null
          ? Map<String, String>.from(jsonDecode(map['social_media'] as String))
          : null,
    );
  }

  // Copy with method
  Contact copyWith({
    int? id,
    String? name,
    String? company,
    String? title,
    String? phone,
    String? email,
    String? website,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
    String? cardImagePath,
    Map<String, String>? socialMedia,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
      cardImagePath: cardImagePath ?? this.cardImagePath,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.name == name &&
        other.company == company &&
        other.title == title &&
        other.phone == phone &&
        other.email == email &&
        other.website == website &&
        _listEquals(other.tags, tags) &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isStarred == isStarred &&
        other.cardImagePath == cardImagePath &&
        _mapEquals(other.socialMedia, socialMedia);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      company,
      title,
      phone,
      email,
      website,
      Object.hashAll(tags),
      notes,
      createdAt,
      updatedAt,
      isStarred,
      cardImagePath,
      socialMedia,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, company: $company, '
        'title: $title, phone: $phone, email: $email, '
        'website: $website, tags: $tags, notes: $notes, '
        'createdAt: $createdAt, updatedAt: $updatedAt, '
        'isStarred: $isStarred, cardImagePath: $cardImagePath, '
        'socialMedia: $socialMedia)';
  }

  // Helper methods for equality comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }

  // Utility methods
  bool get hasPhoneNumber => phone != null && phone!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasCompany => company != null && company!.isNotEmpty;
  bool get hasTitle => title != null && title!.isNotEmpty;
  bool get hasSocialMedia => socialMedia != null && socialMedia!.isNotEmpty;
  bool get hasCardImage => cardImagePath != null && cardImagePath!.isNotEmpty;

  String get displayName {
    if (hasCompany && hasTitle) {
      return '$name, $title at $company';
    } else if (hasCompany) {
      return '$name at $company';
    } else if (hasTitle) {
      return '$name, $title';
    }
    return name;
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '';
  }
}