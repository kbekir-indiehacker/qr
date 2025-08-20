import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/database_constants.dart';

class LocalStorage {
  static LocalStorage? _instance;
  static SharedPreferences? _prefs;

  LocalStorage._internal();

  factory LocalStorage() {
    _instance ??= LocalStorage._internal();
    return _instance!;
  }

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Theme preferences
  Future<void> setThemeMode(String themeMode) async {
    final preferences = await prefs;
    await preferences.setString('theme_mode', themeMode);
  }

  Future<String> getThemeMode() async {
    final preferences = await prefs;
    return preferences.getString('theme_mode') ?? 'system';
  }

  // Language preferences
  Future<void> setLanguage(String languageCode) async {
    final preferences = await prefs;
    await preferences.setString('language', languageCode);
  }

  Future<String> getLanguage() async {
    final preferences = await prefs;
    return preferences.getString('language') ?? 'tr';
  }

  // Sort order preferences
  Future<void> setSortOrder(String sortOrder) async {
    final preferences = await prefs;
    await preferences.setString('sort_order', sortOrder);
  }

  Future<String> getSortOrder() async {
    final preferences = await prefs;
    return preferences.getString('sort_order') ?? DatabaseConstants.sortByName;
  }

  // Auto backup preferences
  Future<void> setAutoBackup(bool autoBackup) async {
    final preferences = await prefs;
    await preferences.setBool('auto_backup', autoBackup);
  }

  Future<bool> getAutoBackup() async {
    final preferences = await prefs;
    return preferences.getBool('auto_backup') ?? true;
  }

  // Backup frequency (in days)
  Future<void> setBackupFrequency(int days) async {
    final preferences = await prefs;
    await preferences.setInt('backup_frequency', days);
  }

  Future<int> getBackupFrequency() async {
    final preferences = await prefs;
    return preferences.getInt('backup_frequency') ?? 7; // Default 7 days
  }

