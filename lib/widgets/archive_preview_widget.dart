import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Widget for previewing archive files (ZIP, TAR, GZ, etc.)
class ArchivePreviewWidget extends StatefulWidget {
  final Uint8List archiveBytes;
  final String fileName;
  final int? fileSize;

  const ArchivePreviewWidget({
    super.key,
    required this.archiveBytes,
    required this.fileName,
    this.fileSize,
  });

  @override
  State<ArchivePreviewWidget> createState() => _ArchivePreviewWidgetState();
}

class _ArchivePreviewWidgetState extends State<ArchivePreviewWidget> {
  Archive? _archive;
  String? _error;
  bool _isLoading = true;
  final Set<String> _expandedFolders = {};
  ArchiveFile? _selectedFile;
  Uint8List? _selectedFileContent;
  bool _isExtractingFile = false;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Archive archive;
      final ext = path.extension(widget.fileName).toLowerCase();

      // Decode based on file extension
      if (ext == '.zip') {
        archive = ZipDecoder().decodeBytes(widget.archiveBytes);
      } else if (ext == '.tar') {
        archive = TarDecoder().decodeBytes(widget.archiveBytes);
      } else if (ext == '.gz' || ext == '.gzip') {
        // Try to decompress GZip
        final decompressed = const GZipDecoder().decodeBytes(widget.archiveBytes);
        // Check if it's a tar.gz
        if (widget.fileName.toLowerCase().endsWith('.tar.gz') ||
            widget.fileName.toLowerCase().endsWith('.tgz')) {
          archive = TarDecoder().decodeBytes(decompressed);
        } else {
          // Single file GZip - create archive with single file
          final file = ArchiveFile(
            widget.fileName.replaceAll('.gz', '').replaceAll('.gzip', ''),
            decompressed.length,
            decompressed,
          );
          archive = Archive()..addFile(file);
        }
      } else if (ext == '.bz2' || ext == '.bzip2') {
        final decompressed = BZip2Decoder().decodeBytes(widget.archiveBytes);
        // Check if it's a tar.bz2
        if (widget.fileName.toLowerCase().endsWith('.tar.bz2') ||
            widget.fileName.toLowerCase().endsWith('.tbz2')) {
          archive = TarDecoder().decodeBytes(decompressed);
        } else {
          final file = ArchiveFile(
            widget.fileName.replaceAll('.bz2', '').replaceAll('.bzip2', ''),
            decompressed.length,
            decompressed,
          );
          archive = Archive()..addFile(file);
        }
      } else if (ext == '.xz') {
        final decompressed = XZDecoder().decodeBytes(widget.archiveBytes);
        if (widget.fileName.toLowerCase().endsWith('.tar.xz') ||
            widget.fileName.toLowerCase().endsWith('.txz')) {
          archive = TarDecoder().decodeBytes(decompressed);
        } else {
          final file = ArchiveFile(
            widget.fileName.replaceAll('.xz', ''),
            decompressed.length,
            decompressed,
          );
          archive = Archive()..addFile(file);
        }
      } else {
        // Try ZIP as default
        try {
          archive = ZipDecoder().decodeBytes(widget.archiveBytes);
        } catch (e) {
          // Try TAR as fallback
          try {
            archive = TarDecoder().decodeBytes(widget.archiveBytes);
          } catch (e2) {
            throw Exception('Unsupported archive format: $ext');
          }
        }
      }

