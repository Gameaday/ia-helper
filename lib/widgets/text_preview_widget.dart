import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/file_preview.dart';

/// Widget for displaying text file previews
///
/// Supports:
/// - Markdown rendering for .md files
/// - Syntax highlighting for code files
/// - Plain text display for other files
/// - Copy to clipboard functionality
class TextPreviewWidget extends StatelessWidget {
  final FilePreview preview;
  final bool isDarkMode;

  const TextPreviewWidget({
    super.key,
    required this.preview,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (preview.textContent == null || preview.textContent!.isEmpty) {
      return const Center(child: Text('No preview available'));
    }

    return Column(
      children: [
        // Action bar with copy button
        _buildActionBar(context),
        const Divider(height: 1),
        // Content area
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  /// Build action bar with copy button
  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            preview.fileName,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
    );
  }

  /// Build content based on file type
  Widget _buildContent(BuildContext context) {
    final fileName = preview.fileName.toLowerCase();

    // Markdown files - use flutter_markdown package
    if (fileName.endsWith('.md') || fileName.endsWith('.markdown')) {
      return _buildMarkdownContent(context);
    }

    // Code files - use flutter_highlight package
    if (_isCodeFile(fileName)) {
      return _buildHighlightedContent(context);
    }

    // Plain text - simple scrollable text
    return _buildPlainTextContent(context);
  }

  /// Build markdown content using flutter_markdown
  Widget _buildMarkdownContent(BuildContext context) {
    return Markdown(
      data: preview.textContent!,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      padding: const EdgeInsets.all(16),
    );
  }

  /// Build syntax-highlighted content using flutter_highlight
  Widget _buildHighlightedContent(BuildContext context) {
    final language = _detectLanguage(preview.fileName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: HighlightView(
        preview.textContent!,
        language: language,
        theme: isDarkMode ? monokaiSublimeTheme : githubTheme,
        padding: const EdgeInsets.all(12),
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
    );
  }

  /// Build plain text content
  Widget _buildPlainTextContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        preview.textContent!,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
    );
  }

  /// Copy content to clipboard
  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: preview.textContent!));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Check if file is a code file
  bool _isCodeFile(String fileName) {
    const codeExtensions = {
      // Programming languages
      '.dart', '.py', '.js', '.ts', '.java', '.c', '.cpp', '.h', '.hpp',
      '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt', '.m', '.mm',

      // Web
      '.html', '.htm', '.css', '.scss', '.sass', '.less',

      // Data/Config
      '.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.conf',

      // Shell
      '.sh', '.bash', '.zsh', '.fish', '.bat', '.cmd', '.ps1',

      // Other
      '.sql', '.r', '.lua', '.vim', '.tex',
    };

    return codeExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Detect programming language from file extension
  String _detectLanguage(String fileName) {
    final lower = fileName.toLowerCase();

    // Map extensions to highlight.js language names
    if (lower.endsWith('.dart')) return 'dart';
    if (lower.endsWith('.py')) return 'python';
    if (lower.endsWith('.js')) return 'javascript';
    if (lower.endsWith('.ts')) return 'typescript';
    if (lower.endsWith('.java')) return 'java';
    if (lower.endsWith('.c')) return 'c';
    if (lower.endsWith('.cpp') || lower.endsWith('.cc')) return 'cpp';
    if (lower.endsWith('.cs')) return 'csharp';
    if (lower.endsWith('.go')) return 'go';
    if (lower.endsWith('.rs')) return 'rust';
    if (lower.endsWith('.rb')) return 'ruby';
    if (lower.endsWith('.php')) return 'php';
    if (lower.endsWith('.swift')) return 'swift';
    if (lower.endsWith('.kt')) return 'kotlin';
    if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'xml';
    if (lower.endsWith('.css')) return 'css';
    if (lower.endsWith('.scss')) return 'scss';
    if (lower.endsWith('.json')) return 'json';
    if (lower.endsWith('.xml')) return 'xml';
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return 'yaml';
    if (lower.endsWith('.sh') || lower.endsWith('.bash')) return 'bash';
    if (lower.endsWith('.sql')) return 'sql';
    if (lower.endsWith('.r')) return 'r';

    // Default to plaintext
    return 'plaintext';
  }
}
