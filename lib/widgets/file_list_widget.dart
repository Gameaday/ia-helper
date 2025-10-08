import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'package:open_file/open_file.dart';
import '../models/archive_metadata.dart';
import '../services/archive_service.dart';
import '../services/file_preview_service.dart';
import '../screens/file_preview_screen.dart';
import '../screens/filters_screen.dart';
import '../utils/permission_utils.dart';
import '../utils/animation_constants.dart';
import 'preview_dialog.dart';

// File download state enum
enum _FileState { notDownloaded, downloaded, outdated, checking }

class FileListWidget extends StatefulWidget {
  final List<ArchiveFile> files;

  const FileListWidget({super.key, required this.files});

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  bool _selectAll = false;
  String _sortBy = 'name'; // name, size, format
  bool _sortAscending = true;

  // Filter state
  List<String> _selectedIncludeFormats = [];
  List<String> _selectedExcludeFormats = [];
  String? _maxSize;

  // Source type filters - start unselected (no filter)
  bool _includeOriginal = false;
  bool _includeDerivative = false;
  bool _includeMetadata = false;

  // File state tracking
  final Map<String, _FileState> _fileStates = {};
  String? _currentArchiveId;

  @override
  void initState() {
    super.initState();
    // Get archive ID from service for constructing file paths
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<ArchiveService>();
      _currentArchiveId = service.currentMetadata?.identifier;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedFiles = _getSortedFiles();
    final selectedCount = sortedFiles.where((f) => f.selected).length;
    final totalSize = _calculateSelectedSize(sortedFiles);

    return Column(
      children: [
        // List controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Select all checkbox
              Checkbox(
                value: _selectAll,
                onChanged: (value) {
                  setState(() {
                    _selectAll = value ?? false;
                    for (var file in sortedFiles) {
                      file.selected = _selectAll;
                    }
                  });
                  // Notify service that selection changed
                  context.read<ArchiveService>().notifyFileSelectionChanged();
                },
              ),
              Text(
                _selectAll ? 'Deselect All' : 'Select All',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

              const Spacer(),

              // Filter button with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 20),
                    onPressed: _openFiltersScreen,
                    tooltip: 'Filter files',
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${_getActiveFilterCount()}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 4),

              // Sort dropdown
              PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, size: 18),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    ),
                  ],
                ),
                tooltip: 'Sort files',
                onSelected: (value) {
                  setState(() {
                    if (_sortBy == value) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortBy = value;
                      _sortAscending = true;
                    }
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha),
                        SizedBox(width: 8),
                        Text('Sort by Name'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'size',
                    child: Row(
                      children: [
                        Icon(Icons.storage),
                        SizedBox(width: 8),
                        Text('Sort by Size'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'format',
                    child: Row(
                      children: [
                        Icon(Icons.category),
                        SizedBox(width: 8),
                        Text('Sort by Format'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Selection summary
        if (selectedCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              '$selectedCount files selected • ${_formatSize(totalSize)}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // File list
        Expanded(
          child: sortedFiles.isEmpty
              ? Consumer<ArchiveService>(
                  builder: (context, service, child) {
                    final hasActiveFilters = _hasActiveFilters();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasActiveFilters
                                  ? Icons.filter_list_off
                                  : Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasActiveFilters
                                  ? 'No files match the current filters'
                                  : 'No files available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Try adjusting your filters to see more results',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Clear all filters
                                  setState(() {
                                    _selectedIncludeFormats.clear();
                                    _selectedExcludeFormats.clear();
                                    _maxSize = null;
                                    _includeOriginal = false;
                                    _includeDerivative = false;
                                    _includeMetadata = false;
                                  });
                                  // Re-apply with no filters
                                  service.filterFiles();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear All Filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: sortedFiles.length,
                  // Optimized cache extent for smooth scrolling with large lists
                  cacheExtent: 1000,
                  // Virtual scrolling: only builds visible items + cache
                  itemBuilder: (context, index) {
                    return _buildFileItem(sortedFiles[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileItem(ArchiveFile file) {
    // Get cached file state or default to notDownloaded
    final fileState = _fileStates[file.name] ?? _FileState.notDownloaded;

    return CheckboxListTile(
      value: file.selected,
      onChanged: (selected) {
        setState(() {
          file.selected = selected ?? false;
          _updateSelectAllState();
        });
        // Notify service that selection changed
        context.read<ArchiveService>().notifyFileSelectionChanged();
      },
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // File state badge
          _buildFileStateBadge(fileState),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (file.format != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getFormatColor(file.format!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.format!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                file.sizeFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (file.name != file.displayName)
            Text(
              file.name,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview button (if file is previewable)
          if (FilePreviewService().canPreview(file.name))
            _buildPreviewButton(file),
          // Contextual action button based on file state
          _buildActionButton(file, fileState),
          // Overflow menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleFileAction(file, action, fileState),
            itemBuilder: (context) => [
              // Show Open option if file is downloaded
              if (fileState == _FileState.downloaded ||
                  fileState == _FileState.outdated)
                PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(_getFileTypeIcon(file.format)),
                      const SizedBox(width: 8),
                      Text(_getFileTypeAction(file.format)),
                    ],
                  ),
                ),
              // Show Delete option if file is downloaded
              if (fileState == _FileState.downloaded ||
                  fileState == _FileState.outdated)
                PopupMenuItem(
                  value: 'delete',
                  child: Builder(
                    builder: (context) => Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete Local File',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview),
                    SizedBox(width: 8),
                    Text('Preview'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('File Info'),
                  ],
                ),
              ),
              if (file.md5 != null || file.sha1 != null)
                const PopupMenuItem(
                  value: 'checksum',
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint),
                      SizedBox(width: 8),
                      Text('Checksums'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  List<ArchiveFile> _getSortedFiles() {
    final files = List<ArchiveFile>.from(widget.files);

    files.sort((a, b) {
      int result = 0;

      switch (_sortBy) {
        case 'name':
          result = a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
          break;
        case 'size':
          final aSize = a.size ?? 0;
          final bSize = b.size ?? 0;
          result = aSize.compareTo(bSize);
          break;
        case 'format':
          final aFormat = a.format ?? '';
          final bFormat = b.format ?? '';
          result = aFormat.compareTo(bFormat);
          break;
      }

      return _sortAscending ? result : -result;
    });

    return files;
  }

  void _updateSelectAllState() {
    final selectedCount = widget.files.where((f) => f.selected).length;
    setState(() {
      _selectAll =
          selectedCount == widget.files.length && widget.files.isNotEmpty;
    });
  }

  int _calculateSelectedSize(List<ArchiveFile> files) {
    return files
        .where((f) => f.selected)
        .map((f) => f.size ?? 0)
        .fold(0, (sum, size) => sum + size);
  }

  Color _getFormatColor(String format) {
    final formatLower = format.toLowerCase();

    // Document formats
    if (['pdf', 'doc', 'docx', 'txt', 'epub'].contains(formatLower)) {
      return Theme.of(context).colorScheme.primary;
    }
    // Image formats
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg'].contains(formatLower)) {
      return Theme.of(context).colorScheme.tertiary;
    }
    // Video formats
    if (['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(formatLower)) {
      return Theme.of(context).colorScheme.secondary;
    }
    // Audio formats
    if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(formatLower)) {
      return Theme.of(context).colorScheme.tertiaryContainer;
    }
    // Archive formats
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(formatLower)) {
      return Theme.of(context).colorScheme.secondaryContainer;
    }

    return Theme.of(context).colorScheme.surfaceContainerHighest;
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

  void _handleFileAction(
    ArchiveFile file,
    String action,
    _FileState fileState,
  ) {
    switch (action) {
      case 'open':
        _openLocalFile(file);
        break;
      case 'delete':
        _deleteLocalFile(file);
        break;
      case 'preview':
        _showFilePreview(file);
        break;
      case 'info':
        _showFileInfo(file);
        break;
      case 'checksum':
        _showChecksums(file);
        break;
    }
  }

  void _showFilePreview(ArchiveFile file) {
    Navigator.push(
      context,
      MD3PageTransitions.fadeThrough(
        page: FilePreviewScreen(file: file),
      ),
    );
  }

  void _showFileInfo(ArchiveFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Full Path', file.name),
            if (file.format != null) _buildInfoRow('Format', file.format!),
            _buildInfoRow('Size', file.sizeFormatted),
            if (file.downloadUrl != null)
              _buildInfoRow('URL', file.downloadUrl!, isUrl: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChecksums(ArchiveFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Checksums'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.md5 != null) _buildInfoRow('MD5', file.md5!),
            if (file.sha1 != null) _buildInfoRow('SHA1', file.sha1!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isUrl ? Theme.of(context).colorScheme.primary : null,
              decoration: isUrl ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedIncludeFormats.isNotEmpty ||
        _selectedExcludeFormats.isNotEmpty ||
        _maxSize != null ||
        _includeOriginal ||
        _includeDerivative ||
        _includeMetadata;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedIncludeFormats.isNotEmpty) count++;
    if (_selectedExcludeFormats.isNotEmpty) count++;
    if (_maxSize != null) count++;
    // Count source type as active when at least one is selected
    if (_includeOriginal || _includeDerivative || _includeMetadata) count++;
    return count;
  }

  void _openFiltersScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MD3PageTransitions.sharedAxis(
        page: FiltersScreen(
          initialIncludeFormats: _selectedIncludeFormats,
          initialExcludeFormats: _selectedExcludeFormats,
          initialMaxSize: _maxSize,
          initialIncludeOriginal: _includeOriginal,
          initialIncludeDerivative: _includeDerivative,
          initialIncludeMetadata: _includeMetadata,
        ),
      ),
    );

    // Update local state with returned filter values
    if (result != null && mounted) {
      setState(() {
        _selectedIncludeFormats = List<String>.from(
          result['includeFormats'] ?? [],
        );
        _selectedExcludeFormats = List<String>.from(
          result['excludeFormats'] ?? [],
        );
        _maxSize = result['maxSize'] as String?;
        _includeOriginal = result['includeOriginal'] as bool? ?? false;
        _includeDerivative = result['includeDerivative'] as bool? ?? false;
        _includeMetadata = result['includeMetadata'] as bool? ?? false;
      });
    }
  }

  // File state checking methods
  Future<void> _checkFileState(ArchiveFile file) async {
    if (_currentArchiveId == null) return;

    setState(() {
      _fileStates[file.name] = _FileState.checking;
    });

    final filePath = _getLocalFilePath(_currentArchiveId!, file.filename);
    final localFile = File(filePath);

    if (!await localFile.exists()) {
      setState(() {
        _fileStates[file.name] = _FileState.notDownloaded;
      });
      return;
    }

    // File exists, check MD5 hash if available
    if (file.md5 != null) {
      final calculatedMd5 = await _calculateFileMD5(localFile);
      if (calculatedMd5 != null &&
          calculatedMd5.toLowerCase() == file.md5!.toLowerCase()) {
        setState(() {
          _fileStates[file.name] = _FileState.downloaded;
        });
      } else {
        setState(() {
          _fileStates[file.name] = _FileState.outdated;
        });
      }
    } else {
      // No hash available, assume downloaded
      setState(() {
        _fileStates[file.name] = _FileState.downloaded;
      });
    }
  }

  Future<String?> _calculateFileMD5(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      return null;
    }
  }

  String _getLocalFilePath(String archiveId, String filename) {
    return '/storage/emulated/0/Download/ia-get/$archiveId/$filename';
  }

  // UI helper methods
  Widget _buildFileStateBadge(_FileState state) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (state) {
      case _FileState.downloaded:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.check_circle,
            size: 14,
            color: colorScheme.onTertiaryContainer,
          ),
        );
      case _FileState.outdated:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.update,
            size: 14,
            color: colorScheme.onErrorContainer,
          ),
        );
      case _FileState.checking:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _FileState.notDownloaded:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(ArchiveFile file, _FileState state) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (state) {
      case _FileState.downloaded:
        return IconButton(
          icon: Icon(_getFileTypeIcon(file.format)),
          tooltip: _getFileTypeAction(file.format),
          onPressed: () => _openLocalFile(file),
          color: colorScheme.tertiary,
        );
      case _FileState.outdated:
        return IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Update File',
          onPressed: () => _redownloadFile(file),
          color: colorScheme.error,
        );
      case _FileState.checking:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _FileState.notDownloaded:
        // Check file state when button is about to be built
        if (_currentArchiveId != null && !_fileStates.containsKey(file.name)) {
          _checkFileState(file);
        }
        return const SizedBox.shrink();
    }
  }

  /// Build preview button with cache status indicator
  Widget _buildPreviewButton(ArchiveFile file) {
    if (_currentArchiveId == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<bool>(
      future: FilePreviewService().isPreviewCached(_currentArchiveId!, file.name),
      builder: (context, snapshot) {
        final isCached = snapshot.data ?? false;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: isCached 
                  ? 'Preview file (cached offline)' 
                  : 'Preview file',
              onPressed: () => _showPreview(file),
              iconSize: 20,
            ),
            // Cache badge
            if (isCached)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.offline_pin,
                    size: 10,
                    color: colorScheme.onTertiary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _getFileTypeIcon(String? format) {
    if (format == null) return Icons.insert_drive_file;
    final fmt = format.toLowerCase();

    // Video formats
    if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(fmt)) {
      return Icons.play_circle_outline;
    }
    // Audio formats
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(fmt)) {
      return Icons.headphones;
    }
    // Image formats
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'].contains(fmt)) {
      return Icons.image;
    }
    // Document formats
    if (['pdf', 'doc', 'docx', 'txt', 'epub'].contains(fmt)) {
      return Icons.description;
    }

    return Icons.folder_open;
  }

  String _getFileTypeAction(String? format) {
    if (format == null) return 'Open';
    final fmt = format.toLowerCase();

    // Video formats
    if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(fmt)) {
      return 'Watch';
    }
    // Audio formats
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(fmt)) {
      return 'Listen';
    }
    // Image formats
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'].contains(fmt)) {
      return 'View';
    }

    return 'Open';
  }

  // File action methods
  Future<void> _openLocalFile(ArchiveFile file) async {
    if (_currentArchiveId == null) return;

    // Check if we have permission to access files
    final hasPermission = await PermissionUtils.hasManageStoragePermission();

    if (!hasPermission) {
      if (!mounted) return;

      // Request permission with explanation
      final granted = await PermissionUtils.requestManageStoragePermission(
        context,
      );

      if (!granted) {
        // User denied permission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage access permission is required to open files',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final filePath = _getLocalFilePath(_currentArchiveId!, file.filename);
    final result = await OpenFile.open(filePath);

    if (mounted && result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}')),
      );
    }
  }

  Future<void> _deleteLocalFile(ArchiveFile file) async {
    if (_currentArchiveId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Local File'),
        content: Text('Delete ${file.filename} from your device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Builder(
              builder: (context) => Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final filePath = _getLocalFilePath(_currentArchiveId!, file.filename);
      final localFile = File(filePath);

      if (await localFile.exists()) {
        await localFile.delete();
        setState(() {
          _fileStates[file.name] = _FileState.notDownloaded;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
      }
    }
  }

  void _redownloadFile(ArchiveFile file) {
    // Mark for re-download by selecting it and triggering download
    setState(() {
      file.selected = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.filename} selected for re-download'),
          action: SnackBarAction(
            label: 'Download',
            onPressed: () {
              // User should use the download button to proceed
            },
          ),
        ),
      );
    }
  }

  /// Show preview dialog for a file
  void _showPreview(ArchiveFile file) {
    if (_currentArchiveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archive not loaded')),
      );
      return;
    }

    // Get filtered and sorted files (same list as displayed)
    final displayedFiles = _getSortedFiles();
    
    // Find the index of the current file
    final fileIndex = displayedFiles.indexWhere((f) => f.name == file.name);
    
    if (fileIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    PreviewDialog.show(
      context,
      _currentArchiveId!,
      displayedFiles,
      fileIndex,
    );
  }
}
