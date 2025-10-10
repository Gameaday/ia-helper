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
                // Offline indicator (only for downloaded files)
                Consumer<ArchiveService>(
                  builder: (context, service, child) {
                    // Check if archive has downloaded files
                    final hasDownloads = service.isDownloaded(metadata.identifier);
                    if (!hasDownloads) return const SizedBox.shrink();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Offline icon only (no text/badge)
                        Tooltip(
                          message: 'Has downloaded files',
                          child: Icon(
                            Icons.offline_pin,
                            size: 20,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
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
                              color: colorScheme.primary,
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
