import 'package:flutter/material.dart';

import '../services/archive_sync_service.dart';

/// Dialog presenting an [ArchiveSyncReport] and, when the audit found
/// issues, an "Apply fixes" action that runs the caller's repair callback
/// and shows the outcome (#94).
class ArchiveSyncDialog extends StatefulWidget {
  final ArchiveSyncReport report;

  /// Runs the repair (re-download changed files, remove orphans),
  /// persists the updated archive record, and returns the outcome.
  final Future<ArchiveSyncOutcome> Function() onApplyFixes;

  const ArchiveSyncDialog({
    super.key,
    required this.report,
    required this.onApplyFixes,
  });

  @override
  State<ArchiveSyncDialog> createState() => _ArchiveSyncDialogState();
}

class _ArchiveSyncDialogState extends State<ArchiveSyncDialog> {
  bool _applying = false;
  ArchiveSyncOutcome? _outcome;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final outcome = await widget.onApplyFixes();
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _applying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final outcome = _outcome;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text('Sync ${report.identifier}'),
      content: SizedBox(
        width: double.maxFinite,
        child: outcome != null
            ? _buildOutcome(theme, colorScheme, outcome)
            : report.hasIssues
                ? _buildIssues(theme, colorScheme, report)
                : _buildUpToDate(theme, colorScheme, report),
      ),
      actions: [
        if (outcome == null && report.hasIssues)
          FilledButton.icon(
            onPressed: _applying ? null : _apply,
            icon: _applying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build_circle_outlined),
            label: Text(_applying ? 'Applying…' : 'Apply fixes'),
          ),
        TextButton(
          onPressed: _applying ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildUpToDate(
    ThemeData theme,
    ColorScheme colorScheme,
    ArchiveSyncReport report,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified, color: colorScheme.primary, size: 48),
        const SizedBox(height: 12),
        Text(
          'All ${report.files.length} tracked file(s) match archive.org.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Item metadata is up to date.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildIssues(
    ThemeData theme,
    ColorScheme colorScheme,
    ArchiveSyncReport report,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${report.okCount} verified · ${report.repairCount} to re-download · '
          '${report.orphanCount} orphaned',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final file in report.files)
                if (file.status != FileSyncStatus.ok)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: _statusIcon(colorScheme, file.status),
                    title: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_statusLabel(file.status)),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutcome(
    ThemeData theme,
    ColorScheme colorScheme,
    ArchiveSyncOutcome outcome,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          outcome.allApplied ? Icons.task_alt : Icons.warning_amber_outlined,
          color: outcome.allApplied ? colorScheme.primary : colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          '${outcome.repairedFiles} file(s) repaired, '
          '${outcome.deletedOrphans} orphaned file(s) removed.',
          style: theme.textTheme.bodyMedium,
        ),
        if (outcome.failures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${outcome.failures.length} file(s) could not be repaired:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          for (final name in outcome.failures.take(5))
            Text('· $name', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  static Widget _statusIcon(ColorScheme colorScheme, FileSyncStatus status) {
    switch (status) {
      case FileSyncStatus.missing:
        return Icon(Icons.file_download_off, color: colorScheme.error);
      case FileSyncStatus.sizeMismatch:
        return Icon(Icons.update, color: colorScheme.tertiary);
      case FileSyncStatus.corrupt:
        return Icon(Icons.broken_image_outlined, color: colorScheme.error);
      case FileSyncStatus.removedRemote:
        return Icon(
          Icons.delete_outline,
          color: colorScheme.onSurfaceVariant,
        );
      case FileSyncStatus.extra:
        return Icon(Icons.help_outline, color: colorScheme.onSurfaceVariant);
      case FileSyncStatus.ok:
        return Icon(Icons.check_circle, color: colorScheme.primary);
    }
  }

  static String _statusLabel(FileSyncStatus status) {
    switch (status) {
      case FileSyncStatus.ok:
        return 'Verified';
      case FileSyncStatus.missing:
        return 'Missing - will be re-downloaded';
      case FileSyncStatus.sizeMismatch:
        return 'Changed on archive.org - will be re-downloaded';
      case FileSyncStatus.corrupt:
        return 'Corrupt - will be re-downloaded';
      case FileSyncStatus.removedRemote:
        return 'No longer on archive.org - local copy will be removed';
      case FileSyncStatus.extra:
        return 'Not part of the archive - local copy will be removed';
    }
  }
}
