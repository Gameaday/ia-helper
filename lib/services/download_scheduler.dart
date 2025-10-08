import 'dart:async';
import 'dart:collection';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/download_task.dart';
import '../models/download_progress.dart';
import '../database/database_helper.dart';
import 'resumable_download_service.dart';

/// Scheduler for managing download queue with priority, network awareness, and time-based scheduling
///
/// Features:
/// - Priority-based queue management (high → normal → low)
/// - Network-aware scheduling (Wi-Fi only, unmetered, any)
/// - Time-based scheduling (scheduled downloads)
/// - Concurrent download management (configurable max)
/// - Auto-retry with exponential backoff
/// - Bandwidth distribution across active downloads
class DownloadScheduler {
  static final DownloadScheduler _instance = DownloadScheduler._internal();
  factory DownloadScheduler() => _instance;
  DownloadScheduler._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();
  late final ResumableDownloadService _downloadService;

  // Configuration
  int maxConcurrentDownloads = 3;
  int maxRetryAttempts = 5;
  Duration schedulerTickInterval = const Duration(seconds: 5);

  // State
  final Map<String, DownloadTask> _activeDownloads = {};
  final Queue<DownloadTask> _queue = Queue();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _schedulerTimer;
  bool _isRunning = false;
  List<ConnectivityResult> _currentConnectivity = [];

  // Streams for updates
  final StreamController<DownloadSchedulerState> _stateController =
      StreamController<DownloadSchedulerState>.broadcast();
  final StreamController<Map<String, DownloadProgress>> _progressController =
      StreamController<Map<String, DownloadProgress>>.broadcast();

  Stream<DownloadSchedulerState> get stateStream => _stateController.stream;
  Stream<Map<String, DownloadProgress>> get progressStream =>
      _progressController.stream;

  /// Initialize the scheduler
  Future<void> initialize() async {
    if (_isRunning) return;

    // Initialize download service with callbacks
    _downloadService = ResumableDownloadService(
      onProgress: _handleProgressUpdate,
      onComplete: _handleDownloadComplete,
      onError: _handleDownloadError,
    );

    // Load queued and paused tasks from database
    await _loadPendingTasks();

    // Monitor network connectivity
    _currentConnectivity = await _connectivity.checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Start scheduler timer
    _schedulerTimer = Timer.periodic(schedulerTickInterval, (_) => _tick());

    _isRunning = true;
    _emitState();
  }

  /// Stop the scheduler
  Future<void> dispose() async {
    _isRunning = false;
    await _connectivitySubscription?.cancel();
    _schedulerTimer?.cancel();
    await _stateController.close();
    await _progressController.close();

    // Pause all active downloads
    for (final taskId in _activeDownloads.keys.toList()) {
      await _downloadService.pauseDownload(taskId);
    }
  }

  /// Add a task to the queue
  Future<void> enqueueTask(DownloadTask task) async {
    // Save to database
    await _db.upsertDownloadTask(task.copyWith(status: DownloadStatus.queued));

    // Add to queue and sort by priority
    _queue.add(task);
    _sortQueue();

    _emitState();

    // Try to start immediately if possible
    await _tick();
  }

  /// Remove a task from the queue
  Future<void> removeTask(String taskId) async {
    // Cancel if active
    if (_activeDownloads.containsKey(taskId)) {
      await _downloadService.cancelDownload(taskId, deletePartialFile: false);
      _activeDownloads.remove(taskId);
    }

    // Remove from queue
    _queue.removeWhere((task) => task.id == taskId);

    // Delete from database
    await _db.deleteDownloadTask(taskId);

    _emitState();
  }

  /// Pause a specific task
  Future<void> pauseTask(String taskId) async {
    if (_activeDownloads.containsKey(taskId)) {
      await _downloadService.pauseDownload(taskId);
      final task = _activeDownloads.remove(taskId);
      if (task != null) {
        _queue.addFirst(task.copyWith(status: DownloadStatus.paused));
        await _db.updateDownloadTask(
          task.copyWith(status: DownloadStatus.paused),
        );
      }
    }
    _emitState();
  }