  // Last backup timestamp
  Future<void> setLastBackupTime(DateTime dateTime) async {
    final preferences = await prefs;
    await preferences.setInt('last_backup_time', dateTime.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastBackupTime() async {
    final preferences = await prefs;
    final timestamp = preferences.getInt('last_backup_time');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // OCR usage tracking
  Future<void> setOcrUsageCount(int count) async {
    final preferences = await prefs;
    await preferences.setInt('ocr_usage_count', count);
  }

  Future<int> getOcrUsageCount() async {
    final preferences = await prefs;
    return preferences.getInt('ocr_usage_count') ?? 0;
  }

  Future<void> incrementOcrUsage() async {
    final currentCount = await getOcrUsageCount();
    await setOcrUsageCount(currentCount + 1);
  }

  // OCR reset date (monthly reset)
  Future<void> setOcrResetDate(DateTime dateTime) async {
    final preferences = await prefs;
    await preferences.setInt('ocr_reset_date', dateTime.millisecondsSinceEpoch);
  }

  Future<DateTime?> getOcrResetDate() async {
    final preferences = await prefs;
    final timestamp = preferences.getInt('ocr_reset_date');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<bool> shouldResetOcrUsage() async {
    final resetDate = await getOcrResetDate();
    if (resetDate == null) {
      // First time, set reset date to next month
      await setOcrResetDate(DateTime.now().add(const Duration(days: 30)));
      return false;
    }

    final now = DateTime.now();
    if (now.isAfter(resetDate)) {
      // Reset usage and set new reset date
      await setOcrUsageCount(0);
      await setOcrResetDate(now.add(const Duration(days: 30)));
      return true;
    }

    return false;
  }

  Future<bool> canUseOcr() async {
    await shouldResetOcrUsage(); // Check and reset if needed
    final isPremium = await getPremiumStatus();
    if (isPremium) return true;

    final usageCount = await getOcrUsageCount();
    return usageCount < DatabaseConstants.maxOcrUsagePerMonth;
  }

  // Premium status
  Future<void> setPremiumStatus(bool isPremium) async {
    final preferences = await prefs;
    await preferences.setBool('premium_status', isPremium);
  }

  Future<bool> getPremiumStatus() async {
    final preferences = await prefs;
    return preferences.getBool('premium_status') ?? false;
  }

  // Premium expiry date
  Future<void> setPremiumExpiryDate(DateTime dateTime) async {
    final preferences = await prefs;
    await preferences.setInt('premium_expiry_date', dateTime.millisecondsSinceEpoch);
  }

  Future<DateTime?> getPremiumExpiryDate() async {
    final preferences = await prefs;
    final timestamp = preferences.getInt('premium_expiry_date');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<bool> isPremiumExpired() async {
    final expiryDate = await getPremiumExpiryDate();
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate);
  }

  // First launch detection
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    final preferences = await prefs;
    await preferences.setBool('first_launch', isFirstLaunch);
  }

  Future<bool> isFirstLaunch() async {
    final preferences = await prefs;
    return preferences.getBool('first_launch') ?? true;
  }

  // Tutorial completion
  Future<void> setTutorialCompleted(bool completed) async {
    final preferences = await prefs;
    await preferences.setBool('tutorial_completed', completed);
  }

  Future<bool> isTutorialCompleted() async {
    final preferences = await prefs;
    return preferences.getBool('tutorial_completed') ?? false;
  }

  // App version (for migration purposes)
  Future<void> setAppVersion(String version) async {
    final preferences = await prefs;
    await preferences.setString('app_version', version);
  }

  Future<String?> getAppVersion() async {
    final preferences = await prefs;
    return preferences.getString('app_version');
  }

  // Contact view preferences
  Future<void> setContactViewMode(String viewMode) async {
    final preferences = await prefs;
    await preferences.setString('contact_view_mode', viewMode);
  }

  Future<String> getContactViewMode() async {
    final preferences = await prefs;
    return preferences.getString('contact_view_mode') ?? 'grid'; // 'grid' or 'list'
  }

  // Show starred contacts first
  Future<void> setShowStarredFirst(bool showFirst) async {
    final preferences = await prefs;
    await preferences.setBool('show_starred_first', showFirst);
  }

  Future<bool> getShowStarredFirst() async {
    final preferences = await prefs;
    return preferences.getBool('show_starred_first') ?? false;
  }

  // Recent searches
  Future<void> addRecentSearch(String query) async {
    final preferences = await prefs;
    final recentSearches = await getRecentSearches();
    
    // Remove if already exists
    recentSearches.remove(query);
    
    // Add to beginning
    recentSearches.insert(0, query);
    
    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    
    await preferences.setStringList('recent_searches', recentSearches);
  }

  Future<List<String>> getRecentSearches() async {
    final preferences = await prefs;
    return preferences.getStringList('recent_searches') ?? [];
  }

  Future<void> clearRecentSearches() async {
    final preferences = await prefs;
    await preferences.remove('recent_searches');
  }

  // Export settings
  Future<void> setLastExportPath(String path) async {
    final preferences = await prefs;
    await preferences.setString('last_export_path', path);
  }

  Future<String?> getLastExportPath() async {
    final preferences = await prefs;
    return preferences.getString('last_export_path');
  }

  // Notification settings
  Future<void> setBackupNotifications(bool enabled) async {
    final preferences = await prefs;
    await preferences.setBool('backup_notifications', enabled);
  }

  Future<bool> getBackupNotifications() async {
    final preferences = await prefs;
    return preferences.getBool('backup_notifications') ?? true;
  }

  // Card scanning settings
  Future<void> setAutoScanEnabled(bool enabled) async {
    final preferences = await prefs;
    await preferences.setBool('auto_scan_enabled', enabled);
  }

  Future<bool> getAutoScanEnabled() async {
    final preferences = await prefs;
    return preferences.getBool('auto_scan_enabled') ?? true;
  }

  Future<void> setScanConfidenceThreshold(double threshold) async {
    final preferences = await prefs;
    await preferences.setDouble('scan_confidence_threshold', threshold);
  }

  Future<double> getScanConfidenceThreshold() async {
    final preferences = await prefs;
    return preferences.getDouble('scan_confidence_threshold') ?? 0.8;
  }

  // Statistics
  Future<void> setTotalContactsCreated(int count) async {
    final preferences = await prefs;
    await preferences.setInt('total_contacts_created', count);
  }

  Future<int> getTotalContactsCreated() async {
    final preferences = await prefs;
    return preferences.getInt('total_contacts_created') ?? 0;
  }

  Future<void> incrementTotalContactsCreated() async {
    final currentCount = await getTotalContactsCreated();
    await setTotalContactsCreated(currentCount + 1);
  }

  Future<void> setTotalScansPerformed(int count) async {
    final preferences = await prefs;
    await preferences.setInt('total_scans_performed', count);
  }

  Future<int> getTotalScansPerformed() async {
    final preferences = await prefs;
    return preferences.getInt('total_scans_performed') ?? 0;
  }

  Future<void> incrementTotalScansPerformed() async {
    final currentCount = await getTotalScansPerformed();
    await setTotalScansPerformed(currentCount + 1);
  }

  // Clear all data
  Future<void> clearAllData() async {
    final preferences = await prefs;
    await preferences.clear();
  }

  // Utility methods
  Future<Map<String, dynamic>> getAllPreferences() async {
    final preferences = await prefs;
    final keys = preferences.getKeys();
    final Map<String, dynamic> allPrefs = {};
    
    for (final key in keys) {
      allPrefs[key] = preferences.get(key);
    }
    
    return allPrefs;
  }

  Future<bool> hasKey(String key) async {
    final preferences = await prefs;
    return preferences.containsKey(key);
  }

  Future<void> removeKey(String key) async {
    final preferences = await prefs;
    await preferences.remove(key);
  }
}