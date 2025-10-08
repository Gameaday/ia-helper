import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/archive_metadata.dart';
import '../services/archive_service.dart';
import '../models/cached_metadata.dart';

class ArchiveInfoWidget extends StatelessWidget {
  final ArchiveMetadata metadata;

  const ArchiveInfoWidget({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final archiveService = Provider.of<ArchiveService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.archive,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metadata.title ?? metadata.identifier,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Offline indicator and pin button
                FutureBuilder<bool>(
                  future: archiveService.isCached(metadata.identifier),
                  builder: (context, snapshot) {
                    final isCached = snapshot.data ?? false;
                    if (!isCached) return const SizedBox.shrink();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Offline badge
                        Tooltip(
                          message: 'Available offline',
                          child: Builder(
                            builder: (builderContext) {
                              final colorScheme = Theme.of(
                                builderContext,
                              ).colorScheme;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.offline_pin,
                                      size: 14,
                                      color: colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Pin/Unpin button
                        FutureBuilder<CachedMetadata?>(
                          future: archiveService
                              .getCachedMetadata(metadata.identifier)
                              .then(
                                (m) => m != null
                                    ? CachedMetadata.fromMetadata(m)
                                    : null,
                              ),
                          builder: (context, cacheSnapshot) {
                            final cachedMeta = cacheSnapshot.data;
                            final isPinned = cachedMeta?.isPinned ?? false;

                            return IconButton(
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: isPinned
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              tooltip: isPinned
                                  ? 'Unpin archive'
                                  : 'Pin archive',
                              onPressed: () async {
                                await archiveService.togglePin(
                                  metadata.identifier,
                                );
                                // Rebuild UI
                                (context as Element).markNeedsBuild();
                              },
                            );
                          },
                        ),
                        // Sync button
                        IconButton(
                          icon: Icon(
                            Icons.sync,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Sync metadata',
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Syncing metadata...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            try {
                              await archiveService.syncMetadata(
                                metadata.identifier,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Metadata synced successfully',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sync failed: $e'),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            if (metadata.description != null) ...[
              const SizedBox(height: 8),
              Text(
                metadata.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (metadata.creator != null) ...[
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      metadata.creator!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (metadata.date != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metadata.date!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${metadata.totalFiles} files',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.storage,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatSize(metadata.totalSize),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Cache sync status
            FutureBuilder<CachedMetadata?>(
              future: archiveService
                  .getCachedMetadata(metadata.identifier)
                  .then(
                    (m) => m != null ? CachedMetadata.fromMetadata(m) : null,
                  ),
              builder: (context, snapshot) {
                final cachedMeta = snapshot.data;
                if (cachedMeta == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Builder(
                    builder: (builderContext) {
                      final colorScheme = Theme.of(builderContext).colorScheme;
                      return Row(
                        children: [
                          Icon(
                            Icons.sync,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cachedMeta.syncStatusString,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (cachedMeta.isPinned) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }
}