      setState(() {
        _archive = archive;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load archive: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleFolder(String folderPath) {
    setState(() {
      if (_expandedFolders.contains(folderPath)) {
        _expandedFolders.remove(folderPath);
      } else {
        _expandedFolders.add(folderPath);
      }
    });
  }

  Future<void> _selectFile(ArchiveFile file) async {
    if (file.isFile) {
      setState(() {
        _isExtractingFile = true;
        _selectedFile = file;
        _selectedFileContent = null;
      });

      try {
        // Extract file content
        final content = file.content as List<int>;
        setState(() {
          _selectedFileContent = Uint8List.fromList(content);
          _isExtractingFile = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to extract file: $e';
          _isExtractingFile = false;
        });
      }
    }
  }

  Future<void> _extractAll() async {
    if (_archive == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final extractPath = path.join(
        directory.path,
        'extracted',
        path.basenameWithoutExtension(widget.fileName),
      );

      // Create extraction directory
      final extractDir = Directory(extractPath);
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract all files
      for (final file in _archive!.files) {
        if (file.isFile) {
          final filePath = path.join(extractPath, file.name);
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted ${_archive!.files.length} files to $extractPath'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract archive: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _getFileIcon(String filename) {
    final ext = path.extension(filename).toLowerCase();
    
    // Images
    if (['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'].contains(ext)) {
      return '🖼️';
    }
    // Documents
    if (['.pdf', '.doc', '.docx', '.txt', '.md', '.rtf'].contains(ext)) {
      return '📄';
    }
    // Audio
    if (['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'].contains(ext)) {
      return '🎵';
    }
    // Video
    if (['.mp4', '.webm', '.mkv', '.avi', '.mov', '.flv'].contains(ext)) {
      return '🎬';
    }
    // Archives
    if (['.zip', '.tar', '.gz', '.bz2', '.xz', '.7z', '.rar'].contains(ext)) {
      return '📦';
    }
    // Code
    if (['.rs', '.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h'].contains(ext)) {
      return '💻';
    }
    
    return '📄';
  }

  Widget _buildFileTree() {
    if (_archive == null || _archive!.files.isEmpty) {
      return Center(
        child: Text(
          'Empty archive',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Build hierarchical structure
    final Map<String, List<ArchiveFile>> filesByPath = {};
    final Set<String> directories = {};

    for (final file in _archive!.files) {
      final filePath = file.name;
      final dirPath = path.dirname(filePath);
      
      // Add all parent directories
      String currentPath = '';
      for (final segment in dirPath.split('/')) {
        if (segment.isEmpty || segment == '.') continue;
        currentPath = currentPath.isEmpty ? segment : '$currentPath/$segment';
        directories.add(currentPath);
      }

      // Add file to its parent directory
      if (!filesByPath.containsKey(dirPath)) {
        filesByPath[dirPath] = [];
      }
      filesByPath[dirPath]!.add(file);
    }

    return ListView(
      children: [
        _buildDirectoryNode('.', filesByPath, directories, 0),
      ],
    );
  }

  Widget _buildDirectoryNode(
    String dirPath,
    Map<String, List<ArchiveFile>> filesByPath,
    Set<String> directories,
    int level,
  ) {
    final isExpanded = _expandedFolders.contains(dirPath);
    final files = filesByPath[dirPath] ?? [];
    final subdirs = directories
        .where((d) => path.dirname(d) == dirPath && d != dirPath)
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Directory header
        if (dirPath != '.')
          InkWell(
            onTap: () => _toggleFolder(dirPath),
            child: Padding(
              padding: EdgeInsets.only(left: level * 16.0 + 8, top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 20,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path.basename(dirPath),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        
        // Contents (if expanded or root)
        if (isExpanded || dirPath == '.')
          ...subdirs.map((subdir) =>
              _buildDirectoryNode(subdir, filesByPath, directories, level + 1)),
        
        if (isExpanded || dirPath == '.')
          ...files.map((file) => _buildFileNode(file, level + 1)),
      ],
    );
  }

  Widget _buildFileNode(ArchiveFile file, int level) {
    final isSelected = _selectedFile == file;
    final filename = path.basename(file.name);

    return InkWell(
      onTap: () => _selectFile(file),
      child: Container(
        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
        padding: EdgeInsets.only(left: level * 16.0 + 8, top: 8, bottom: 8, right: 8),
        child: Row(
          children: [
            Text(
              _getFileIcon(filename),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    _formatFileSize(file.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) {
      return Center(
        child: Text(
          'Select a file to preview',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (_isExtractingFile) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Extracting file...'),
          ],
        ),
      );
    }

    if (_selectedFileContent == null) {
      return Center(
        child: Text(
          'Failed to extract file',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final ext = path.extension(_selectedFile!.name).toLowerCase();
    
    // Try to preview based on file type
    if (['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(ext)) {
      // Image preview
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Image.memory(
                _selectedFileContent!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'Failed to load image',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  path.basename(_selectedFile!.name),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_formatFileSize(_selectedFile!.size)),
              ],
            ),
          ),
        ],
      );
    } else if (['.txt', '.md', '.json', '.xml', '.html', '.css', '.js', '.dart', '.rs'].contains(ext)) {
      // Text preview
      try {
        final text = String.fromCharCodes(_selectedFileContent!);
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  text,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    path.basename(_selectedFile!.name),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_formatFileSize(_selectedFile!.size)),
                ],
              ),
            ),
          ],
        );
      } catch (e) {
        return Center(
          child: Text(
            'Cannot preview as text: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      }
    } else {
      // Binary file - show hex preview
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                _selectedFileContent!
                    .take(1024)
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join(' '),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      path.basename(_selectedFile!.name),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_formatFileSize(_selectedFile!.size)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Binary file (showing first 1KB as hex)',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading archive...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadArchive,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Archive info header
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.archive, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_archive!.files.length} files • ${_formatFileSize(widget.fileSize ?? widget.archiveBytes.length)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _extractAll,
                  icon: const Icon(Icons.folder_zip),
                  tooltip: 'Extract all files',
                ),
              ],
            ),
          ),
        ),
        
        // Split view: file tree and preview
        Expanded(
          child: Row(
            children: [
              // File tree (left side)
              Expanded(
                flex: 1,
                child: Builder(
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                    child: _buildFileTree(),
                  ),
                ),
              ),
              
              // File preview (right side)
              Expanded(
                flex: 1,
                child: _buildFilePreview(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
