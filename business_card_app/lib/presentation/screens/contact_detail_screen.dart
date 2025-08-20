import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_card_app/data/models/contact.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';
import 'package:business_card_app/presentation/screens/contact_edit_screen.dart';

/// Provider for selected contact detail
final contactDetailProvider = FutureProvider.family<Contact?, int>((ref, contactId) async {
  return await ref.read(contactsProvider.notifier).getContactById(contactId);
});

/// Contact detail screen with view and edit modes
class ContactDetailScreen extends ConsumerWidget {
  final int contactId;

  const ContactDetailScreen({
    super.key,
    required this.contactId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactDetailProvider(contactId));

    return contactAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Kişi Detayı'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Hata'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Kişi bulunamadı: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      ),
      data: (contact) {
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kişi Bulunamadı'),
            ),
            body: const Center(
              child: Text('Bu kişi artık mevcut değil'),
            ),
          );
        }

        return _ContactDetailView(contact: contact, ref: ref);
      },
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  final Contact contact;
  final WidgetRef ref;

  const _ContactDetailView({
    required this.contact,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            icon: Icon(
              contact.isStarred ? Icons.star : Icons.star_border,
              color: contact.isStarred ? Colors.amber : null,
            ),
            onPressed: () => _toggleStarred(),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editContact(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
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
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Kopyala'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with avatar and basic info
            _buildHeader(context),
            // Quick actions
            _buildQuickActions(context),
            // Contact information
            _buildContactInfo(context),
            // Tags
            if (contact.tags.isNotEmpty) _buildTags(context),
            // Notes
            if (contact.notes?.isNotEmpty == true) _buildNotes(context),
            // Metadata
            _buildMetadata(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Hero(
              tag: 'contact_avatar_${contact.id}',
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _getAvatarColor(),
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              contact.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Title and company
            if (contact.title != null || contact.company != null)
              Text(
                _buildSubtitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];

    // Call action
    if (contact.hasPhoneNumber) {
      actions.add(
        _QuickActionButton(
          icon: Icons.phone,
          label: 'Ara',
          color: Colors.green,
          onPressed: () => _makePhoneCall(contact.phone!),
        ),
      );
    }

    // WhatsApp action
    if (contact.hasPhoneNumber) {
      actions.add(
        _QuickActionButton(
          icon: Icons.message,
          label: 'WhatsApp',
          color: Colors.green[700]!,
          onPressed: () => _openWhatsApp(contact.phone!),
        ),
      );
    }

    // Email action
    if (contact.hasEmail) {
      actions.add(
        _QuickActionButton(
          icon: Icons.email,
          label: 'E-posta',
          color: Colors.blue,
          onPressed: () => _sendEmail(contact.email!),
        ),
      );
    }

    // Website action
    if (contact.website != null) {
      actions.add(
        _QuickActionButton(
          icon: Icons.language,
          label: 'Web',
          color: Colors.orange,
          onPressed: () => _openWebsite(contact.website!),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final infoItems = <Widget>[];

    // Phone
    if (contact.phone != null) {
      infoItems.add(
        _ContactInfoItem(
          icon: Icons.phone,
          label: 'Telefon',
          value: contact.phone!,
          onTap: () => _makePhoneCall(contact.phone!),
          onLongPress: () => _copyToClipboard(context, contact.phone!, 'Telefon numarası'),
        ),
      );
    }

    // Email
    if (contact.email != null) {
      infoItems.add(
        _ContactInfoItem(
          icon: Icons.email,
          label: 'E-posta',
          value: contact.email!,
          onTap: () => _sendEmail(contact.email!),
          onLongPress: () => _copyToClipboard(context, contact.email!, 'E-posta adresi'),
        ),
      );
    }

    // Company
    if (contact.company != null) {
      infoItems.add(
        _ContactInfoItem(
          icon: Icons.business,
          label: 'Şirket',
          value: contact.company!,
          onLongPress: () => _copyToClipboard(context, contact.company!, 'Şirket adı'),
        ),
      );
    }

    // Title
    if (contact.title != null) {
      infoItems.add(
        _ContactInfoItem(
          icon: Icons.work,
          label: 'Ünvan',
          value: contact.title!,
          onLongPress: () => _copyToClipboard(context, contact.title!, 'Ünvan'),
        ),
      );
    }

    // Website
    if (contact.website != null) {
      infoItems.add(
        _ContactInfoItem(
          icon: Icons.language,
          label: 'Web Sitesi',
          value: contact.website!,
          onTap: () => _openWebsite(contact.website!),
          onLongPress: () => _copyToClipboard(context, contact.website!, 'Web sitesi'),
        ),
      );
    }

    // Social media
    if (contact.socialMedia?.isNotEmpty == true) {
      contact.socialMedia!.forEach((platform, handle) {
        infoItems.add(
          _ContactInfoItem(
            icon: _getSocialMediaIcon(platform),
            label: _getSocialMediaLabel(platform),
            value: handle,
            onTap: () => _openSocialMedia(platform, handle),
            onLongPress: () => _copyToClipboard(context, handle, platform),
          ),
        );
      });
    }

    if (infoItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'İletişim Bilgileri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...infoItems,
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Etiketler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contact.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notlar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              contact.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilgiler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetadataRow('Oluşturulma', _formatDate(contact.createdAt)),
            if (contact.updatedAt != null)
              _buildMetadataRow('Güncelleme', _formatDate(contact.updatedAt!)),
            if (contact.cardImagePath != null)
              _buildMetadataRow('Kartvizit resmi', 'Mevcut'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getAvatarColor() {
    final nameHash = contact.name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[nameHash.abs() % colors.length];
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (contact.title != null) parts.add(contact.title!);
    if (contact.company != null) parts.add(contact.company!);
    return parts.join(' • ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  IconData _getSocialMediaIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.link;
    }
  }

  String _getSocialMediaLabel(String platform) {
    return platform[0].toUpperCase() + platform.substring(1);
  }

  // Action methods
  void _toggleStarred() {
    ref.read(contactsProvider.notifier).toggleStarred(contact.id!);
  }

  void _editContact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactEditScreen(contact: contact),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share':
        _shareContact();
        break;
      case 'duplicate':
        _duplicateContact();
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _shareContact() {
    // TODO: Implement contact sharing
  }

  void _duplicateContact() {
    // TODO: Implement contact duplication
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kişiyi Sil'),
        content: Text('${contact.name} kişisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteContact(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _deleteContact(BuildContext context) async {
    await ref.read(contactsProvider.notifier).deleteContact(contact.id!);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} silindi')),
      );
    }
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite(String website) async {
    final uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openSocialMedia(String platform, String handle) async {
    String url;
    switch (platform.toLowerCase()) {
      case 'linkedin':
        url = 'https://linkedin.com/in/$handle';
        break;
      case 'twitter':
      case 'x':
        url = 'https://twitter.com/$handle';
        break;
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'facebook':
        url = 'https://facebook.com/$handle';
        break;
      default:
        url = handle;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label panoya kopyalandı')),
    );
  }
}

// Helper widgets
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          heroTag: label,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _ContactInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ContactInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}