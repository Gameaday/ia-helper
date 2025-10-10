import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding widget that helps new users understand Internet Archive Helper
class OnboardingWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingWidget({super.key, required this.onComplete});

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_OnboardingWidgetState._onboardingCompleteKey) ??
        false);
  }
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const String _onboardingCompleteKey = 'onboarding_complete';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    widget.onComplete();
  }

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.library_books_rounded,
      title: 'Welcome to Internet Archive Helper',
      description:
          'Your gateway to millions of free books, movies, music, software, and historical documents from the Internet Archive.',
      iconColor: Color(0xFF004B87),
    ),
    const OnboardingPage(
      icon: Icons.home_rounded,
      title: '🏠 Home - Your Search Hub',
      description:
          'Start here! Search by archive identifier or keywords. The intelligent search bar auto-detects what you\'re looking for.',
      iconColor: Color(0xFF1976D2),
      showBottomNavHighlight: true,
      highlightedTab: 0,
    ),
    const OnboardingPage(
      icon: Icons.folder_rounded,
      title: '📚 Library - Your Content',
      description:
          'Access your favorites, downloaded archives, and browsing history. Everything you\'ve saved in one place.',
      iconColor: Color(0xFF388E3C),
      showBottomNavHighlight: true,
      highlightedTab: 1,
    ),
    const OnboardingPage(
      icon: Icons.explore_rounded,
      title: '🔍 Discover - Browse & Explore',
      description:
          'Explore trending archives, browse by category, and discover featured collections. Perfect for finding new content.',
      iconColor: Color(0xFFFF6B35),
      showBottomNavHighlight: true,
      highlightedTab: 2,
    ),
    const OnboardingPage(
      icon: Icons.download_rounded,
      title: '⬇️ Transfers - Manage Downloads',
      description:
          'Track active downloads, pause/resume, and manage your download queue. Smart downloads with auto-retry.',
      iconColor: Color(0xFF0088CC),
      showBottomNavHighlight: true,
      highlightedTab: 3,
    ),
    const OnboardingPage(
      icon: Icons.more_horiz_rounded,
      title: '⚙️ More - Settings & About',
      description:
          'Customize your experience with bandwidth controls, storage settings, and more. Access help and app info.',
      iconColor: Color(0xFF757575),
      showBottomNavHighlight: true,
      highlightedTab: 4,
    ),
    const OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      title: 'Ready to Get Started!',
      description:
          'Tap the search bar on the Home screen to begin. Try searching for "nasa_images" or browse the Discover tab for inspiration.',
      iconColor: Color(0xFF6A1B9A),
      callToAction: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).primaryColor
                            : Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: _pages[index],
                  );
                },
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 64), // Placeholder for alignment
                  // Skip button (only on first pages)
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    ),

                  // Next/Get Started button
                  FilledButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
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
}

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final bool showBottomNavHighlight;
  final int highlightedTab;
  final bool callToAction;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    this.showBottomNavHighlight = false,
    this.highlightedTab = 0,
    this.callToAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon with background circle
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 80, color: iconColor),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        // Bottom navigation preview (if enabled)
        if (showBottomNavHighlight) ...[
          const SizedBox(height: 32),
          _buildBottomNavPreview(context),
        ],

        // Call to action card (for last page)
        if (callToAction) ...[
          const SizedBox(height: 32),
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Swipe up to begin your journey!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build a preview of the bottom navigation bar with highlighted tab
  Widget _buildBottomNavPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final tabs = [
      (Icons.home_rounded, 'Home'),
      (Icons.folder_rounded, 'Library'),
      (Icons.explore_rounded, 'Discover'),
      (Icons.download_rounded, 'Transfers'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabs.length, (index) {
          final (icon, label) = tabs[index];
          final isHighlighted = index == highlightedTab;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isHighlighted
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: isHighlighted ? 28 : 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isHighlighted
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: isHighlighted ? 13 : 11,
                  fontWeight:
                      isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
