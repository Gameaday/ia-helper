import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/snackbar_helper.dart';

/// Screen displaying app information, credits, and legal notices
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Could not open $urlString');
    }
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: 'IA Helper',
      applicationVersion: _version.isNotEmpty
          ? '$_version ($_buildNumber)'
          : 'Unknown',
      applicationIcon: Image.asset(
        'assets/icons/ic_launcher_1024.png',
        width: 80,
        height: 80,
      ),
      applicationLegalese:
          '© 2024 IA Helper\n\nThis app is not affiliated with or endorsed by the Internet Archive.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAppHeader(context),
          const SizedBox(height: 24),
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildCreditsCard(context),
          const SizedBox(height: 16),
          _buildLegalCard(context),
          const SizedBox(height: 16),
          _buildLinksCard(context),
          const SizedBox(height: 24),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/icons/ic_launcher_1024.png',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 16),
        Text(
          'IA Helper',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_version.isNotEmpty)
          Text(
            'Version $_version ($_buildNumber)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About This App',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'IA Helper is a mobile app for browsing, searching, and downloading content from the Internet Archive (archive.org).',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Features include:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...[
              'Advanced search with filters',
              'Download management with queue',
              'Offline access to downloaded content',
              'Favorites and collections',
              'Search history and saved searches',
              'Bandwidth throttling',
            ].map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Credits', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildCreditRow(context, 'Development', 'IA Helper Team'),
            const Divider(height: 24),
            _buildCreditRow(
              context,
              'Internet Archive API',
              'Internet Archive',
              onTap: () => _launchUrl('https://archive.org'),
            ),
            const Divider(height: 24),
            _buildCreditRow(
              context,
              'Built with',
              'Flutter & Dart',
              onTap: () => _launchUrl('https://flutter.dev'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.gavel_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Open Source Licenses'),
            subtitle: const Text('View third-party licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showLicensePage,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we handle your data'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _launchUrl(
              'https://github.com/gameaday/ia-helper/blob/main/PRIVACY_POLICY.md',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Terms of Service'),
            subtitle: const Text('Internet Archive terms'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _launchUrl('https://archive.org/about/terms.php'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.code_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _launchUrl('https://github.com/gameaday/ia-helper'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.bug_report_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Report Issues'),
            subtitle: const Text('Bug reports & feature requests'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () =>
                _launchUrl('https://github.com/gameaday/ia-helper/issues'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Contact & Support'),
            subtitle: const Text('Get help with the app'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () =>
                _launchUrl('https://github.com/gameaday/ia-helper/discussions'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'This app is not affiliated with or endorsed by the Internet Archive.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '© 2024 IA Helper',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
