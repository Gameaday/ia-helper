import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_archive_helper/services/metadata_export_service.dart';
import 'package:internet_archive_helper/utils/snackbar_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export-metadata bottom sheet (#91): pick scopes and a format, then
/// share the generated file. Everything happens on-device; the file goes
/// only where the user sends it.
class MetadataExportSheet extends StatefulWidget {
  const MetadataExportSheet({super.key});

  @override
  State<MetadataExportSheet> createState() => _MetadataExportSheetState();
}

class _MetadataExportSheetState extends State<MetadataExportSheet> {
  final _service = MetadataExportService();
  final Set<ExportScope> _scopes = {ExportScope.downloads};
  ExportFormat _format = ExportFormat.json;
  bool _isExporting = false;

  static const _scopeLabels = {
    ExportScope.downloads: 'Downloads',
    ExportScope.favorites: 'Favorites',
    ExportScope.watchlist: 'Watchlist',
  };

  static const _scopeIcons = {
    ExportScope.downloads: Icons.download_done_outlined,
    ExportScope.favorites: Icons.favorite_outline,
    ExportScope.watchlist: Icons.visibility_outlined,
  };

  Future<void> _export() async {
    if (_scopes.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);
    try {
      final content = await _service.export(
        scopes: _scopes,
        format: _format,
      );

      // Web has no filesystem to share from — share the text directly.
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(text: content, title: 'IA Helper metadata export'),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final extension = _format == ExportFormat.json ? 'json' : 'csv';
        final fileName =
            'ia-helper-export-${DateTime.now().millisecondsSinceEpoch}.'
            '$extension';
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            title: 'IA Helper metadata export',
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.ios_share, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export metadata',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close export sheet',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Generate a JSON or CSV document of your local library data, '
              'with citation-style records for each item. The file leaves '
              'your device only when you share it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('What to export', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ExportScope.values.map((scope) {
                final selected = _scopes.contains(scope);
                return FilterChip(
                  avatar: Icon(
                    _scopeIcons[scope],
                    size: 18,
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  label: Text(_scopeLabels[scope]!),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _scopes.add(scope);
                      } else {
                        _scopes.remove(scope);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Format', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(
                  value: ExportFormat.json,
                  icon: Icon(Icons.data_object),
                  label: Text('JSON'),
                ),
                ButtonSegment(
                  value: ExportFormat.csv,
                  icon: Icon(Icons.table_view),
                  label: Text('CSV'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) {
                setState(() => _format = selection.first);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _scopes.isEmpty ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Exporting',
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(_isExporting ? 'Exporting…' : 'Export & share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
