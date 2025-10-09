import 'package:flutter/material.dart';
import '../services/ia_health_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/snackbar_helper.dart';
import 'dart:async';

/// Internet Archive Health Status Screen
///
/// Displays real-time health and availability information for Internet Archive
/// services, helping users diagnose connection issues and understand service status.
class IAHealthScreen extends StatefulWidget {
  const IAHealthScreen({super.key});

  static const String routeName = '/ia-health';

  @override
  State<IAHealthScreen> createState() => _IAHealthScreenState();
}

class _IAHealthScreenState extends State<IAHealthScreen> {
  bool _isLoading = true;
  IAHealthStatus? _mainStatus;
  List<IAEndpointStatus> _endpoints = [];
  DateTime? _lastChecked;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        IAHealthService.checkMainSite(),
        IAHealthService.checkAllEndpoints(),
      ]);

      if (mounted) {
        setState(() {
          _mainStatus = results[0] as IAHealthStatus;
          _endpoints = results[1] as List<IAEndpointStatus>;
          _lastChecked = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _checkHealth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(context),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildOverallStatus(context),
            const SizedBox(height: 24),
            _buildSectionHeader('Service Endpoints'),
            const SizedBox(height: 12),
            ..._endpoints.map(
              (endpoint) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEndpointCard(context, endpoint),
              ),
            ),
            const SizedBox(height: 24),
            _buildLastChecked(context),
            const SizedBox(height: 16),
            _buildStatusLegend(context),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Service Status'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Status',
              onPressed: _checkHealth,
            ),
        ],
      ),
      body: ResponsiveUtils.isTabletOrLarger(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Health Monitor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check Internet Archive service availability and response times. Pull down to refresh.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus(BuildContext context) {
    if (_mainStatus == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final status = _mainStatus!;
    final isHealthy = status.isHealthy;

    return Card(
      color: isHealthy
          ? colorScheme.primaryContainer
          : colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              size: 64,
              color: isHealthy
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              status.isAvailable
                  ? 'Internet Archive is Online'
                  : 'Service Unavailable',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isHealthy
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              status.statusText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isHealthy
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            if (status.responseTimeMs != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: isHealthy
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${status.responseTimeMs}ms response time',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isHealthy
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ],
            if (status.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                'Error: ${status.errorMessage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointCard(BuildContext context, IAEndpointStatus endpoint) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHealthy = endpoint.isHealthy;

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isHealthy
                ? colorScheme.primaryContainer
                : colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy
                ? colorScheme.onPrimaryContainer
                : colorScheme.onErrorContainer,
          ),
        ),
        title: Text(
          endpoint.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              endpoint.isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (endpoint.responseTimeMs != null) ...[
              const SizedBox(height: 2),
              Text('Response: ${endpoint.responseTimeMs}ms'),
            ],
            if (endpoint.errorMessage != null) ...[
              const SizedBox(height: 2),
              Text(
                'Error: ${endpoint.errorMessage}',
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: endpoint.responseTimeMs != null
            ? _buildResponseTimeBadge(context, endpoint.responseTimeMs!)
            : null,
      ),
    );
  }

  Widget _buildResponseTimeBadge(BuildContext context, int responseTimeMs) {
    Color badgeColor;
    String label;

    if (responseTimeMs < 1000) {
      badgeColor = Colors.green;
      label = 'Fast';
    } else if (responseTimeMs < 3000) {
      badgeColor = Colors.orange;
      label = 'OK';
    } else {
      badgeColor = Colors.red;
      label = 'Slow';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLastChecked(BuildContext context) {
    if (_lastChecked == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final diff = now.difference(_lastChecked!);
    String timeAgo;

    if (diff.inSeconds < 60) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else {
      timeAgo = '${diff.inHours}h ago';
    }

    return Center(
      child: Text(
        'Last checked: $timeAgo',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatusLegend(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Response Time Guide',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLegendRow(context, 'Fast', '< 1 second', Colors.green),
            const SizedBox(height: 8),
            _buildLegendRow(context, 'OK', '1-3 seconds', Colors.orange),
            const SizedBox(height: 8),
            _buildLegendRow(context, 'Slow', '> 3 seconds', Colors.red),
            const SizedBox(height: 12),
            Text(
              'Note: Response times may vary based on your network connection and Internet Archive server load.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(
    BuildContext context,
    String label,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
