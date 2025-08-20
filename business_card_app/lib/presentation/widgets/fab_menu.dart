import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/presentation/screens/contact_edit_screen.dart';

/// FAB menu açık/kapalı durumu
final fabMenuOpenProvider = StateProvider<bool>((ref) => false);

/// Animasyonlu FAB Speed Dial Menu
class FabMenu extends ConsumerStatefulWidget {
  const FabMenu({super.key});

  @override
  ConsumerState<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends ConsumerState<FabMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 270 derece (3/4 tam tur)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(fabMenuOpenProvider);

    // Animation durumunu senkronize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isOpen && !_animationController.isCompleted) {
        _animationController.forward();
      } else if (!isOpen && !_animationController.isDismissed) {
        _animationController.reverse();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu items (animasyonlu)
        if (isOpen) ...(_buildMenuItems()),
        
        // Ana FAB butonu
        _buildMainFab(isOpen),
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    final menuItems = [
      _FabMenuItem(
        index: 0,
        icon: Icons.qr_code_scanner,
        label: 'QR Tara',
        color: Colors.blue,
        onPressed: () => _handleMenuAction('qr_scan'),
      ),
      _FabMenuItem(
        index: 1,
        icon: Icons.document_scanner,
        label: 'OCR Tara',
        color: Colors.green,
        onPressed: () => _handleMenuAction('ocr_scan'),
      ),
      _FabMenuItem(
        index: 2,
        icon: Icons.person_add,
        label: 'Manuel Ekle',
        color: Colors.orange,
        onPressed: () => _handleMenuAction('manual_add'),
      ),
    ];

    return menuItems.map((item) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _scaleAnimation.value,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: item,
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMainFab(bool isOpen) {
    return FloatingActionButton(
      onPressed: _toggleMenu,
      backgroundColor: Theme.of(context).primaryColor,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // radyan cinsinden
            child: Icon(
              isOpen ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  void _toggleMenu() {
    final isOpen = ref.read(fabMenuOpenProvider);
    ref.read(fabMenuOpenProvider.notifier).state = !isOpen;
  }

  void _closeMenu() {
    ref.read(fabMenuOpenProvider.notifier).state = false;
  }

  void _handleMenuAction(String action) {
    _closeMenu();
    
    switch (action) {
      case 'qr_scan':
        _startQRScan();
        break;
      case 'ocr_scan':
        _startOCRScan();
        break;
      case 'manual_add':
        _addContactManually();
        break;
    }
  }

  void _startQRScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod tarayıcı açılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: QR scanner implementasyonu
  }

  void _startOCRScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OCR tarayıcı açılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: OCR scanner implementasyonu
  }

  void _addContactManually() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactEditScreen(),
      ),
    );
  }
}

/// FAB menu item widget'ı
class _FabMenuItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FabMenuItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Button
          FloatingActionButton.small(
            onPressed: onPressed,
            backgroundColor: color,
            heroTag: 'fab_$index',
            elevation: 4,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
    );
  }
}

/// Alternatif minimal FAB menu implementasyonu
class MinimalFabMenu extends ConsumerWidget {
  const MinimalFabMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showBottomSheet(context),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showBottomSheet(BuildContext context) {
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Kişi Ekle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Options
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.qr_code_scanner, color: Colors.white),
                ),
                title: const Text('QR Kod Tara'),
                subtitle: const Text('QR kod okuyarak kişi bilgilerini al'),
                onTap: () {
                  Navigator.pop(context);
                  // QR scan action
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
                  // OCR scan action
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ContactEditScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}