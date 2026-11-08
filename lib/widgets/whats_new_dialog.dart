import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/semantic_colors.dart';

/// Dialog showing new features in the current app version
/// Shown once per version update to help users discover new functionality
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  /// Version for which this What's New content is shown
  static const String targetVersion = '2.0.0';

  /// SharedPreferences key for tracking last shown version
  static const String _prefKey = 'whats_new_last_shown_version';

  /// Check if What's New should be shown for the current version
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownVersion = prefs.getString(_prefKey);
    return lastShownVersion != targetVersion;
  }

  /// Mark What's New as shown for the current version
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, targetVersion);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.celebration,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text("What's New in v2.0"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your downloads, your rules - here's what's new:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            _buildFeatureItem(
              context,
              icon: Icons.folder_outlined,
              iconColor: SemanticColors.success,
              title: 'Choose Any Folder',
              description:
                  'Pick exactly where downloads go with Android\'s file picker, including subfolders',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.bookmark_add_outlined,
              iconColor: SemanticColors.info,
              title: 'Saved Searches & Watchlist',
              description:
                  'Save searches for later and watch items to catch new files as they land',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.ios_share_outlined,
              iconColor: SemanticColors.warning,
              title: 'Export Your Data',
              description:
                  'Export saved searches and your watchlist to JSON for backups',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.notifications_active_outlined,
              iconColor: SemanticColors.primary(context),
              title: 'Download Notifications',
              description:
                  'See progress at a glance with pause, resume, and cancel actions',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.restart_alt_outlined,
              iconColor: SemanticColors.info,
              title: 'More Reliable Transfers',
              description:
                  'The download queue survives restarts and reacts to connection changes',
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Watchlist lives in the Library tab - check it to stay on top of new uploads',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await markAsShown();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
