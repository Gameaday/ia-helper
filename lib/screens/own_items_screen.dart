import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/archive_metadata.dart';
import '../services/archive_service.dart';
import '../services/local_archive_storage.dart';
import '../services/own_items_service.dart';
import '../utils/snackbar_helper.dart';
import 'archive_detail_screen.dart';
import 'ia_account_screen.dart';

/// Lists the items the user can write to on archive.org, with local sync
/// state, in-app opening, and remote metadata editing (#95).
class OwnItemsScreen extends StatefulWidget {
  const OwnItemsScreen({super.key});

  static const String routeName = '/own-items';

  @override
  State<OwnItemsScreen> createState() => _OwnItemsScreenState();
}

class _OwnItemsScreenState extends State<OwnItemsScreen> {
  final _filterController = TextEditingController();
  late final OwnItemsService _service;

  List<OwnItem> _items = [];
  bool _loading = true;
  bool _isAuthError = false;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _service = OwnItemsService();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _isAuthError = false;
    });
    try {
      final items = await _service.listOwnItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on IAS3AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isAuthError = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your items';
        _loading = false;
      });
    }
  }

  /// Edit the item's remote metadata (read -> edit -> write -> verify,
  /// #95). forceRefresh reads the CURRENT remote metadata rather than an
  /// ETag-cached copy.
  Future<void> _editMetadata(OwnItem item) async {
    final archiveService = context.read<ArchiveService>();
    try {
      await archiveService.fetchMetadata(item.identifier, forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
      return;
    }
    if (!mounted) return;
    final metadata = archiveService.currentMetadata;
    if (metadata == null) {
      SnackBarHelper.showError(context, 'Could not load item metadata');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _MetadataEditDialog(
        item: item,
        metadata: metadata,
        service: _service,
        archiveService: archiveService,
      ),
    );
  }

  /// Open the item in the app's detail screen (same pattern as Library).
  Future<void> _openInApp(OwnItem item) async {
    final archiveService = context.read<ArchiveService>();
    try {
      await archiveService.fetchMetadata(item.identifier, forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
      return;
    }
    if (!mounted) return;
    if (archiveService.currentMetadata != null) {
      await Navigator.pushNamed(context, ArchiveDetailScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadedIds = context.watch<LocalArchiveStorage>().archives.keys;
    final query = _filter.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _items
        : _items
              .where((i) => i.identifier.toLowerCase().contains(query))
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Items')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'))
          : _error != null
          ? _buildError(theme, colorScheme)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      labelText: 'Filter items',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _filter.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear filter',
                              onPressed: () {
                                _filterController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                    ),
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty(theme, colorScheme)
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final onDevice = downloadedIds.contains(
                              item.identifier,
                            );
                            final subtitle = [
                              if (item.creationDate != null)
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(item.creationDate!),
                              if (onDevice) 'On this device',
                            ].join('  ·  ');
                            return ListTile(
                              leading: Icon(
                                Icons.inventory_2_outlined,
                                color: onDevice
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              title: Text(
                                item.identifier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                subtitle.isEmpty
                                    ? 'Tap to edit metadata'
                                    : subtitle,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open in app',
                                onPressed: () => _openInApp(item),
                              ),
                              onTap: () => _editMetadata(item),
                            );
                          },
                        ),
                ),
                if (filtered.length != _items.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Showing ${filtered.length} of ${_items.length} item(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAuthError
                  ? Icons.key_off_outlined
                  : Icons.cloud_off_outlined,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            if (_isAuthError) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, IAAccountScreen.routeName),
                child: const Text('Configure S3 keys'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No items found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _filter.isEmpty
                ? 'Your keys have no writable items yet.'
                : 'No items match this filter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for editing one item's remote metadata (#95). Sends the change
/// via the IA metadata write API, then re-reads the item to verify the
/// round-trip (archive.org applies writes via its metadata task queue, so
/// the verification read can briefly lag).
class _MetadataEditDialog extends StatefulWidget {
  final OwnItem item;
  final ArchiveMetadata metadata;
  final OwnItemsService service;
  final ArchiveService archiveService;

  const _MetadataEditDialog({
    required this.item,
    required this.metadata,
    required this.service,
    required this.archiveService,
  });

  @override
  State<_MetadataEditDialog> createState() => _MetadataEditDialogState();
}

class _MetadataEditDialogState extends State<_MetadataEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.metadata.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.metadata.description ?? '',
    );
    // The local metadata model does not carry subject tags, so the field
    // starts empty; leaving it blank keeps the remote tags untouched.
    _subjectController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final accepted = await widget.service.updateItemMetadata(
        widget.item.identifier,
        title: title,
        description: _descriptionController.text.trim(),
        subject: _subjectController.text.trim(),
      );
      if (!accepted) {
        if (!mounted) return;
        SnackBarHelper.showWarning(
          context,
          'archive.org did not accept the change',
        );
        Navigator.of(context).pop();
        return;
      }
      // Verify the round-trip: re-read and compare (#95).
      var verified = false;
      try {
        await widget.archiveService.fetchMetadata(
          widget.item.identifier,
          forceRefresh: true,
        );
        final refreshed = widget.archiveService.currentMetadata;
        verified = refreshed?.title?.trim() == title;
      } catch (_) {
        // The verification read failed; the write itself already
        // succeeded, so fall through to the "submitted" message.
      }
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        verified
            ? 'Metadata updated and verified'
            : 'Change submitted - archive.org applies it in a moment',
      );
      Navigator.of(context).pop();
    } on IAS3AuthException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      SnackBarHelper.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      SnackBarHelper.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Metadata'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.identifier,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Title cannot be empty'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject tags',
                  hintText: 'Comma-separated (leave blank to keep current)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _save,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(_submitting ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
