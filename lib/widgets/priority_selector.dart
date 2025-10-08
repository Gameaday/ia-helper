import 'package:flutter/material.dart';
import '../models/download_priority.dart';
import '../utils/app_shapes.dart';

/// Compact priority selector for mobile UI
/// 
/// Shows priority as a chip/badge with icon and color
/// Tapping opens a bottom sheet for selection
class PrioritySelector extends StatelessWidget {
  final DownloadPriority priority;
  final ValueChanged<DownloadPriority> onChanged;
  final bool compact;

  const PrioritySelector({
    super.key,
    required this.priority,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactChip(context);
    }
    return _buildFullChip(context);
  }

  /// Build compact chip (icon only)
  Widget _buildCompactChip(BuildContext context) {
    return InkWell(
      onTap: () => _showPriorityPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(priority.colorValue).withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(priority.colorValue).withAlpha(76),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priority.icon,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Build full chip (icon + text)
  Widget _buildFullChip(BuildContext context) {
    return InkWell(
      onTap: () => _showPriorityPicker(context),
      borderRadius: AppShapes.large,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(priority.colorValue).withAlpha(25),
          borderRadius: AppShapes.large,
          border: Border.all(
            color: Color(priority.colorValue).withAlpha(76),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priority.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              priority.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(priority.colorValue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show bottom sheet for priority selection
  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppShapes.topLarge,
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Download Priority',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...DownloadPriority.values.map((p) => _buildPriorityOption(
              context,
              p,
              isSelected: p == priority,
            )),
          ],
        ),
      ),
    );
  }

  /// Build individual priority option in bottom sheet
  Widget _buildPriorityOption(
    BuildContext context,
    DownloadPriority p,
    {required bool isSelected}
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(p.colorValue).withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(p.colorValue).withAlpha(76),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            p.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        p.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Color(p.colorValue) : null,
        ),
      ),
      subtitle: Text(
        p.description,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Color(p.colorValue))
          : null,
      onTap: () {
        onChanged(p);
        Navigator.pop(context);
      },
    );
  }
}

/// Simple priority badge (read-only, no interaction)
class PriorityBadge extends StatelessWidget {
  final DownloadPriority priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Color(priority.colorValue).withAlpha(25),
        borderRadius: AppShapes.medium,
        border: Border.all(
          color: Color(priority.colorValue).withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            priority.icon,
            style: const TextStyle(fontSize: 12),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              priority.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(priority.colorValue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
