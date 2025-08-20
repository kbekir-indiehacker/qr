import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/presentation/screens/my_card_screen.dart';
import 'package:business_card_app/presentation/screens/contacts_list_screen.dart';
import 'package:business_card_app/presentation/screens/settings_screen.dart';

/// Ana ekran provider'ı - seçili tab index'ini tutar
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Uygulama ana ekranı - Bottom Navigation ile tab yönetimi
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);
    
    // Tab ekranları
    const screens = [
      MyCardScreen(),
      ContactsListScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person),
            label: 'Kartım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            activeIcon: Icon(Icons.contacts),
            label: 'Kişiler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 8,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kişi Ekle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.qr_code_scanner, color: Colors.white),
                      ),
                      title: const Text('QR Kod Tara'),
                      subtitle: const Text('QR kod okuyarak kişi bilgilerini al'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR kod tarayıcı açılıyor...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.document_scanner, color: Colors.white),
                      ),
                      title: const Text('Kartvizit Tara'),
                      subtitle: const Text('Kartvizit fotoğrafından bilgileri çıkar'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OCR tarayıcı açılıyor...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.person_add, color: Colors.white),
                      ),
                      title: const Text('Manuel Ekle'),
                      subtitle: const Text('Kişi bilgilerini elle gir'),
                      onTap: () {
                        Navigator.pop(context);
                        // Manual add functionality will be added later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manuel ekleme açılıyor...')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Ana ekran wrapper - genel app bar yapısı
class MainScreenWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const MainScreenWrapper({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
        leading: leading,
        bottom: bottom,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 2,
      ),
      body: child,
    );
  }
}