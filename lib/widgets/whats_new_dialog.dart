import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/semantic_colors.dart';

/// Dialog showing new features in the current app version
/// Shown once per version update to help users discover new functionality
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  /// Version for which this What's New content is shown
  static const String targetVersion = '1.9.0';

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
          const Text("What's New in v1.9"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "A big reliability and management update - here's what's new:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            _buildFeatureItem(
              context,
              icon: Icons.download_done_outlined,
              iconColor: SemanticColors.success,
              title: 'Resumable Downloads',
              description:
                  'Downloads pick up where they left off and survive app restarts',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.wifi_off_outlined,
              iconColor: SemanticColors.info,
              title: 'Connection-Aware',
              description:
                  'Transfers pause when you go offline and resume automatically',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.hub_outlined,
              iconColor: SemanticColors.warning,
              title: 'Torrent Handoff',
              description:
                  'Share an item\'s official torrent to your torrent app for seeding',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.sync_outlined,
              iconColor: SemanticColors.primary(context),
              title: 'Library Sync',
              description:
                  'Verify downloaded items against Archive.org and repair changes',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.manage_accounts_outlined,
              iconColor: SemanticColors.info,
              title: 'Manage Your Items',
              description:
                  'Add your Archive.org S3 keys to browse and edit your own uploads',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.tablet_outlined,
              iconColor: SemanticColors.success,
              title: 'Tablet Layout',
              description:
                  'Adaptive navigation and grids that feel at home on big screens',
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
                      'Check Settings for bandwidth limits, cache controls, and your account',
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
