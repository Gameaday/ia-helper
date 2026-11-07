import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ia_credentials_service.dart';
import '../services/own_items_service.dart';
import '../utils/snackbar_helper.dart';
import '../utils/responsive_utils.dart';
import 'own_items_screen.dart';

/// Manage the archive.org S3 keys used for own-item management (#95).
///
/// Keys live in device secure storage, are validated against IA with a
/// real S3 call before being kept, and are never displayed back in full.
class IAAccountScreen extends StatefulWidget {
  const IAAccountScreen({super.key});

  static const String routeName = '/ia-account';

  @override
  State<IAAccountScreen> createState() => _IAAccountScreenState();
}

class _IAAccountScreenState extends State<IAAccountScreen> {
  static const _keysUrl = 'https://archive.org/account/settings.php';

  final _formKey = GlobalKey<FormState>();
  final _accessController = TextEditingController();
  final _secretController = TextEditingController();
  final _credentials = IACredentialsService();

  bool _loading = true;
  bool _saving = false;
  bool _obscureSecret = true;
  IAS3Keys? _keys;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _accessController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final keys = await _credentials.getKeys();
    if (!mounted) return;
    setState(() {
      _keys = keys;
      _loading = false;
    });
  }

  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final keys = IAS3Keys(
      accessKey: _accessController.text.trim(),
      secretKey: _secretController.text.trim(),
    );
    // Save first, then validate with a real S3 call. Rejected keys are
    // removed again so bad credentials never linger in secure storage.
    await _credentials.saveKeys(keys);
    final service = OwnItemsService(credentials: _credentials);
    String? rejection;
    int? itemCount;
    try {
      final items = await service.listOwnItems();
      itemCount = items.length;
    } on IAS3AuthException catch (e) {
      rejection = e.message;
      await _credentials.clearKeys();
    } catch (_) {
      // Network hiccup during validation: the keys may still be valid,
      // so keep them and let the user retry from My Items.
    } finally {
      service.dispose();
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (rejection != null) {
      SnackBarHelper.showError(context, rejection);
      return;
    }
    setState(() => _keys = keys);
    _accessController.clear();
    _secretController.clear();
    if (itemCount != null) {
      SnackBarHelper.showSuccess(
        context,
        'Keys verified - you can manage $itemCount item(s)',
      );
    } else {
      SnackBarHelper.showInfo(
        context,
        'Keys saved, but verification could not finish. Try My Items.',
      );
    }
  }

  Future<void> _removeKeys() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove S3 keys?'),
        content: const Text(
          'The keys will be deleted from this device. Your archive.org '
          'account is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _credentials.clearKeys();
    if (!mounted) return;
    setState(() => _keys = null);
    SnackBarHelper.showSuccess(context, 'S3 keys removed from this device');
  }

  Future<void> _openKeysPage() async {
    final uri = Uri.parse(_keysUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      SnackBarHelper.showWarning(context, 'Could not open browser');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = _loading
        ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(
                Icons.manage_accounts_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'My Archive.org Account',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Connect your S3 keys to manage items you have uploaded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_keys != null) _buildConfigured(theme, colorScheme)
              else _buildForm(theme, colorScheme),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('My Archive.org Account')),
      body: ResponsiveUtils.isTabletOrLarger(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildConfigured(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('S3 keys configured', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Access key: ${_keys!.masked}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Keys are stored in this device\'s secure storage and sent only '
              'to archive.org over HTTPS.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, OwnItemsScreen.routeName),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('My Items'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _removeKeys,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove Keys'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create S3 API keys at archive.org under account settings, then '
            'paste them here. They allow listing your items and editing '
            'their metadata.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openKeysPage,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open archive.org account settings'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accessController,
            decoration: const InputDecoration(
              labelText: 'S3 Access Key',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter the access key';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _secretController,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              labelText: 'S3 Secret Key',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecret
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscureSecret ? 'Show secret' : 'Hide secret',
                onPressed: () => setState(
                  () => _obscureSecret = !_obscureSecret,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter the secret key';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'The secret is stored encrypted on this device and never shown '
            'again after saving.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveKeys,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Verifying…' : 'Save and Verify'),
            ),
          ),
        ],
      ),
    );
  }
}
