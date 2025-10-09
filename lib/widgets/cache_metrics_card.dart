import 'package:flutter/material.dart';
import '../services/identifier_verification_service.dart';

/// Widget to display identifier cache statistics and metrics
///
/// Shows cache performance, API call savings, and normalization success rates
class CacheMetricsCard extends StatelessWidget {
  const CacheMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = IdentifierVerificationService.instance;
    final metrics = service.metrics;
    final stats = service.getCacheStats();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Cache Performance', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (metrics.totalVerifications > 0)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset metrics',
                    onPressed: () {
                      service.resetMetrics();
                      // Force rebuild
                      (context as Element).markNeedsBuild();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Main metrics
            _buildMetricRow(
              context,
              icon: Icons.check_circle_outline,
              label: 'Cache Hit Rate',
              value: stats['hitRate'] as String,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              context,
              icon: Icons.cloud_off,
              label: 'API Calls Saved',
              value:
                  '${metrics.apiCallsSaved} / ${metrics.apiCallsSaved + metrics.apiCallsMade}',
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              context,
              icon: Icons.trending_down,
              label: 'API Reduction',
              value: stats['apiReduction'] as String,
              color: Colors.orange,
            ),

            if (metrics.totalSuccesses > 0) ...[
              const Divider(height: 24),
              Text('Normalization Strategy', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),

              // Normalization success rates
              _buildMetricRow(
                context,
                icon: Icons.text_fields,
                label: 'Standard (Case Preserved)',
                value:
                    '${metrics.standardHits} (${stats['standardSuccessRate']})',
                color: Colors.purple,
                dense: true,
              ),
              const SizedBox(height: 4),
              _buildMetricRow(
                context,
                icon: Icons.text_format,
                label: 'Strict (Lowercase)',
                value: '${metrics.strictHits} (${stats['strictSuccessRate']})',
                color: Colors.teal,
                dense: true,
              ),
              const SizedBox(height: 4),
              _buildMetricRow(
                context,
                icon: Icons.auto_fix_high,
                label: 'Alternatives',
                value:
                    '${metrics.alternativeHits} (${stats['alternativeSuccessRate']})',
                color: Colors.amber,
                dense: true,
              ),
            ],

            if (metrics.totalVerifications == 0) ...[
              const SizedBox(height: 8),
              Text(
                'No searches yet. Start searching to see metrics!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat(
                    context,
                    label: 'Total Searches',
                    value: '${metrics.totalVerifications}',
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildSummaryStat(
                    context,
                    label: 'API Calls',
                    value: '${metrics.apiCallsMade}',
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildSummaryStat(
                    context,
                    label: 'Cache Size',
                    value: '${stats['size']}',
                  ),
                ],
              ),
            ),

            if (stats['size'] as int > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    service.clearCache();
                    service.resetMetrics();
                    // Force rebuild
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear Cache'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool dense = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: dense ? 16 : 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: dense
                ? theme.textTheme.bodySmall
                : theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style:
              (dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSummaryStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
