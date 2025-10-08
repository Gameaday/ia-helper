import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/semantic_colors.dart';

/// Dialog showing new features in the current app version
/// Shown once per version update to help users discover new functionality
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  /// Version for which this What's New content is shown
  static const String targetVersion = '1.6.0';

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
          const Text('What\'s New in v1.6'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ve been busy improving your experience!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            _buildFeatureItem(
              context,
              icon: Icons.speed,
              iconColor: SemanticColors.info,
              title: 'Real-Time Progress',
              description:
                  'Watch your downloads with live speed and time remaining',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.folder_open,
              iconColor: SemanticColors.success,
              title: 'Open Downloaded Files',
              description: 'Tap files to open them instantly from the app',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.link,
              iconColor: SemanticColors.primary(context),
              title: 'Deep Links',
              description:
                  'Click archive.org links anywhere - they open in the app!',
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.tune,
              iconColor: SemanticColors.warning,
              title: 'Bandwidth Controls',
              description: 'Limit download speed in Settings to save data',
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
                      'Explore Settings for more customization options',
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
