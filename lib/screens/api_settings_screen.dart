import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_settings_service.dart';
import '../utils/responsive_utils.dart';

/// Internet Archive API Settings Screen
///
/// Allows users to view and configure API-related settings, demonstrating:
/// - Transparency about API usage and rate limiting
/// - Good citizenship practices (reduced priority, rate limiting)
/// - Respect for Internet Archive's infrastructure
/// - Customization options for advanced users
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  static const String routeName = '/api-settings';

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  bool _isLoading = true;

  // Settings values
  bool _reducedPriority = false;
  bool _autoReduceLarge = true;
  int _largeSizeThresholdMB = 50;
  int _requestDelayMs = 100;
  int _maxRequestsPerMinute = 30;
  bool _sendDoNotTrack = true;
  bool _respectRetryAfter = true;
  String? _customUserAgent;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final values = await Future.wait([
      ApiSettingsService.getReducedPriority(),
      ApiSettingsService.getAutoReduceLargeFiles(),
      ApiSettingsService.getLargeSizeThresholdMB(),
      ApiSettingsService.getRequestDelayMs(),
      ApiSettingsService.getMaxRequestsPerMinute(),
      ApiSettingsService.getSendDoNotTrack(),
      ApiSettingsService.getRespectRetryAfter(),
      ApiSettingsService.getCustomUserAgent(),
    ]);

    if (mounted) {
      setState(() {
        _reducedPriority = values[0] as bool;
        _autoReduceLarge = values[1] as bool;
        _largeSizeThresholdMB = values[2] as int;
        _requestDelayMs = values[3] as int;
        _maxRequestsPerMinute = values[4] as int;
        _sendDoNotTrack = values[5] as bool;
        _respectRetryAfter = values[6] as bool;
        _customUserAgent = values[7] as String?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoBanner(context),
              const SizedBox(height: 24),
              // Only show Identification section on native platforms (not web)
              if (!kIsWeb) ...[
                _buildSectionHeader('Identification'),
                const SizedBox(height: 12),
                _buildIdentificationSettings(context),
                const SizedBox(height: 24),
              ],
              _buildSectionHeader('Download Priority'),
              const SizedBox(height: 12),
              _buildPrioritySettings(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Rate Limiting'),
              const SizedBox(height: 12),
              _buildRateLimitSettings(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Privacy & Compliance'),
              const SizedBox(height: 12),
              _buildPrivacySettings(context),
              const SizedBox(height: 24),
              _buildResetButton(context),
              const SizedBox(height: 16),
              _buildDocumentationLinks(context),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('API Settings')),
      body: ResponsiveUtils.isTabletOrLarger(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good API Citizenship',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These settings help us be respectful of Internet Archive\'s resources and follow their best practices.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationSettings(BuildContext context) {
    // Hide User-Agent settings on web since browsers don't allow custom User-Agent
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final defaultUserAgent = 'InternetArchiveHelper/1.6.0 (Flutter)';
    final displayUserAgent = _customUserAgent ?? defaultUserAgent;
    final isCustom = _customUserAgent != null && _customUserAgent!.isNotEmpty;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('User-Agent Header'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  displayUserAgent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  isCustom ? 'Custom' : 'Default',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUserAgentDialog(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User-Agent identifies your app to Internet Archive. Customize it to provide contact information or version details.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.low_priority),
            title: const Text('Use Reduced Priority'),
            subtitle: const Text('Mark all downloads as lower priority'),
            value: _reducedPriority,
            onChanged: (value) async {
              await ApiSettingsService.setReducedPriority(value);
              setState(() => _reducedPriority = value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.file_download),
            title: const Text('Auto-Reduce Large Files'),
            subtitle: Text(
              'Automatically use reduced priority for files > $_largeSizeThresholdMB MB',
            ),
            value: _autoReduceLarge,
            onChanged: (value) async {
              await ApiSettingsService.setAutoReduceLargeFiles(value);
              setState(() => _autoReduceLarge = value);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Large File Threshold'),
            subtitle: Text('$_largeSizeThresholdMB MB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdDialog(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The X-Accept-Reduced-Priority header helps avoid rate limiting and reduces strain on archive.org servers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Request Delay'),
            subtitle: Text('$_requestDelayMs ms between requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRequestDelayDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Max Requests Per Minute'),
            subtitle: Text(
              '$_maxRequestsPerMinute requests/min (recommended: 30)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMaxRequestsDialog(),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('Respect Retry-After'),
            subtitle: const Text('Honor server-requested retry delays'),
            value: _respectRetryAfter,
            onChanged: (value) async {
              await ApiSettingsService.setRespectRetryAfter(value);
              setState(() => _respectRetryAfter = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Archive.org recommends no more than 30 requests per minute. Lower settings show more respect for their infrastructure.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.privacy_tip),
            title: const Text('Send "Do Not Track"'),
            subtitle: const Text('Include DNT:1 header in requests'),
            value: _sendDoNotTrack,
            onChanged: (value) async {
              await ApiSettingsService.setSendDoNotTrack(value);
              setState(() => _sendDoNotTrack = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The DNT header signals that you prefer not to be tracked. This is sent by default as a privacy-respecting practice.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(
          Icons.restore,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          'Reset to Defaults',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Restore recommended Internet Archive settings'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showResetDialog,
      ),
    );
  }

  Widget _buildDocumentationLinks(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.book,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Learn More',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDocLink(
                  context,
                  'API Best Practices',
                  'archive.org/developers/',
                ),
                const SizedBox(height: 8),
                _buildDocLink(
                  context,
                  'Rate Limiting Guide',
                  'archive.org/services/docs/api/ratelimiting.html',
                ),
                const SizedBox(height: 8),
                _buildDocLink(
                  context,
                  'Custom Headers (Priority)',
                  'archive.org/developers/iarest.html#custom-headers',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocLink(BuildContext context, String title, String url) {
    return Row(
      children: [
        Icon(
          Icons.open_in_new,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showThresholdDialog() async {
    final mb = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Large File Threshold',
        label: 'Size in MB',
        initialValue: _largeSizeThresholdMB,
        minValue: 1,
        maxValue: 1000,
        step: 10,
      ),
    );

    if (mb != null && mounted) {
      await ApiSettingsService.setLargeSizeThresholdMB(mb);
      setState(() => _largeSizeThresholdMB = mb);
    }
  }

  Future<void> _showRequestDelayDialog() async {
    final ms = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Request Delay',
        label: 'Milliseconds between requests',
        initialValue: _requestDelayMs,
        minValue: 0,
        maxValue: 5000,
        step: 50,
      ),
    );

    if (ms != null && mounted) {
      await ApiSettingsService.setRequestDelayMs(ms);
      setState(() => _requestDelayMs = ms);
    }
  }

  Future<void> _showMaxRequestsDialog() async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) => _NumberPickerDialog(
        title: 'Max Requests Per Minute',
        label: 'Requests per minute (recommended: 30)',
        initialValue: _maxRequestsPerMinute,
        minValue: 1,
        maxValue: 100,
        step: 1,
      ),
    );

    if (count != null && mounted) {
      await ApiSettingsService.setMaxRequestsPerMinute(count);
      setState(() => _maxRequestsPerMinute = count);
    }
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will restore all API settings to Internet Archive\'s recommended values. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ApiSettingsService.resetToDefaults();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }

  Future<void> _showUserAgentDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          _UserAgentDialog(currentUserAgent: _customUserAgent),
    );

    if (result != null) {
      await ApiSettingsService.setCustomUserAgent(
        result.isEmpty ? null : result,
      );
      setState(() => _customUserAgent = result.isEmpty ? null : result);
    }
  }
}

/// Simple number picker dialog
class _NumberPickerDialog extends StatefulWidget {
  final String title;
  final String label;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final int step;

  const _NumberPickerDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
  });

  @override
  State<_NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<_NumberPickerDialog> {
  late TextEditingController _controller;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null &&
                  parsed >= widget.minValue &&
                  parsed <= widget.maxValue) {
                _value = parsed;
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_value > widget.minValue) {
                    setState(() {
                      _value -= widget.step;
                      _controller.text = _value.toString();
                    });
                  }
                },
              ),
              Expanded(
                child: Slider(
                  value: _value.toDouble(),
                  min: widget.minValue.toDouble(),
                  max: widget.maxValue.toDouble(),
                  divisions: ((widget.maxValue - widget.minValue) / widget.step)
                      .round(),
                  label: _value.toString(),
                  onChanged: (value) {
                    setState(() {
                      _value = (value / widget.step).round() * widget.step;
                      _controller.text = _value.toString();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_value < widget.maxValue) {
                    setState(() {
                      _value += widget.step;
                      _controller.text = _value.toString();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UserAgentDialog extends StatefulWidget {
  final String? currentUserAgent;

  const _UserAgentDialog({this.currentUserAgent});

  @override
  State<_UserAgentDialog> createState() => _UserAgentDialogState();
}

class _UserAgentDialogState extends State<_UserAgentDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUserAgent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom User-Agent'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize the User-Agent header sent to Internet Archive.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'User-Agent',
                hintText: 'InternetArchiveHelper/1.6.0 (Flutter)',
                helperText: 'Leave empty to use default',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended format:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AppName/Version (contact@email.com) Platform/Version',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentUserAgent != null &&
            widget.currentUserAgent!.isNotEmpty)
          TextButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context, '');
            },
            child: const Text('Reset to Default'),
          ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
