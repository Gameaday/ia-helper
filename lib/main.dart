import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/archive_service.dart';
import 'services/history_service.dart';
import 'services/background_download_service.dart';
import 'services/deep_link_service.dart';
import 'services/local_archive_storage.dart';
import 'services/download_scheduler.dart';
import 'providers/download_provider.dart';
import 'providers/bandwidth_manager_provider.dart';
import 'models/bandwidth_preset.dart';
import 'screens/home_screen.dart';
import 'screens/archive_detail_screen.dart';
import 'screens/download_screen.dart';
import 'screens/download_queue_screen.dart';
import 'screens/advanced_search_screen.dart';
import 'screens/saved_searches_screen.dart';
import 'screens/search_results_screen.dart';
import 'models/search_query.dart';
import 'widgets/onboarding_widget.dart';
import 'widgets/whats_new_dialog.dart';
import 'utils/theme.dart';
import 'utils/permission_utils.dart';
import 'utils/animation_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize download scheduler for queue management
  await DownloadScheduler().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const IAGetMobileApp());
}

class IAGetMobileApp extends StatelessWidget {
  const IAGetMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Bandwidth Manager - needs to be created first for global access
        ChangeNotifierProvider<BandwidthManagerProvider>(
          create: (_) => BandwidthManagerProvider()..initialize(BandwidthPreset.mb1),
          lazy: false, // Initialize eagerly to set up bandwidth limits
        ),
        // History service - needs to be created first
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService(),
          lazy: true,
        ),
        // Local archive storage - for managing downloaded archives
        ChangeNotifierProvider<LocalArchiveStorage>(
          create: (_) => LocalArchiveStorage(),
          lazy: false, // Initialize eagerly to load saved archives
        ),
        // Core services - lazy loaded to optimize startup time
        // ArchiveService depends on both HistoryService and LocalArchiveStorage
        ChangeNotifierProxyProvider2<
          HistoryService,
          LocalArchiveStorage,
          ArchiveService
        >(
          create: (context) => ArchiveService(
            historyService: context.read<HistoryService>(),
            localArchiveStorage: context.read<LocalArchiveStorage>(),
          ),
          update: (context, historyService, localArchiveStorage, previous) =>
              previous ??
              ArchiveService(
                historyService: historyService,
                localArchiveStorage: localArchiveStorage,
              ),
          lazy: true,
        ),
        // Download provider with bandwidth management
        ChangeNotifierProxyProvider<BandwidthManagerProvider, DownloadProvider>(
          create: (context) => DownloadProvider(
            bandwidthManager: context.read<BandwidthManagerProvider>(),
          ),
          update: (context, bandwidthManager, previous) =>
              previous ??
              DownloadProvider(
                bandwidthManager: bandwidthManager,
              ),
          lazy: true,
        ),
        // Background download service with archive storage integration
        ChangeNotifierProxyProvider<
          LocalArchiveStorage,
          BackgroundDownloadService
        >(
          create: (context) {
            final service = BackgroundDownloadService();
            service.setArchiveStorage(context.read<LocalArchiveStorage>());
            return service;
          },
          update: (context, archiveStorage, previous) {
            final service = previous ?? BackgroundDownloadService();
            service.setArchiveStorage(archiveStorage);
            return service;
          },
          lazy: true,
        ),
        Provider<DeepLinkService>(
          create: (_) => DeepLinkService(),
          dispose: (_, service) => service.dispose(),
          lazy: true,
        ),
      ],
      child: MaterialApp(
        title: 'Internet Archive Helper',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,

        // Clamp text scaling to prevent layout issues
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final scaleFactor = mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.2);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(scaleFactor),
            ),
            child: child!,
          );
        },

        // Navigation performance
        onGenerateRoute: (settings) {
          // Implement custom route generation with Material Design 3 transitions
          switch (settings.name) {
            case '/':
              return MD3PageTransitions.fadeThrough(
                page: const AppInitializer(),
                settings: settings,
              );
            case '/home':
              return MD3PageTransitions.fadeThrough(
                page: const HomeScreen(),
                settings: settings,
              );
            case ArchiveDetailScreen.routeName:
              return MD3PageTransitions.fadeThrough(
                page: const ArchiveDetailScreen(),
                settings: settings,
              );
            case DownloadScreen.routeName:
              return MD3PageTransitions.fadeThrough(
                page: const DownloadScreen(),
                settings: settings,
              );
            case DownloadQueueScreen.routeName:
              return MD3PageTransitions.fadeThrough(
                page: const DownloadQueueScreen(),
                settings: settings,
              );
            case AdvancedSearchScreen.routeName:
              return MD3PageTransitions.sharedAxis(
                page: const AdvancedSearchScreen(),
                settings: settings,
              );
            case SavedSearchesScreen.routeName:
              return MD3PageTransitions.sharedAxis(
                page: const SavedSearchesScreen(),
                settings: settings,
              );
            case SearchResultsScreen.routeName:
              // Pass SearchQuery through settings.arguments
              final args = settings.arguments as Map<String, dynamic>?;
              final query = args?['query'] as SearchQuery? ?? const SearchQuery();
              final title = args?['title'] as String?;
              return MD3PageTransitions.fadeThrough(
                page: SearchResultsScreen(
                  query: query,
                  title: title,
                ),
                settings: settings,
              );
            default:
              return MD3PageTransitions.fadeThrough(
                page: const AppInitializer(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

/// App initializer that handles onboarding flow
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _shouldShowOnboarding = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app with proper sequencing and error handling
  ///
  /// Startup sequence (optimized for fast app launch):
  /// 1. Check onboarding status (fast, local operation)
  /// 2. Show UI immediately (deferred service initialization)
  /// 3. Initialize services lazily on first access
  ///
  /// Services are now lazy-loaded through Provider, eliminating startup bottleneck.
  Future<void> _initializeApp() async {
    try {
      // Check onboarding status (fast, local check)
      await _checkOnboardingStatus();

      // Initialize critical services after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _initializeCriticalServices();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = 'Failed to initialize app: ${e.toString()}';
          _isLoading = false;
        });
      }
      debugPrint('App initialization error: $e');
    }
  }

  /// Initialize only critical services that need early setup
  Future<void> _initializeCriticalServices() async {
    if (!mounted) return;

    try {
      // Capture services before any await operations
      final archiveStorage = context.read<LocalArchiveStorage>();
      final bgService = context.read<BackgroundDownloadService>();
      final deepLinkService = context.read<DeepLinkService>();

      // Initialize LocalArchiveStorage first (loads saved archives)
      await archiveStorage.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Archive storage initialization timed out');
        },
      );

      // Initialize BackgroundDownloadService (needs early setup for notifications)

      await bgService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Background service initialization timed out');
        },
      );

      await deepLinkService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('DeepLink service initialization timed out');
        },
      );

      // Set up deep link handler
      deepLinkService.onArchiveLinkReceived = (identifier) {
        if (!mounted) return;

        final archiveService = context.read<ArchiveService>();
        
        // Fetch metadata first
        archiveService.fetchMetadata(identifier).then((_) {
          // After metadata is fetched successfully, navigate to detail screen
          if (!mounted) return;
          
          if (archiveService.currentMetadata != null && archiveService.error == null) {
            // Navigate to detail screen
            // Use pushReplacement if we're on home screen, otherwise push normally
            Navigator.of(context).push(
              MD3PageTransitions.fadeThrough(
                page: const ArchiveDetailScreen(),
                settings: const RouteSettings(name: ArchiveDetailScreen.routeName),
              ),
            );
          } else if (archiveService.error != null) {
            // Show error message if fetch failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load archive: ${archiveService.error}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    archiveService.fetchMetadata(identifier);
                  },
                ),
              ),
            );
          }
        }).catchError((error) {
          if (!mounted) return;
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open link: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      };

      // Request notification permissions (non-blocking)
      _requestNotificationPermissions();
      
      // Show What's New dialog if this is a new version
      _showWhatsNewIfNeeded();
    } catch (e) {
      // Log but don't block app startup for service initialization failures
      debugPrint('Service initialization error: $e');
    }
  }

  /// Show What's New dialog for new app versions (non-blocking)
  Future<void> _showWhatsNewIfNeeded() async {
    if (!mounted) return;
    
    try {
      // Check if What's New should be shown
      final shouldShow = await WhatsNewDialog.shouldShow();
      
      if (shouldShow && mounted) {
        // Wait a moment for the home screen to settle
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const WhatsNewDialog(),
          );
        }
      }
    } catch (e) {
      // Non-critical - just log and continue
      debugPrint('Failed to show What\'s New dialog: $e');
    }
  }

  /// Request notification permissions for download notifications (non-blocking)
  Future<void> _requestNotificationPermissions() async {
    try {
      // Check if already granted
      final hasPermission = await PermissionUtils.hasNotificationPermissions();
      if (hasPermission) return;

      // Request permission (will be silently skipped on older Android versions)
      await PermissionUtils.requestNotificationPermissions();
    } catch (e) {
      // Non-critical - just log and continue
      debugPrint('Failed to request notification permissions: $e');
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final shouldShow = await OnboardingWidget.shouldShowOnboarding().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false, // Default to not showing on timeout
      );

      if (mounted) {
        setState(() {
          _shouldShowOnboarding = shouldShow;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = false;
          _isLoading = false;
        });
      }
    }
  }

  void _completeOnboarding() {
    setState(() {
      _shouldShowOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if initialization failed
    if (_initializationError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, 
                size: 64, 
                color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _initializationError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializationError = null;
                    _isLoading = true;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Internet Archive Helper',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_shouldShowOnboarding) {
      return OnboardingWidget(onComplete: _completeOnboarding);
    }

    return const HomeScreen();
  }
}
