# Business Card App - Claude Code Kuralları

## Genel Proje Bilgileri
- Proje Adı: Business Card App
- Ana Dil: Flutter/Dart
- Platform: Android & iOS (Cross-platform)
- Geliştirme Ortamı: macOS (Darwin)

## Kod Yazma Kuralları

### Genel Kurallar
- Türkçe yorum satırları kullan
- Fonksiyon ve değişken isimlerinde anlamlı İngilizce isimler tercih et
- Kodda tutarlı indentasyon kullan (tabs/spaces)
- Her dosyada maksimum 500 satır kural

### Commit Kuralları
- Commit mesajları Türkçe yazılacak
- Format: "tip: açıklama"
- Örnekler:
  - feat: yeni özellik eklendi
  - fix: hata düzeltildi
  - refactor: kod yeniden düzenlendi
  - docs: dokümantasyon güncellendi

### Test Kuralları
- Her yeni özellik için test yazılmalı
- Test dosyaları .test veya .spec uzantısı kullanmalı
- Test coverage minimum %80 olmalı

### Dosya Yapısı (Flutter)
- lib/ klasörü ana kod dosyalarını içermeli
- test/ klasörü test dosyalarını içermeli
- lib/core/ klasörü tema, sabitler ve utils içermeli
- lib/data/ klasörü models, repositories ve datasources içermeli
- lib/presentation/ klasörü screens, widgets ve providers içermeli
- Konfigürasyon dosyaları root dizinde (pubspec.yaml, l10n.yaml)

### Linting ve Formatting
- Kod style consistency için linter kullan
- Automatic formatting etkin olmalı
- Pre-commit hooks kullan

## Build ve Deploy Kuralları
- Build komutu: flutter build apk (Android) / flutter build ios (iOS)
- Test komutu: flutter test
- Lint komutu: flutter analyze
- Run komutu: flutter run
- Localization generate: flutter gen-l10n

### Minimum SDK Gereksinimleri
- Android: minSdkVersion 26 (DEĞİŞTİRİLMEYECEK)
- iOS: deployment target 13.0 (NFC Manager v4 gereksinimi)

### Desteklenen Platformlar
- Android (ana platform)
- iOS (ana platform)
- Web (gelecekte)
- Desktop (gelecekte)

### Dil Desteği
- Ana dil: İngilizce (en)
- İkinci dil: Türkçe (tr)
- Her geliştirme hem İngilizce hem Türkçe için yapılacak

## Güvenlik Kuralları
- API anahtarları ve şifreler .env dosyasında saklanmalı
- .env dosyası .gitignore'da olmalı
- Hassas bilgiler loglara yazılmamalı

## Proje Özel Notları
- Business card (kartvizit) uygulaması için
- QR kod üretimi ve okuma işlemleri içerir
- NFC paylaşım özelliği içerir
- Metin tanıma (OCR) özelliği içerir
- Performans kritik olabilir
- Cross-platform compatibility (Android & iOS)
- Offline çalışabilir olmalı

## Dependency Listesi
- flutter_riverpod: State management
- sqflite: Local database
- qr_flutter: QR code generation
- google_mlkit_text_recognition: OCR/Text recognition
- nfc_manager: NFC functionality
- firebase_auth: Authentication
- google_sign_in: Google authentication
- googleapis: Google APIs
- shared_preferences: Local preferences storage
- flutter_localizations: Internationalization