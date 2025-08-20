import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:business_card_app/presentation/screens/main_screen.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';
import 'package:business_card_app/presentation/widgets/my_card_form.dart';
import 'package:business_card_app/presentation/widgets/qr_code_widget.dart';
import 'package:business_card_app/data/repositories/user_repository.dart';

/// My Card ekranı - kullanıcının kendi kartını yönetir
class MyCardScreen extends ConsumerStatefulWidget {
  const MyCardScreen({super.key});

  @override
  ConsumerState<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends ConsumerState<MyCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataState = ref.watch(userDataProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);

    return MainScreenWrapper(
      title: 'Kartım',
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.check : Icons.edit),
          onPressed: () {
            setState(() {
              _isEditing = !_isEditing;
            });
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'share':
                _shareCard();
                break;
              case 'nfc':
                _shareWithNFC();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Paylaş'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'nfc',
              child: Row(
                children: [
                  Icon(Icons.nfc),
                  SizedBox(width: 8),
                  Text('NFC Paylaş'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Bilgiler', icon: Icon(Icons.person)),
          Tab(text: 'QR Kod', icon: Icon(Icons.qr_code)),
        ],
      ),
      child: userDataState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  ref.invalidate(userDataProvider);
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (userData) => TabBarView(
          controller: _tabController,
          children: [
            // Bilgiler tab'ı
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profil kartı
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              userData.name.isNotEmpty 
                                  ? userData.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData.name.isEmpty ? 'Adınızı girin' : userData.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (userData.email.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              userData.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Premium durumu
                          premiumStatus.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (isPremium) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPremium ? Colors.amber : Colors.grey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isPremium ? 'Premium Üye' : 'Ücretsiz Üye',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Form
                  if (_isEditing)
                    MyCardForm(
                      initialData: userData,
                      onSave: (updatedData) {
                        ref.read(userDataProvider.notifier).updateUserData(updatedData);
                        setState(() {
                          _isEditing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bilgiler güncellendi')),
                        );
                      },
                      onCancel: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                    )
                  else
                    _buildInfoDisplay(userData),
                ],
              ),
            ),
            // QR Kod tab'ı
            _buildQRCodeTab(userData),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoDisplay(UserData userData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('İsim', userData.name),
            _buildInfoRow('E-posta', userData.email),
            _buildInfoRow('Telefon', userData.phone ?? 'Belirtilmemiş'),
            _buildInfoRow('Şirket', userData.company ?? 'Belirtilmemiş'),
            _buildInfoRow('Ünvan', userData.title ?? 'Belirtilmemiş'),
            _buildInfoRow('Web Sitesi', userData.website ?? 'Belirtilmemiş'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareCard,
                    icon: const Icon(Icons.share),
                    label: const Text('Kartı Paylaş'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareWithNFC,
                    icon: const Icon(Icons.nfc),
                    label: const Text('NFC'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'Belirtilmemiş' : value),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab(UserData userData) {
    final premiumStatus = ref.watch(premiumStatusProvider);
    
    return premiumStatus.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Hata: $error')),
      data: (isPremium) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isPremium) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ücretsiz sürümde 1 QR kod oluşturabilirsiniz. Premium sürümde sınırsız QR kod oluşturun.',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Premium upgrade ekranına git
                      },
                      child: const Text('Premium Al'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            QRCodeWidget(
              userData: userData,
              isPremium: isPremium,
            ),
          ],
        ),
      ),
    );
  }

  void _shareCard() {
    final userData = ref.read(userDataProvider).value;
    if (userData == null) return;

    final vCardData = _generateVCard(userData);
    Share.share(vCardData, subject: '${userData.name} - Kartvizit');
  }

  void _shareWithNFC() {
    // NFC paylaşım implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('NFC özelliği yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _generateVCard(UserData userData) {
    return '''BEGIN:VCARD
VERSION:3.0
FN:${userData.name}
ORG:${userData.company ?? ''}
TITLE:${userData.title ?? ''}
EMAIL:${userData.email}
TEL:${userData.phone ?? ''}
URL:${userData.website ?? ''}
END:VCARD''';
  }
}

