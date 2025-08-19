import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../constants/database_constants.dart';

class DatabaseUtils {
  // Date formatters
  static String formatBackupFileName(DateTime dateTime) {
    final formatted = dateTime.toIso8601String().replaceAll(':', '-').split('.')[0];
    return 'backup_$formatted${DatabaseConstants.backupFileExtension}';
  }

  static String formatDisplayDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  // File size formatter
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return "${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}";
  }

  // Backup file operations
  static Future<String> getBackupDirectory() async {
    // This would typically use path_provider to get the documents directory
    // For now, we'll return a placeholder
    return path.join(Directory.systemTemp.path, DatabaseConstants.backupFolderName);
  }

  static Future<File> createBackupFile(String content, {String? fileName}) async {
    final backupDir = await getBackupDirectory();
    final directory = Directory(backupDir);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    fileName ??= formatBackupFileName(DateTime.now());
    final filePath = path.join(backupDir, fileName);
    final file = File(filePath);
    
    await file.writeAsString(content);
    return file;
  }

  static Future<String> readBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw DatabaseException('Yedekleme dosyası bulunamadı: $filePath');
    }
    return await file.readAsString();
  }

  static Future<List<File>> getBackupFiles() async {
    final backupDir = await getBackupDirectory();
    final directory = Directory(backupDir);
    
    if (!await directory.exists()) {
      return [];
    }
    
    final files = await directory
        .list()
        .where((entity) => 
            entity is File && 
            entity.path.endsWith(DatabaseConstants.backupFileExtension))
        .cast<File>()
        .toList();
    
    // Sort by modification date (newest first)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    return files;
  }

  static Future<void> deleteBackupFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> cleanOldBackupFiles({int maxFiles = 10}) async {
    final backupFiles = await getBackupFiles();
    
    if (backupFiles.length > maxFiles) {
      final filesToDelete = backupFiles.skip(maxFiles);
      for (final file in filesToDelete) {
        await file.delete();
      }
    }
  }

  // JSON validation and processing
  static bool isValidBackupJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) return false;
      
      // Check required fields
      if (!data.containsKey('version') || 
          !data.containsKey('timestamp') || 
          !data.containsKey('contacts')) {
        return false;
      }
      
      // Validate contacts array
      final contacts = data['contacts'];
      if (contacts is! List) return false;
      
      // Validate each contact
      for (final contact in contacts) {
        if (contact is! Map<String, dynamic> || 
            !contact.containsKey('name') || 
            contact['name'] is! String ||
            (contact['name'] as String).isEmpty) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic> getBackupMetadata(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) {
        throw DatabaseException('Geçersiz yedekleme formatı');
      }
      
      final contacts = data['contacts'] as List? ?? [];
      final timestamp = data['timestamp'] as String?;
      final version = data['version'];
      
      return {
        'contactCount': contacts.length,
        'timestamp': timestamp,
        'version': version,
        'fileSize': jsonString.length,
      };
    } catch (e) {
      throw DatabaseException('Yedekleme meta verileri okunamadı: $e');
    }
  }

  // Database maintenance utilities
  static bool isValidContactName(String name) {
    return name.trim().isNotEmpty && 
           name.length <= DatabaseConstants.maxContactNameLength;
  }

  static bool isValidEmail(String email) {
    if (email.isEmpty) return true; // Optional field
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return true; // Optional field
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  static bool isValidWebsite(String website) {
    if (website.isEmpty) return true; // Optional field
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(website);
  }

  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  // Search utilities
  static List<String> extractSearchTerms(String query) {
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
  }

  static bool matchesSearchTerms(String text, List<String> terms) {
    if (text.isEmpty || terms.isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    return terms.every((term) => lowerText.contains(term));
  }

  // Tag utilities
  static List<String> sanitizeTags(List<String> tags) {
    return tags
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => tag.trim().toLowerCase())
        .toSet() // Remove duplicates
        .take(DatabaseConstants.maxTagsPerContact)
        .toList();
  }

  static bool isValidTag(String tag) {
    return tag.trim().isNotEmpty && 
           tag.length <= 50 && // Reasonable tag length limit
           RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(tag);
  }

  // Statistics utilities
  static Map<String, double> calculateContactCompleteness(Map<String, dynamic> contactData) {
    final fields = {
      'name': contactData['name'] != null && contactData['name'].toString().isNotEmpty,
      'company': contactData['company'] != null && contactData['company'].toString().isNotEmpty,
      'title': contactData['title'] != null && contactData['title'].toString().isNotEmpty,
      'phone': contactData['phone'] != null && contactData['phone'].toString().isNotEmpty,
      'email': contactData['email'] != null && contactData['email'].toString().isNotEmpty,
      'website': contactData['website'] != null && contactData['website'].toString().isNotEmpty,
      'notes': contactData['notes'] != null && contactData['notes'].toString().isNotEmpty,
      'tags': contactData['tags'] != null && (contactData['tags'] as List).isNotEmpty,
      'socialMedia': contactData['socialMedia'] != null && (contactData['socialMedia'] as Map).isNotEmpty,
    };
    
    final totalFields = fields.length;
    final completedFields = fields.values.where((completed) => completed).length;
    final completenessPercentage = (completedFields / totalFields) * 100;
    
    return {
      'totalFields': totalFields.toDouble(),
      'completedFields': completedFields.toDouble(),
      'completenessPercentage': completenessPercentage,
    };
  }

  // Encryption utilities (for future premium features)
  static String generateBackupChecksum(String content) {
    // Simple checksum for backup validation
    int checksum = 0;
    for (int i = 0; i < content.length; i++) {
      checksum += content.codeUnitAt(i);
    }
    return checksum.toRadixString(16);
  }

  static bool validateBackupChecksum(String content, String expectedChecksum) {
    return generateBackupChecksum(content) == expectedChecksum;
  }

  // Migration utilities
  static Map<String, dynamic> migrateContactData(Map<String, dynamic> data, int fromVersion, int toVersion) {
    Map<String, dynamic> migratedData = Map.from(data);
    
    // Handle version migrations
    if (fromVersion < toVersion) {
      // Example migration logic for future versions
      if (fromVersion < 2) {
        // Migration from version 1 to 2
        migratedData['version'] = 2;
        // Add any necessary data transformations
      }
    }
    
    return migratedData;
  }

  // Error handling utilities
  static String getErrorMessage(dynamic error) {
    if (error is DatabaseException) {
      return error.message;
    } else if (error is FileSystemException) {
      return 'Dosya sistemi hatası: ${error.message}';
    } else if (error is FormatException) {
      return 'Veri formatı hatası: ${error.message}';
    } else {
      return 'Beklenmeyen hata: $error';
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  DatabaseException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'DatabaseException: $message';
}

class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int contactCount;
  final int fileSize;
  final String type;
  
  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.contactCount,
    required this.fileSize,
    required this.type,
  });
  
  factory BackupInfo.fromFile(File file, Map<String, dynamic> metadata) {
    return BackupInfo(
      fileName: path.basename(file.path),
      filePath: file.path,
      createdAt: file.lastModifiedSync(),
      contactCount: metadata['contactCount'] ?? 0,
      fileSize: file.lengthSync(),
      type: DatabaseConstants.backupTypeManual,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'contactCount': contactCount,
      'fileSize': fileSize,
      'type': type,
    };
  }
  
  String get formattedSize => DatabaseUtils.formatFileSize(fileSize);
  String get formattedDate => DatabaseUtils.formatDisplayDate(createdAt);
  String get relativeDate => DatabaseUtils.formatRelativeDate(createdAt);
}