import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/favorite.dart';
import '../services/favorites_service.dart';
import '../utils/animation_constants.dart';

/// Material Design 3 compliant favorite button widget
///
/// Displays a star icon that toggles between outlined and filled states.
/// Uses MD3 emphasized animations for visual feedback.
///
/// Features:
/// - Smooth scale and rotation animations on toggle
/// - Proper theme-based coloring (primary color for favorited)
/// - Haptic feedback on toggle
/// - Async state management with loading indicator
/// - Accessible with semantic labels
class FavoriteButton extends StatefulWidget {
  /// The archive identifier to favorite/unfavorite
  final String identifier;

  /// Optional title for the favorite
  final String? title;

  /// Optional mediatype for the favorite
  final String? mediatype;

  /// Optional metadata to store with the favorite
  final Map<String, dynamic>? metadataJson;

  /// Icon size (default: 24.0)
  final double iconSize;

  /// Callback when favorite status changes
  final ValueChanged<bool>? onFavoriteChanged;

  /// Whether to show loading indicator during async operations
  final bool showLoadingIndicator;

  const FavoriteButton({
    super.key,
    required this.identifier,
    this.title,
    this.mediatype,
    this.metadataJson,
    this.iconSize = 24.0,
    this.onFavoriteChanged,
    this.showLoadingIndicator = true,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;

  bool _isFavorited = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFavoriteStatus();
  }

  void _initializeAnimations() {
    // MD3 Emphasized curve for expressive, distinctive motion
    _animationController = AnimationController(
      duration: MD3Durations.medium, // 200ms - standard for state changes
      vsync: this,
    );

    // Scale animation: slightly overshoot then settle
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: MD3Curves.emphasized)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: MD3Curves.emphasized)),
        weight: 50,
      ),
    ]).animate(_animationController);

    // Subtle rotation for added expressiveness (15 degrees)
    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.26, // ~15 degrees in radians
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: MD3Curves.emphasized,
          ),
        );
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorited = await _favoritesService.isFavorited(widget.identifier);
    if (mounted) {
      setState(() {
        _isFavorited = isFavorited;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favorite = Favorite(
        identifier: widget.identifier,
        title: widget.title,
        mediatype: widget.mediatype,
        addedAt: DateTime.now(),
        metadataJson: widget.metadataJson,
      );

      final newStatus = await _favoritesService.toggleFavorite(favorite);

      if (mounted) {
        setState(() {
          _isFavorited = newStatus;
          _isLoading = false;
        });

        // Trigger animation
        _animationController.forward(from: 0.0);

        // Provide haptic feedback
        HapticFeedback.lightImpact();

        // Notify callback
        widget.onFavoriteChanged?.call(newStatus);

        // Show feedback snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus ? 'Added to favorites' : 'Removed from favorites',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              width: 200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // MD3 small shape
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use primary color for favorited, onSurfaceVariant for not favorited
    final iconColor = _isFavorited
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      label: _isFavorited ? 'Remove from favorites' : 'Add to favorites',
      button: true,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: IconButton(
                icon: _isLoading && widget.showLoadingIndicator
                    ? SizedBox(
                        width: widget.iconSize,
                        height: widget.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : Icon(
                        _isFavorited ? Icons.star : Icons.star_border,
                        size: widget.iconSize,
                        color: iconColor,
                      ),
                onPressed: _isLoading ? null : _toggleFavorite,
                tooltip: _isFavorited
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                // MD3 standard state layer
                splashRadius: widget.iconSize + 8,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact version of FavoriteButton without padding (for tight spaces)
class FavoriteIconButton extends StatelessWidget {
  /// The archive identifier to favorite/unfavorite
  final String identifier;

  /// Optional title for the favorite
  final String? title;

  /// Optional mediatype for the favorite
  final String? mediatype;

  /// Optional metadata to store with the favorite
  final Map<String, dynamic>? metadataJson;

  /// Icon size (default: 20.0 for compact)
  final double iconSize;

  /// Callback when favorite status changes
  final ValueChanged<bool>? onFavoriteChanged;

  const FavoriteIconButton({
    super.key,
    required this.identifier,
    this.title,
    this.mediatype,
    this.metadataJson,
    this.iconSize = 20.0,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FavoriteButton(
      identifier: identifier,
      title: title,
      mediatype: mediatype,
      metadataJson: metadataJson,
      iconSize: iconSize,
      onFavoriteChanged: onFavoriteChanged,
      showLoadingIndicator: false, // No loading indicator in compact mode
    );
  }
}
