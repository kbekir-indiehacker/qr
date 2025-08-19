import 'package:nfc_manager/nfc_manager.dart';

class NfcHelper {
  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  static Future<void> startNfcSession({
    required Function(String message) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (!available) {
        onError('NFC not available on this device');
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            // Simple tag detection for now
            final tagId = tag.toString();
            final message = 'NFC Tag detected\nTag: $tagId';
            
            await NfcManager.instance.stopSession();
            onSuccess(message);
          } catch (e) {
            await NfcManager.instance.stopSession();
            onError('Failed to read tag: ${e.toString()}');
          }
        },
      );
    } catch (e) {
      onError('NFC session failed: ${e.toString()}');
    }
  }

  static Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Session may already be stopped
    }
  }

  static String createBusinessCardData({
    required String name,
    required String company,
    required String phone,
    required String email,
    String? website,
    String? address,
  }) {
    // Create simple business card format
    final buffer = StringBuffer();
    buffer.writeln('BUSINESS CARD');
    buffer.writeln('Name: $name');
    buffer.writeln('Company: $company');
    buffer.writeln('Phone: $phone');
    buffer.writeln('Email: $email');
    
    if (website != null && website.isNotEmpty) {
      buffer.writeln('Website: $website');
    }
    
    if (address != null && address.isNotEmpty) {
      buffer.writeln('Address: $address');
    }
    
    return buffer.toString();
  }

  static Map<String, String>? parseBusinessCardData(String data) {
    final Map<String, String> result = {};
    final lines = data.split('\n');
    
    for (final line in lines) {
      if (line.startsWith('Name: ')) {
        result['name'] = line.substring(6);
      } else if (line.startsWith('Company: ')) {
        result['company'] = line.substring(9);
      } else if (line.startsWith('Phone: ')) {
        result['phone'] = line.substring(7);
      } else if (line.startsWith('Email: ')) {
        result['email'] = line.substring(7);
      } else if (line.startsWith('Website: ')) {
        result['website'] = line.substring(9);
      } else if (line.startsWith('Address: ')) {
        result['address'] = line.substring(9);
      }
    }
    
    return result.isNotEmpty ? result : null;
  }
}