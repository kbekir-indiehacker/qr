import 'package:flutter/material.dart';
import 'package:business_card_app/data/models/contact.dart';

/// Single contact item widget for list display
class ContactListItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onToggleStarred;
  final VoidCallback? onLongPress;

  const ContactListItem({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onToggleStarred,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(),
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Company and title
                    if (contact.company != null || contact.title != null)
                      Text(
                        _buildSubtitle(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Contact methods
                    Row(
                      children: [
                        if (contact.hasEmail) ...[
                          Icon(
                            Icons.email,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (contact.hasPhoneNumber) ...[
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (contact.website != null) ...[
                          Icon(
                            Icons.language,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Tags
                        if (contact.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              children: contact.tags.take(2).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star button
                  InkWell(
                    onTap: onToggleStarred,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        contact.isStarred ? Icons.star : Icons.star_border,
                        color: contact.isStarred ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  // Quick action based on available contact methods
                  _buildQuickActionButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    
    if (contact.title != null) {
      parts.add(contact.title!);
    }
    
    if (contact.company != null) {
      parts.add(contact.company!);
    }
    
    return parts.join(' • ');
  }

  Color _getAvatarColor() {
    // Generate consistent color based on name
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

  Widget _buildQuickActionButton(BuildContext context) {
    // Priority: Phone > Email > Website
    if (contact.hasPhoneNumber) {
      return InkWell(
        onTap: () => _callContact(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.phone,
            size: 16,
            color: Colors.green[600],
          ),
        ),
      );
    } else if (contact.hasEmail) {
      return InkWell(
        onTap: () => _emailContact(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.email,
            size: 16,
            color: Colors.blue[600],
          ),
        ),
      );
    } else if (contact.website != null) {
      return InkWell(
        onTap: () => _visitWebsite(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.language,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return const SizedBox(width: 28, height: 28);
  }

  void _callContact(BuildContext context) {
    // Implement phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.phone} aranıyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _emailContact(BuildContext context) {
    // Implement email
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.email} adresine e-posta gönderiliyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _visitWebsite(BuildContext context) {
    // Implement website visit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.website} açılıyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}