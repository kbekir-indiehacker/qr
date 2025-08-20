import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:business_card_app/data/repositories/user_repository.dart';

/// QR kod gösterimi ve yönetimi için widget
class QRCodeWidget extends StatefulWidget {
  final UserData userData;
  final bool isPremium;

  const QRCodeWidget({
    super.key,
    required this.userData,
    required this.isPremium,
  });

  @override
  State<QRCodeWidget> createState() => _QRCodeWidgetState();
}

class _QRCodeWidgetState extends State<QRCodeWidget> {
  String _selectedFormat = 'vcard';
  final List<String> _qrFormats = ['vcard', 'json', 'url'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Format seçimi (Premium için)
        if (widget.isPremium) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Kod Formatı',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _qrFormats.map((format) {
                      return ChoiceChip(
                        label: Text(_getFormatLabel(format)),
                        selected: _selectedFormat == format,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFormat = format;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // QR Kod gösterimi
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: _generateQRData(),
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    embeddedImage: const AssetImage('assets/images/logo.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(40, 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getFormatDescription(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // QR kod aksiyonları
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _shareQRCode,
                      icon: const Icon(Icons.share),
                      label: const Text('Paylaş'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copyQRData,
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopyala'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saveQRCode,
                      icon: const Icon(Icons.download),
                      label: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // QR kod veri önizlemesi
        Card(
          child: ExpansionTile(
            title: const Text('QR Kod Verisi'),
            leading: const Icon(Icons.code),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _generateQRData(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // QR kod ipuçları
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'QR Kod İpuçları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• QR kodunuzu taradığınızda iletişim bilgileriniz otomatik olarak eklenir'),
                const Text('• Karanlık mod kullanırken QR kodu daha iyi taranır'),
                const Text('• QR kodunuzu yazdırarak kartvizitinizde kullanabilirsiniz'),
                if (widget.isPremium)
                  const Text('• Premium üye olarak farklı formatlar arasından seçim yapabilirsiniz'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _generateQRData() {
    switch (_selectedFormat) {
      case 'vcard':
        return _generateVCard();
      case 'json':
        return _generateJSON();
      case 'url':
        return _generateURL();
      default:
        return _generateVCard();
    }
  }

  String _generateVCard() {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:${widget.userData.name}');
    buffer.writeln('N:${widget.userData.name};;;');
    
    if (widget.userData.company?.isNotEmpty == true) {
      buffer.writeln('ORG:${widget.userData.company}');
    }
    
    if (widget.userData.title?.isNotEmpty == true) {
      buffer.writeln('TITLE:${widget.userData.title}');
    }
    
    if (widget.userData.email.isNotEmpty) {
      buffer.writeln('EMAIL:${widget.userData.email}');
    }
    
    if (widget.userData.phone?.isNotEmpty == true) {
      buffer.writeln('TEL:${widget.userData.phone}');
    }
    
    if (widget.userData.website?.isNotEmpty == true) {
      buffer.writeln('URL:${widget.userData.website}');
    }
    
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  String _generateJSON() {
    final data = {
      'name': widget.userData.name,
      'email': widget.userData.email,
      'phone': widget.userData.phone,
      'company': widget.userData.company,
      'title': widget.userData.title,
      'website': widget.userData.website,
      'type': 'business_card',
      'version': '1.0',
    };
    
    // Remove null values
    data.removeWhere((key, value) => value == null || value == '');
    
    return data.toString();
  }

  String _generateURL() {
    final params = <String>[];
    params.add('name=${Uri.encodeComponent(widget.userData.name)}');
    params.add('email=${Uri.encodeComponent(widget.userData.email)}');
    
    if (widget.userData.phone?.isNotEmpty == true) {
      params.add('phone=${Uri.encodeComponent(widget.userData.phone!)}');
    }
    if (widget.userData.company?.isNotEmpty == true) {
      params.add('company=${Uri.encodeComponent(widget.userData.company!)}');
    }
    if (widget.userData.title?.isNotEmpty == true) {
      params.add('title=${Uri.encodeComponent(widget.userData.title!)}');
    }
    if (widget.userData.website?.isNotEmpty == true) {
      params.add('website=${Uri.encodeComponent(widget.userData.website!)}');
    }
    
    return 'https://businesscard.app/contact?${params.join('&')}';
  }

  String _getFormatLabel(String format) {
    switch (format) {
      case 'vcard':
        return 'vCard';
      case 'json':
        return 'JSON';
      case 'url':
        return 'URL';
      default:
        return format.toUpperCase();
    }
  }

  String _getFormatDescription() {
    switch (_selectedFormat) {
      case 'vcard':
        return 'Standart vCard formatı - çoğu cihaz tarafından desteklenir';
      case 'json':
        return 'JSON formatı - geliştiriciler için uygundur';
      case 'url':
        return 'Web URL formatı - tarayıcıda açılır';
      default:
        return '';
    }
  }

  void _shareQRCode() {
    final qrData = _generateQRData();
    Share.share(
      qrData,
      subject: '${widget.userData.name} - QR Kod',
    );
  }

  void _copyQRData() {
    final qrData = _generateQRData();
    Clipboard.setData(ClipboardData(text: qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod verisi panoya kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveQRCode() {
    // QR kod resmi kaydetme implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod kaydetme özelliği yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}