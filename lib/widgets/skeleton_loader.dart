import 'package:flutter/material.dart';

/// Skeleton loader widget for MD3-compliant loading states
///
/// Displays animated shimmer placeholders while content is loading.
/// Follows Material Design 3 specifications for loading states.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Skeleton for a single line of text
  factory SkeletonLoader.text({
    Key? key,
    double? width,
    double height = 16,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Skeleton for a card
  factory SkeletonLoader.card({
    Key? key,
    double? width,
    double? height,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Skeleton for a circular avatar
  factory SkeletonLoader.circle({
    Key? key,
    required double size,
  }) {
    return SkeletonLoader(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerHigh,
                colorScheme.surfaceContainerHighest,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for archive result cards
class ArchiveResultCardSkeleton extends StatelessWidget {
  final bool isListLayout;

  const ArchiveResultCardSkeleton({
    super.key,
    this.isListLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    // Exclude from screen readers - just loading placeholders
    return ExcludeSemantics(
      child: isListLayout
          ? _buildListSkeleton(context)
          : _buildGridSkeleton(context),
    );
  }

  Widget _buildGridSkeleton(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          AspectRatio(
            aspectRatio: 4 / 3,
            child: SkeletonLoader.card(),
          ),

          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                SkeletonLoader.text(width: double.infinity),
                const SizedBox(height: 8),
                SkeletonLoader.text(width: 150),

                const SizedBox(height: 12),

                // Metadata chips
                Row(
                  children: [
                    SkeletonLoader.text(width: 60, height: 20),
                    const SizedBox(width: 8),
                    SkeletonLoader.text(width: 80, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          SizedBox(
            width: 120,
            height: 120,
            child: SkeletonLoader.card(),
          ),

          // Content skeleton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.text(width: double.infinity),
                  const SizedBox(height: 8),
                  SkeletonLoader.text(width: 120),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonLoader.text(width: 60, height: 20),
                      const SizedBox(width: 8),
                      SkeletonLoader.text(width: 80, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of skeleton loaders for search results
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ArchiveResultCardSkeleton(),
    );
  }
}

/// List of skeleton loaders for search results
class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          const ArchiveResultCardSkeleton(isListLayout: true),
    );
  }
}
