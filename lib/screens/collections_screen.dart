import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/collection.dart';
import 'package:internet_archive_helper/services/collections_service.dart';

/// Material Design 3 compliant collections management screen
/// 
/// Features:
/// - List of all collections with item counts
/// - Create new collection with name, description, icon, color
/// - Edit/rename existing collections
/// - Delete collections with confirmation
/// - View collection details (items)
/// - Empty state with MD3 illustration
/// - MD3 transitions and animations
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _collectionsService = CollectionsService.instance;
  
  List<Collection> _collections = [];
  Map<int, int> _itemCounts = {};
  bool _isLoading = true;
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
      final collections = await _collectionsService.getAllCollections();
      final counts = <int, int>{};
      
      // Load item counts for each collection
      for (final collection in collections) {
        final count = await _collectionsService.getCollectionItemCount(collection.id!);
        counts[collection.id!] = count;
      }
      
      setState(() {
        _collections = collections;
        _itemCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCollectionDialog,
            tooltip: 'Create collection',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
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
      );
    }
    
    if (_collections.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadCollections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          return _buildCollectionCard(_collections[index]);
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    
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
            Text(
              'No collections yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create collections to organize your favorite archives',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  
  Widget _buildCollectionCard(Collection collection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemCount = _itemCounts[collection.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewCollectionDetails(collection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Collection icon with color
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: collection.color ?? colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  collection.iconData,
                  color: collection.color != null
                      ? _getContrastColor(collection.color!)
                      : colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Collection info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (collection.description != null &&
                        collection.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditCollectionDialog(collection);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(collection);
                      break;
                    case 'duplicate':
                      _duplicateCollection(collection);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy),
                        SizedBox(width: 12),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCreateCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) => CollectionEditDialog(
        onSave: (name, description, icon, color) async {
          try {
            await _collectionsService.createCollection(
              name: name,
              description: description,
              icon: icon,
              color: color,
            );
            await _loadCollections();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Collection "$name" created'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating collection: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
  
  void _showEditCollectionDialog(Collection collection) {
    showDialog(
      context: context,
      builder: (context) => CollectionEditDialog(
        collection: collection,
        onSave: (name, description, icon, color) async {
          try {
            await _collectionsService.updateCollection(
              id: collection.id!,
              name: name,
              description: description,
              icon: icon,
              color: color,
            );
            await _loadCollections();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Collection "$name" updated'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating collection: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(Collection collection) {
    final itemCount = _itemCounts[collection.id] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Collection?'),
        content: Text(
          itemCount > 0
              ? 'This will delete "${collection.name}" and remove $itemCount ${itemCount == 1 ? 'item' : 'items'} from the collection. Favorites will not be affected.'
              : 'Are you sure you want to delete "${collection.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _collectionsService.deleteCollection(collection.id!);
                await _loadCollections();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Collection "${collection.name}" deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting collection: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _duplicateCollection(Collection collection) async {
    try {
      final newCollectionId = await _collectionsService.duplicateCollection(
        sourceCollectionId: collection.id!,
        newName: '${collection.name} (Copy)',
      );
      
      if (newCollectionId == null) {
        throw Exception('Failed to duplicate collection');
      }
      
      await _loadCollections();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collection duplicated as "${collection.name} (Copy)"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error duplicating collection: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _viewCollectionDetails(Collection collection) async {
    // Get collection items
    final items = await _collectionsService.getCollectionItems(
      collectionId: collection.id!,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              if (collection.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    IconData(int.parse(collection.icon!), fontFamily: 'MaterialIcons'),
                    color: collection.color,
                  ),
                ),
              Expanded(
                child: Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (collection.description != null &&
                    collection.description!.isNotEmpty) ...[
                  Text(
                    collection.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                // Collection metadata
                _buildDetailRow(
                  context,
                  Icons.archive,
                  'Items',
                  '${items.length}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  'Created',
                  _formatDate(collection.createdAt),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.update,
                  'Updated',
                  _formatDate(collection.updatedAt),
                ),
                if (collection.isSmart) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    Icons.auto_awesome,
                    'Type',
                    'Smart Collection',
                  ),
                ],
                // Show first few items
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Items',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...items.take(5).map((identifier) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              identifier,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '... and ${items.length - 5} more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                _showEditCollectionDialog(collection);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Color _getContrastColor(Color background) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Dialog for creating or editing a collection
class CollectionEditDialog extends StatefulWidget {
  final Collection? collection;
  final Function(String name, String? description, String icon, Color? color) onSave;

  const CollectionEditDialog({
    super.key,
    this.collection,
    required this.onSave,
  });

  @override
  State<CollectionEditDialog> createState() => _CollectionEditDialogState();
}

class _CollectionEditDialogState extends State<CollectionEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;
  late Color? _selectedColor;
  
  final _formKey = GlobalKey<FormState>();
  
  // Available icons
  static const _availableIcons = [
    'folder',
    'collections',
    'star',
    'favorite',
    'bookmark',
    'label',
    'local_offer',
    'inventory_2',
    'category',
    'style',
    'palette',
  ];
  
  // Available colors
  static final _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.collection?.description ?? '',
    );
    _selectedIcon = widget.collection?.icon ?? 'folder';
    _selectedColor = widget.collection?.color;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      title: Text(widget.collection == null ? 'Create Collection' : 'Edit Collection'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter collection name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Icon selector
              Text(
                'Icon',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((iconName) {
                  final isSelected = iconName == _selectedIcon;
                  final iconData = _getIconDataFromName(iconName);
                  return FilterChip(
                    label: Icon(
                      iconData,
                      size: 20,
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedIcon = iconName);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Color selector
              Text(
                'Color (optional)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // No color option
                  FilterChip(
                    label: const Icon(Icons.block, size: 20),
                    selected: _selectedColor == null,
                    onSelected: (_) {
                      setState(() => _selectedColor = null);
                    },
                  ),
                  // Color options
                  ..._availableColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return FilterChip(
                      label: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedColor = color);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
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
              widget.onSave(
                _nameController.text.trim(),
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                _selectedIcon,
                _selectedColor,
              );
              Navigator.pop(context);
            }
          },
          child: Text(widget.collection == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
  
  IconData _getIconDataFromName(String iconName) {
    switch (iconName) {
      case 'folder':
        return Icons.folder;
      case 'collections':
        return Icons.collections;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'bookmark':
        return Icons.bookmark;
      case 'label':
        return Icons.label;
      case 'local_offer':
        return Icons.local_offer;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'category':
        return Icons.category;
      case 'style':
        return Icons.style;
      case 'palette':
        return Icons.palette;
      default:
        return Icons.folder;
    }
  }
}
