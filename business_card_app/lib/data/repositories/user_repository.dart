import '../datasources/local_storage.dart';
import '../datasources/database_helper.dart';

class UserData {
  final String name;
  final String email;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final bool isFirstLaunch;
  final bool tutorialCompleted;
  final String appVersion;

  UserData({
    required this.name,
    required this.email,
    required this.isPremium,
    this.premiumExpiryDate,
    required this.isFirstLaunch,
    required this.tutorialCompleted,
    required this.appVersion,
  });

  UserData copyWith({
    String? name,
    String? email,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    bool? isFirstLaunch,
    bool? tutorialCompleted,
    String? appVersion,
  }) {
    return UserData(
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'isFirstLaunch': isFirstLaunch,
      'tutorialCompleted': tutorialCompleted,
      'appVersion': appVersion,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isPremium: json['isPremium'] ?? false,
      premiumExpiryDate: json['premiumExpiryDate'] != null
          ? DateTime.parse(json['premiumExpiryDate'])
          : null,
      isFirstLaunch: json['isFirstLaunch'] ?? true,
      tutorialCompleted: json['tutorialCompleted'] ?? false,
      appVersion: json['appVersion'] ?? '1.0.0',
    );
  }
}

abstract class UserRepositoryInterface {
  Future<UserData> getUserData();
  Future<void> updateUserData(UserData userData);
  Future<bool> isPremiumUser();
  Future<void> setPremiumStatus(bool isPremium, DateTime? expiryDate);
  Future<bool> isFirstLaunch();
  Future<void> setFirstLaunchCompleted();
  Future<bool> isTutorialCompleted();
  Future<void> setTutorialCompleted();
}

class UserRepository implements UserRepositoryInterface {
  final LocalStorage _localStorage;
  final DatabaseHelper _databaseHelper;

