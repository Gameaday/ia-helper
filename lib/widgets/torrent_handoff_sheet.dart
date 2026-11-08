import 'package:flutter/material.dart';

import '../services/torrent_handoff_service.dart';
import '../utils/animation_constants.dart';

/// "Seed externally" bottom sheet (#93).
///
/// Fetches the item's official torrent and hands it to whatever external
/// torrent app the user has. IA Helper itself never speaks BitTorrent —
/// this is a plain file handoff plus a magnet link, so users can keep
/// alive items whose torrents have no seeders left.
class TorrentHandoffSheet extends StatefulWidget {
  const TorrentHandoffSheet({super.key, required this.identifier, this.title});

  final String identifier;
  final String? title;

  static void show(
    BuildContext context, {
    required String identifier,
    String? title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      style: MD3Sheets.modalEntrance,
      builder: (_) =>
          TorrentHandoffSheet(identifier: identifier, title: title),
    );
  }

  @override
  State<TorrentHandoffSheet> createState() => _TorrentHandoffSheetState();
}

class _TorrentHandoffSheetState extends State<TorrentHandoffSheet> {
  static const TorrentHandoffService _service = TorrentHandoffService();

  bool _loading = true;
  TorrentHandoff? _handoff;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final handoff = await _service.prepare(widget.identifier);
      if (!mounted) return;
      setState(() {
        _handoff = handoff;
        _loading = false;
      });
    } on TorrentHandoffException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while fetching the torrent: $e';
        _loading = false;
      });
    }
  }

  Future<void> _share() async {
    final handoff = _handoff;
    if (handoff == null) return;
    try {
      await _service.shareTorrentFile(handoff);
      if (!mounted) return;
      _snack('Torrent file shared — pick your torrent app.');
    } catch (e) {
      if (!mounted) return;
      _snack('Sharing failed: $e');
    }
  }

  Future<void> _copyMagnet() async {
    final handoff = _handoff;
    if (handoff == null) return;
    try {
      await _service.copyMagnetLink(handoff);
      if (!mounted) return;
      _snack('Magnet link copied to clipboard.');
    } catch (e) {
      if (!mounted) return;
      _snack('Could not copy magnet link: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seed externally',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_loading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(semanticsLabel: 'Fetching torrent'),
              const SizedBox(height: 16),
              Text(
                'Fetching the official torrent from archive.org…',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _prepare,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ] else if (_handoff != null) ...[
              Text(
                'IA Helper doesn\'t torrent itself. Hand the official torrent '
                'for "${_handoff!.name}" to your torrent app — great for '
                'items with no seeders left.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText(
                'btih: ${_handoff!.btih}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share),
                label: const Text('Share torrent file'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _copyMagnet,
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy magnet link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
