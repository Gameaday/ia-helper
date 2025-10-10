import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Safe wrapper for widgets that might throw errors during scrolling
/// 
/// Catches errors in child widgets and shows fallback UI instead of crashing.
/// Useful for wrapping list/grid items that load images or fetch data.
class SafeWidget extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final Widget? fallback;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const SafeWidget({
    super.key,
    required this.builder,
    this.fallback,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SafeWidget] Caught error: $error');
      }
      
      onError?.call(error, stackTrace);
      
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Safe image widget that handles errors gracefully
/// 
/// Wraps Image.network with comprehensive error handling for scrolling lists.
/// Prevents disposed widget errors and network failures from crashing the app.
class SafeNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext)? placeholder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  bool _hasError = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!, null);
    }

    if (_hasError) {
      return _buildDefaultPlaceholder(context, isError: true);
    }

    return Image.network(
      widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        if (widget.placeholder != null) {
          return widget.placeholder!(context);
        }

        return _buildDefaultPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        // Only update state if still mounted
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _error = error;
              });
            }
          });
        }

        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(context, error, stackTrace);
        }

        return _buildDefaultPlaceholder(context, isError: true);
      },
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.width,
      height: widget.height,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isError ? Icons.broken_image_outlined : Icons.image_outlined,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}