  UserRepository({
    LocalStorage? localStorage,
    DatabaseHelper? databaseHelper,
  })  : _localStorage = localStorage ?? LocalStorage(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Future<UserData> getUserData() async {
    try {
      final name = await _getUserName();
      final email = await _getUserEmail();
      final isPremium = await _localStorage.getPremiumStatus();
      final premiumExpiryDate = await _localStorage.getPremiumExpiryDate();
      final isFirstLaunch = await _localStorage.isFirstLaunch();
      final tutorialCompleted = await _localStorage.isTutorialCompleted();
      final appVersion = await _localStorage.getAppVersion() ?? '1.0.0';

      return UserData(
        name: name,
        email: email,
        isPremium: isPremium && !await _localStorage.isPremiumExpired(),
        premiumExpiryDate: premiumExpiryDate,
        isFirstLaunch: isFirstLaunch,
        tutorialCompleted: tutorialCompleted,
        appVersion: appVersion,
      );
    } catch (e) {
      throw UserRepositoryException('Kullanıcı verileri alınırken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateUserData(UserData userData) async {
    try {
      await _setUserName(userData.name);
      await _setUserEmail(userData.email);
      await _localStorage.setPremiumStatus(userData.isPremium);
      
      if (userData.premiumExpiryDate != null) {
        await _localStorage.setPremiumExpiryDate(userData.premiumExpiryDate!);
      }
      
      await _localStorage.setFirstLaunch(userData.isFirstLaunch);
      await _localStorage.setTutorialCompleted(userData.tutorialCompleted);
      await _localStorage.setAppVersion(userData.appVersion);
    } catch (e) {
      throw UserRepositoryException('Kullanıcı verileri güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> isPremiumUser() async {
    try {
      final isPremium = await _localStorage.getPremiumStatus();
      if (!isPremium) return false;
      
      // Check if premium has expired
      final isExpired = await _localStorage.isPremiumExpired();
      if (isExpired) {
        // Update premium status to false
        await _localStorage.setPremiumStatus(false);
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setPremiumStatus(bool isPremium, DateTime? expiryDate) async {
    try {
      await _localStorage.setPremiumStatus(isPremium);
      
      if (isPremium && expiryDate != null) {
        await _localStorage.setPremiumExpiryDate(expiryDate);
      }
      
      // Reset OCR usage if user becomes premium
      if (isPremium) {
        await _localStorage.setOcrUsageCount(0);
      }
    } catch (e) {
      throw UserRepositoryException('Premium durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> isFirstLaunch() async {
    try {
      return await _localStorage.isFirstLaunch();
    } catch (e) {
      return true; // Default to first launch on error
    }
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    try {
      await _localStorage.setFirstLaunch(false);
    } catch (e) {
      throw UserRepositoryException('İlk başlatma durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> isTutorialCompleted() async {
    try {
      return await _localStorage.isTutorialCompleted();
    } catch (e) {
      return false; // Default to tutorial not completed on error
    }
  }

  @override
  Future<void> setTutorialCompleted() async {
    try {
      await _localStorage.setTutorialCompleted(true);
    } catch (e) {
      throw UserRepositoryException('Öğretici durumu güncellenirken hata oluştu: $e');
    }
  }

  // Premium management methods
  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      return await _localStorage.getPremiumExpiryDate();
    } catch (e) {
      return null;
    }
  }

  Future<int> getDaysUntilPremiumExpiry() async {
    try {
      final expiryDate = await getPremiumExpiryDate();
      if (expiryDate == null) return 0;
      
      final now = DateTime.now();
      final difference = expiryDate.difference(now);
      return difference.inDays > 0 ? difference.inDays : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> shouldShowPremiumWarning() async {
    try {
      final isPremium = await isPremiumUser();
      if (!isPremium) return false;
      
      final daysUntilExpiry = await getDaysUntilPremiumExpiry();
      return daysUntilExpiry <= 7; // Show warning 7 days before expiry
    } catch (e) {
      return false;
    }
  }

  // User profile methods
  Future<String> _getUserName() async {
    try {
      return await _databaseHelper.getSetting<String>('user_name') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _setUserName(String name) async {
    try {
      await _databaseHelper.setSetting('user_name', name, 'string');
    } catch (e) {
      throw UserRepositoryException('Kullanıcı adı güncellenirken hata oluştu: $e');
    }
  }

  Future<String> _getUserEmail() async {
    try {
      return await _databaseHelper.getSetting<String>('user_email') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _setUserEmail(String email) async {
    try {
      // Validate email format
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(email)) {
          throw UserRepositoryException('Geçersiz e-posta formatı');
        }
      }
      
      await _databaseHelper.setSetting('user_email', email, 'string');
    } catch (e) {
      if (e is UserRepositoryException) rethrow;
      throw UserRepositoryException('E-posta güncellenirken hata oluştu: $e');
    }
  }

  // Statistics and usage methods
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final totalContactsCreated = await _localStorage.getTotalContactsCreated();
      final totalScansPerformed = await _localStorage.getTotalScansPerformed();
      final ocrUsageCount = await _localStorage.getOcrUsageCount();
      final isPremium = await isPremiumUser();
      final premiumExpiryDate = await getPremiumExpiryDate();
      
      return {
        'totalContactsCreated': totalContactsCreated,
        'totalScansPerformed': totalScansPerformed,
        'ocrUsageCount': ocrUsageCount,
        'isPremium': isPremium,
        'premiumExpiryDate': premiumExpiryDate,
        'daysUntilPremiumExpiry': await getDaysUntilPremiumExpiry(),
      };
    } catch (e) {
      throw UserRepositoryException('Kullanıcı istatistikleri alınırken hata oluştu: $e');
    }
  }

  Future<void> resetUserData() async {
    try {
      await _localStorage.clearAllData();
      // Reinitialize default settings
      await _localStorage.setFirstLaunch(true);
      await _localStorage.setTutorialCompleted(false);
      await _localStorage.setPremiumStatus(false);
    } catch (e) {
      throw UserRepositoryException('Kullanıcı verileri sıfırlanırken hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final userData = await getUserData();
      final statistics = await getUserStatistics();
      final preferences = await _localStorage.getAllPreferences();
      
      return {
        'userData': userData.toJson(),
        'statistics': statistics,
        'preferences': preferences,
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw UserRepositoryException('Kullanıcı verileri dışa aktarılırken hata oluştu: $e');
    }
  }
}

class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);

  @override
  String toString() => 'UserRepositoryException: $message';
}