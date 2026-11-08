import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/watchlist_entry.dart';
import 'package:internet_archive_helper/screens/archive_detail_screen.dart';
import 'package:internet_archive_helper/services/archive_service.dart';
import 'package:internet_archive_helper/services/watchlist_service.dart';
import 'package:internet_archive_helper/utils/animation_constants.dart';
import 'package:internet_archive_helper/utils/app_shapes.dart';
import 'package:internet_archive_helper/utils/semantic_colors.dart';
import 'package:internet_archive_helper/utils/snackbar_helper.dart';
import 'package:internet_archive_helper/widgets/error_card.dart';
import 'package:provider/provider.dart';

/// Watchlist screen (#91).
///
/// Tracks archive.org items for new uploads, strictly locally. The list
/// checks archive.org when opened (and on refresh); items gain a
/// "N new files" badge when their file count grew since the last look.
/// Opening an item acknowledges the badge.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  static const String routeName = '/watchlist';

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _service = WatchlistService.instance;

  List<WatchlistEntry> _entries = [];
  bool _isLoading = true;
  bool _isChecking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _refresh(checkRemote: true);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted && _service.isChecking != _isChecking) {
      setState(() => _isChecking = _service.isChecking);
    }
  }

  /// Load entries; optionally check archive.org first (check-on-open).
  Future<void> _refresh({bool checkRemote = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var entries = await _service.getAllEntries();
      if (checkRemote && entries.isNotEmpty) {
        await _service.checkAll();
        entries = await _service.getAllEntries();
      }
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(WatchlistEntry entry) async {
    final archiveService = context.read<ArchiveService>();
    try {
      await archiveService.fetchMetadata(entry.identifier);
      if (!mounted) return;

      await Navigator.push(
        context,
        MD3PageTransitions.fadeThrough(
          page: const ArchiveDetailScreen(),
          settings: const RouteSettings(name: ArchiveDetailScreen.routeName),
        ),
      );

      // Opening the item acknowledges any new-files badge.
      await _service.acknowledgeNewFiles(entry.identifier);
      if (mounted) await _refresh();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final identifier = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.visibility_outlined),
        title: const Text('Watch an item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Archive.org identifier',
            hintText: 'e.g. constitution-0001',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Watch'),
          ),
        ],
      ),
    );

    if (identifier == null || identifier.isEmpty) return;
    await _addIdentifier(identifier);
  }

  Future<void> _addIdentifier(String identifier) async {
    final archiveService = context.read<ArchiveService>();
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final validId = await archiveService.validateIdentifier(identifier);
      if (validId == null) {
        throw Exception('No archive.org item found for "$identifier"');
      }

      await _service.addEntry(identifier: validId);
      final entry = await _service.getEntry(validId);
      if (entry != null) {
        try {
          // Baseline check so the badge starts clean.
          await _service.checkEntry(entry, resetBaseline: true);
        } catch (_) {
          // Network hiccup at add time is not fatal — the next
          // check-on-open will establish the baseline.
        }
      }

      await _refresh();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Watching $validId');
    } catch (e) {
      await _refresh();
      if (!mounted) return;
      SnackBarHelper.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            onPressed: _showAddDialog,
            tooltip: 'Watch an item',
          ),
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Checking watchlist',
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isChecking ? null : () => _refresh(checkRemote: true),
            tooltip: 'Check for new files',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading'),
      );
    }

    if (_error != null) {
      return ErrorCard(
        error: Exception(_error!),
        onRetry: () => _refresh(checkRemote: true),
      );
    }

    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(checkRemote: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) => _buildEntryCard(_entries[index]),
      ),
    );
  }

  Widget _buildEntryCard(WatchlistEntry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(entry.identifier),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: colorScheme.errorContainer,
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.onErrorContainer,
          ),
        ),
        onDismissed: (_) async {
          await _service.removeEntry(entry.identifier);
          if (mounted) {
            setState(
              () => _entries.removeWhere(
                (e) => e.identifier == entry.identifier,
              ),
            );
          }
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconFor(entry.mediatype),
                color: colorScheme.primary,
              ),
            ),
            title: Text(
              entry.displayTitle,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.lastCheckedAt == null
                    ? '${entry.identifier} • not checked yet'
                    : '${entry.identifier} • ${entry.knownFileCount} files • '
                        'checked ${_formatDate(entry.lastCheckedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: entry.hasNewFiles ? _newBadge(entry.newFileCount) : null,
            onTap: () => _openEntry(entry),
          ),
        ),
      ),
    );
  }

  Widget _newBadge(int count) {
    final theme = Theme.of(context);
    final success = SemanticColors.successOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: success.withAlpha(38),
        borderRadius: AppShapes.small,
      ),
      child: Text(
        '$count new',
        style: theme.textTheme.labelSmall?.copyWith(
          color: success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 96,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text('Watchlist is empty', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Watch archive.org items and get a badge when new files are '
              'uploaded. Everything stays on this device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Watch an item'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? mediatype) {
    switch (mediatype?.toLowerCase()) {
      case 'texts':
        return Icons.menu_book;
      case 'movies':
        return Icons.movie;
      case 'audio':
        return Icons.music_note;
      case 'software':
        return Icons.apps;
      case 'image':
        return Icons.image;
      case 'web':
        return Icons.public;
      default:
        return Icons.visibility_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours == 0) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
