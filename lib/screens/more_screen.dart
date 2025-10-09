import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/data_storage_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/about_screen.dart';
import '../screens/api_settings_screen.dart';
import '../screens/ia_health_screen.dart';
import '../utils/animation_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// More menu screen with organized access to settings and additional features
///
/// Provides clean, organized access to:
/// - Settings
/// - Help & About
/// - Data & Storage management
/// - Statistics
/// - Links and resources
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const String routeName = '/more';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            // App logo and title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Internet Archive Helper',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.6.0',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),

            // Settings section
            _buildSectionHeader(context, 'Configuration'),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences and configuration',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const SettingsScreen(),
                    settings: const RouteSettings(name: '/settings'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.api,
              title: 'API Settings',
              subtitle: 'Internet Archive API configuration',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const ApiSettingsScreen(),
                    settings: const RouteSettings(name: '/api-settings'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Information section
            _buildSectionHeader(context, 'Information'),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'User guide and tutorials',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const HelpScreen(),
                    settings: const RouteSettings(name: '/help'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App info, credits, and licenses',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const AboutScreen(),
                    settings: const RouteSettings(name: '/about'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.storage,
              title: 'Data & Storage',
              subtitle: 'Manage cache and local data',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const DataStorageScreen(),
                    settings: const RouteSettings(name: '/data-storage'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.bar_chart,
              title: 'Statistics',
              subtitle: 'Download and usage statistics',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const StatisticsScreen(),
                    settings: const RouteSettings(name: '/statistics'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.health_and_safety,
              title: 'IA Service Status',
              subtitle: 'Internet Archive health monitoring',
              onTap: () {
                Navigator.of(context).push(
                  MD3PageTransitions.sharedAxis(
                    page: const IAHealthScreen(),
                    settings: const RouteSettings(name: '/ia-health'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Resources section
            _buildSectionHeader(context, 'Resources'),
            _buildMenuItem(
              context,
              icon: Icons.public,
              title: 'Visit Internet Archive',
              subtitle: 'archive.org',
              onTap: () async {
                final uri = Uri.parse('https://archive.org');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.code,
              title: 'GitHub Repository',
              subtitle: 'Source code and issues',
              onTap: () async {
                final uri = Uri.parse('https://github.com/Gameaday/ia-helper');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.policy,
              title: 'Privacy Policy',
              subtitle: 'Data collection and usage',
              onTap: () async {
                final uri = Uri.parse(
                  'https://github.com/Gameaday/ia-helper/blob/main/PRIVACY_POLICY.md',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Made with ❤️ for the Internet Archive',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© 2025 Internet Archive Helper',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
