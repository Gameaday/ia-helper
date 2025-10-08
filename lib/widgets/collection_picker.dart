import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/collection.dart';
import 'package:internet_archive_helper/services/collections_service.dart';

/// Material Design 3 compliant collection picker widget
///
/// Displays as a bottom sheet allowing users to:
/// - Add an archive item to one or more collections
/// - Create a new collection on-the-fly
/// - See which collections already contain the item
/// - MD3 container transform animation
class CollectionPicker extends StatefulWidget {
  /// The archive identifier to add to collections
  final String identifier;

  /// Optional title for display
  final String? title;

  /// Optional mediatype for the item
  final String? mediatype;

  /// Callback when collections are updated
  final VoidCallback? onCollectionsUpdated;

  const CollectionPicker({
    super.key,
    required this.identifier,
    this.title,
    this.mediatype,
    this.onCollectionsUpdated,
  });

  @override
  State<CollectionPicker> createState() => _CollectionPickerState();

  /// Show the collection picker as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String identifier,
    String? title,
    String? mediatype,
    VoidCallback? onCollectionsUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CollectionPicker(
        identifier: identifier,
        title: title,
        mediatype: mediatype,
        onCollectionsUpdated: onCollectionsUpdated,
      ),
    );
  }
}

class _CollectionPickerState extends State<CollectionPicker> {
  final _collectionsService = CollectionsService.instance;

  List<Collection> _allCollections = [];
  Set<int> _selectedCollectionIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all collections
      final collections = await _collectionsService.getAllCollections();

      // Load which collections already contain this item
      final existingCollections = await _collectionsService
          .getCollectionsForItem(widget.identifier);
      final existingIds = existingCollections.map((c) => c.id!).toSet();

      setState(() {
        _allCollections = collections;
        _selectedCollectionIds = existingIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Get currently selected collections
      final currentIds = await _collectionsService.getCollectionsForItem(
        widget.identifier,
      );
      final currentIdSet = currentIds.map((c) => c.id!).toSet();

      // Find collections to add to
      final toAdd = _selectedCollectionIds.difference(currentIdSet);
      for (final collectionId in toAdd) {
        await _collectionsService.addItemToCollection(
          collectionId: collectionId,
          identifier: widget.identifier,
        );
      }

      // Find collections to remove from
      final toRemove = currentIdSet.difference(_selectedCollectionIds);
      for (final collectionId in toRemove) {
        await _collectionsService.removeItemFromCollection(
          collectionId: collectionId,
          identifier: widget.identifier,
        );
      }

      widget.onCollectionsUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedCollectionIds.isEmpty
                ? 'Removed from collections'
                : 'Added to ${_selectedCollectionIds.length} ${_selectedCollectionIds.length == 1 ? 'collection' : 'collections'}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 8, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Collections',
                            style: theme.textTheme.headlineSmall,
                          ),
                          if (widget.title != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.title!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(child: _buildContent(scrollController)),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading || _isSaving
                            ? null
                            : () => _showCreateCollectionDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('New Collection'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading || _isSaving
                            ? null
                            : _saveChanges,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading collections',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadCollections,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allCollections.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _allCollections.length,
      itemBuilder: (context, index) {
        return _buildCollectionItem(_allCollections[index]);
      },
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
              Icons.folder_open,
              size: 96,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text('No Collections', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Create your first collection to organize your favorites',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Collection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionItem(Collection collection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCollectionIds.contains(collection.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedCollectionIds.add(collection.id!);
            } else {
              _selectedCollectionIds.remove(collection.id);
            }
          });
        },
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: collection.color ?? colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            collection.iconData,
            color: collection.color != null
                ? _getContrastColor(collection.color!)
                : colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(collection.name),
        subtitle:
            collection.description != null && collection.description!.isNotEmpty
            ? Text(
                collection.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }

  void _showCreateCollectionDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _QuickCreateDialog(),
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final collectionId = await _collectionsService.createCollection(
        name: name.trim(),
      );

      if (collectionId != null) {
        await _loadCollections();

        // Auto-select the newly created collection
        setState(() {
          _selectedCollectionIds.add(collectionId);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collection "$name" created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating collection: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Quick dialog for creating a new collection
class _QuickCreateDialog extends StatefulWidget {
  const _QuickCreateDialog();

  @override
  State<_QuickCreateDialog> createState() => _QuickCreateDialogState();
}

class _QuickCreateDialogState extends State<_QuickCreateDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            hintText: 'Enter name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
          autofocus: true,
          onFieldSubmitted: (_) {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
