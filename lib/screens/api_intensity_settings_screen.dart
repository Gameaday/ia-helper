import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_intensity_settings.dart';
import '../utils/snackbar_helper.dart';

/// Screen for configuring API intensity and data usage settings
class ApiIntensitySettingsScreen extends StatefulWidget {
  const ApiIntensitySettingsScreen({super.key});

  static const String routeName = '/api-intensity-settings';

  @override
  State<ApiIntensitySettingsScreen> createState() =>
      _ApiIntensitySettingsScreenState();

  /// Get current API intensity settings
  static Future<ApiIntensitySettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('api_intensity_settings');
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ApiIntensitySettings.fromJson(json);
      } catch (e) {
        // If parsing fails, return default
        return ApiIntensitySettings.standard();
      }
    }
    return ApiIntensitySettings.standard();
  }

  /// Save API intensity settings
  static Future<void> saveSettings(ApiIntensitySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'api_intensity_settings',
      jsonEncode(settings.toJson()),
    );
  }
}

class _ApiIntensitySettingsScreenState
    extends State<ApiIntensitySettingsScreen> {
  late ApiIntensitySettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ApiIntensitySettingsScreen.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await ApiIntensitySettingsScreen.saveSettings(_settings);
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Settings saved');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('API Intensity')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('API Intensity')),
      body: ListView(
        children: [
          // Introduction Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Control Data Usage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how much data to fetch from the Internet Archive. '
                    'Lower intensity means faster loading and less data usage, '
                    'but fewer features.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Intensity Level Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'API Intensity Level',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Level options with RadioGroup
          RadioGroup<ApiIntensityLevel>(
            groupValue: _settings.level,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = ApiIntensitySettings.fromLevel(value);
                });
                _saveSettings();
              }
            },
            child: Column(
              children: [
                _buildLevelOption(
                  ApiIntensityLevel.full,
                  ApiIntensitySettings.full(),
                  Icons.flash_on,
                  Colors.orange,
                ),
                _buildLevelOption(
                  ApiIntensityLevel.standard,
                  ApiIntensitySettings.standard(),
                  Icons.flash_auto,
                  Colors.blue,
                ),
                _buildLevelOption(
                  ApiIntensityLevel.minimal,
                  ApiIntensitySettings.minimal(),
                  Icons.flash_off,
                  Colors.green,
                ),
                _buildLevelOption(
                  ApiIntensityLevel.cacheOnly,
                  ApiIntensitySettings.cacheOnly(),
                  Icons.cloud_off,
                  Colors.grey,
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // Advanced Options (if not cache-only)
          if (_settings.level != ApiIntensityLevel.cacheOnly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Advanced Options',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SwitchListTile(
              secondary: const Icon(Icons.image),
              title: const Text('Load Thumbnails'),
              subtitle: const Text('Show cover images in search results'),
              value: _settings.loadThumbnails,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(loadThumbnails: value);
                });
                _saveSettings();
              },
            ),

            SwitchListTile(
              secondary: const Icon(Icons.cloud_download),
              title: const Text('Preload Metadata'),
              subtitle: const Text('Cache popular items for instant access'),
              value: _settings.preloadMetadata,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(preloadMetadata: value);
                });
                _saveSettings();
              },
            ),

            SwitchListTile(
              secondary: const Icon(Icons.description),
              title: const Text('Extended Metadata'),
              subtitle: const Text('Load full descriptions and details'),
              value: _settings.loadExtendedMetadata,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(loadExtendedMetadata: value);
                });
                _saveSettings();
              },
            ),

            SwitchListTile(
              secondary: const Icon(Icons.analytics),
              title: const Text('Statistics'),
              subtitle: const Text('Load download counts and ratings'),
              value: _settings.loadStatistics,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(loadStatistics: value);
                });
                _saveSettings();
              },
            ),

            SwitchListTile(
              secondary: const Icon(Icons.explore),
              title: const Text('Related Items'),
              subtitle: const Text('Show similar archives'),
              value: _settings.loadRelatedItems,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(loadRelatedItems: value);
                });
                _saveSettings();
              },
            ),

            const Divider(height: 32),
          ],

          // Estimated Usage Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.data_usage,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimated Usage',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '~${_settings.estimatedDataUsagePerItem} KB per item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _settings.estimateDataUsage(50),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated for 50 search results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Help Text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Changes take effect immediately. Your current settings will be used for all new searches and downloads.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(
    ApiIntensityLevel level,
    ApiIntensitySettings preset,
    IconData icon,
    Color color,
  ) {
    final isSelected = _settings.level == level;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: RadioListTile<ApiIntensityLevel>(
        value: level,
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : color,
            ),
            const SizedBox(width: 8),
            Text(
              preset.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              preset.description,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.data_usage,
                  size: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '~${preset.estimatedDataUsagePerItem} KB/item',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        secondary: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
    );
  }
}
