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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use grid layout for tablets and desktops
            final useGridLayout = constraints.maxWidth >= 600;

            if (useGridLayout) {
              return _buildGridLayout(context, colorScheme, textTheme);
            } else {
              return _buildListLayout(context, colorScheme, textTheme);
            }
          },
        ),
      ),
    );
  }

  Widget _buildListLayout(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ListView(
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

        // Configuration section
        _buildSectionHeader(context, 'Configuration'),
        _buildMenuItem(
          context,
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'Downloads, bandwidth, and preferences',
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

        // Data & Monitoring section
        _buildSectionHeader(context, 'Data & Monitoring'),
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
          title: 'Service Status',
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

        // Help & About section
        _buildSectionHeader(context, 'Help & About'),
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

        const SizedBox(height: 16),

        // External Resources section
        _buildSectionHeader(context, 'External Resources'),
        _buildMenuItem(
          context,
          icon: Icons.public,
          title: 'Internet Archive',
          subtitle: 'Visit archive.org',
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
          title: 'GitHub',
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
    );
  }

  Widget _buildGridLayout(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Determine columns based on width
    int columns = 2; // Tablet: 2 columns
    if (MediaQuery.of(context).size.width >= 900) {
      columns = 3; // Desktop: 3 columns
    }

    final menuItems = _getAllMenuItems(context);

    return CustomScrollView(
      slivers: [
        // Header with logo
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
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
          ),
        ),

        // Grid of menu items
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = menuItems[index];
                return _MenuItemCard(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                );
              },
              childCount: menuItems.length,
            ),
          ),
        ),

        // Footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              children: [
                Text(
                  'Made with ❤️ for the Internet Archive',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2025 Internet Archive Helper',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_MenuItem> _getAllMenuItems(BuildContext context) {
    return [
      // === Configuration Section ===
      _MenuItem(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'Downloads, bandwidth, and preferences',
        onTap: () {
          Navigator.of(context).push(
            MD3PageTransitions.sharedAxis(
              page: const SettingsScreen(),
              settings: const RouteSettings(name: '/settings'),
            ),
          );
        },
      ),
      _MenuItem(
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

      // === Data & Monitoring Section ===
      _MenuItem(
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
      _MenuItem(
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
      _MenuItem(
        icon: Icons.health_and_safety,
        title: 'Service Status',
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

      // === Help & About Section ===
      _MenuItem(
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
      _MenuItem(
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

      // === External Resources Section ===
      _MenuItem(
        icon: Icons.public,
        title: 'Internet Archive',
        subtitle: 'Visit archive.org',
        onTap: () async {
          final uri = Uri.parse('https://archive.org');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
      _MenuItem(
        icon: Icons.code,
        title: 'GitHub',
        subtitle: 'Source code and issues',
        onTap: () async {
          final uri = Uri.parse('https://github.com/Gameaday/ia-helper');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
      _MenuItem(
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
    ];
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

/// Menu item data class
class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Menu item card widget for grid layout
class _MenuItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