  /// Resume a specific task
  Future<void> resumeTask(String taskId) async {
    // Find task in queue or database
    DownloadTask? task = _queue.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    // Update status and re-add to queue
    task = task.copyWith(status: DownloadStatus.queued);
    await _db.updateDownloadTask(task);

    _queue.removeWhere((t) => t.id == taskId);
    _queue.add(task);
    _sortQueue();

    _emitState();
    await _tick();
  }

  /// Pause all active downloads
  Future<void> pauseAll() async {
    for (final taskId in _activeDownloads.keys.toList()) {
      await pauseTask(taskId);
    }
  }

  /// Resume all paused downloads
  Future<void> resumeAll() async {
    final pausedTasks = await _db.getDownloadTasks(
      status: DownloadStatus.paused,
    );

    for (final task in pausedTasks) {
      _queue.add(task.copyWith(status: DownloadStatus.queued));
      await _db.updateDownloadTask(
        task.copyWith(status: DownloadStatus.queued),
      );
    }

    _sortQueue();
    _emitState();
    await _tick();
  }

  /// Update task priority
  Future<void> updateTaskPriority(
    String taskId,
    DownloadPriority priority,
  ) async {
    // Update in queue
    final taskIndex = _queue.toList().indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final tasks = _queue.toList();
      final task = tasks[taskIndex].copyWith(priority: priority);
      tasks[taskIndex] = task;

      _queue.clear();
      _queue.addAll(tasks);
      _sortQueue();

      await _db.updateDownloadTask(task);
      _emitState();
    }
  }

  // Private methods

  Future<void> _loadPendingTasks() async {
    final tasks = await _db.getDownloadTasks();

    for (final task in tasks) {
      if (task.status == DownloadStatus.queued ||
          task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.error &&
              task.retryCount < maxRetryAttempts) {
        _queue.add(task);
      }
    }

    _sortQueue();
  }

  void _sortQueue() {
    final tasks = _queue.toList();

    // Sort by: priority (high→low), scheduled time (earliest first), created time
    tasks.sort((a, b) {
      // Priority comparison (high=2, normal=1, low=0)
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;

      // Scheduled time comparison
      if (a.scheduledTime != null && b.scheduledTime != null) {
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      }
      if (a.scheduledTime != null) return -1;
      if (b.scheduledTime != null) return 1;

      // Created time comparison
      return a.createdAt.compareTo(b.createdAt);
    });

    _queue.clear();
    _queue.addAll(tasks);
  }

  Future<void> _tick() async {
    if (!_isRunning) return;

    // Start new downloads if we have capacity
    while (_activeDownloads.length < maxConcurrentDownloads &&
        _queue.isNotEmpty) {
      final task = _queue.first;

      // Check if task is ready to start
      if (!_isTaskReady(task)) {
        // Move to end of queue if not ready
        _queue.removeFirst();
        _queue.addLast(task);
        continue;
      }

      // Check network requirements
      if (!_isNetworkSuitable(task)) {
        break; // Don't start any more tasks if network unsuitable
      }

      // Remove from queue and start download
      _queue.removeFirst();
      _activeDownloads[task.id] = task;

      // Start download (fire and forget, callbacks will handle completion)
      _startDownload(task);
    }

    _emitState();
  }

  bool _isTaskReady(DownloadTask task) {
    // Check if scheduled time has arrived
    if (task.scheduledTime != null) {
      if (DateTime.now().isBefore(task.scheduledTime!)) {
        return false;
      }
    }

    // Check retry backoff
    if (task.status == DownloadStatus.error) {
      if (task.retryCount >= maxRetryAttempts) {
        return false;
      }

      // Exponential backoff: 2^retryCount seconds
      final backoffSeconds = 2 << task.retryCount.clamp(0, 5);
      final nextRetry = task.startedAt?.add(Duration(seconds: backoffSeconds));
      if (nextRetry != null && DateTime.now().isBefore(nextRetry)) {
        return false;
      }
    }

    return true;
  }

  bool _isNetworkSuitable(DownloadTask task) {
    if (_currentConnectivity.isEmpty ||
        _currentConnectivity.contains(ConnectivityResult.none)) {
      return false;
    }

    switch (task.networkRequirement) {
      case NetworkRequirement.any:
        return true;

      case NetworkRequirement.wiFiOnly:
        return _currentConnectivity.contains(ConnectivityResult.wifi) ||
            _currentConnectivity.contains(ConnectivityResult.ethernet);

      case NetworkRequirement.unmetered:
        // WiFi and Ethernet are typically unmetered
        return _currentConnectivity.contains(ConnectivityResult.wifi) ||
            _currentConnectivity.contains(ConnectivityResult.ethernet);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    try {
      final updatedTask = task.copyWith(
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      );
      await _db.updateDownloadTask(updatedTask);

      // Start download (callbacks will handle completion)
      _downloadService.downloadTask(updatedTask);
    } catch (e) {
      _handleDownloadError(task.id, e.toString());
    }
  }

  void _handleProgressUpdate(String taskId, DownloadProgress progress) {
    // Update progress map and emit
    final allProgress = Map<String, DownloadProgress>.from(
      _activeDownloads.map((id, task) => MapEntry(id, progress)),
    );
    _progressController.add(allProgress);
  }

  void _handleDownloadComplete(String taskId, DownloadTask task) {
    _activeDownloads.remove(taskId);
    _emitState();

    // Start next download
    _tick();
  }

  void _handleDownloadError(String taskId, String error) async {
    final task = _activeDownloads.remove(taskId);
    if (task == null) return;

    // Increment retry count
    final updatedTask = task.copyWith(
      status: DownloadStatus.error,
      retryCount: task.retryCount + 1,
      errorMessage: error,
    );

    await _db.updateDownloadTask(updatedTask);

    // Re-queue if under retry limit
    if (updatedTask.retryCount < maxRetryAttempts) {
      _queue.add(updatedTask);
      _sortQueue();
    }

    _emitState();

    // Start next download
    await _tick();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _currentConnectivity = results;

    // Pause active downloads if network becomes unsuitable
    for (final task in _activeDownloads.values.toList()) {
      if (!_isNetworkSuitable(task)) {
        pauseTask(task.id);
      }
    }

    // Try to start downloads if network becomes suitable
    _tick();
  }

  void _emitState() {
    _stateController.add(
      DownloadSchedulerState(
        queuedTasks: _queue.length,
        activeTasks: _activeDownloads.length,
        maxConcurrent: maxConcurrentDownloads,
        isNetworkSuitable:
            _currentConnectivity.isNotEmpty &&
            !_currentConnectivity.contains(ConnectivityResult.none),
        connectivity: _currentConnectivity,
      ),
    );
  }
}

/// State of the download scheduler
class DownloadSchedulerState {
  final int queuedTasks;
  final int activeTasks;
  final int maxConcurrent;
  final bool isNetworkSuitable;
  final List<ConnectivityResult> connectivity;

  DownloadSchedulerState({
    required this.queuedTasks,
    required this.activeTasks,
    required this.maxConcurrent,
    required this.isNetworkSuitable,
    required this.connectivity,
  });

  bool get hasCapacity => activeTasks < maxConcurrent;
  bool get isIdle => queuedTasks == 0 && activeTasks == 0;
  bool get isActive => activeTasks > 0;

  String get connectivityDescription {
    if (connectivity.isEmpty ||
        connectivity.contains(ConnectivityResult.none)) {
      return 'No connection';
    }
    if (connectivity.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    }
    if (connectivity.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    }
    if (connectivity.contains(ConnectivityResult.mobile)) {
      return 'Mobile data';
    }
    return 'Connected';
  }
}
