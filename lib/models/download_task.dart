import '../models/archive_metadata.dart';
import 'download_progress.dart';

/// Priority level for download scheduling
enum DownloadPriority {
  low,
  normal,
  high;

  String get displayName {
    switch (this) {
      case DownloadPriority.low:
        return 'Low';
      case DownloadPriority.normal:
        return 'Normal';
      case DownloadPriority.high:
        return 'High';
    }
  }
}

/// Network requirement for downloads
enum NetworkRequirement {
  any,
  wiFiOnly,
  unmetered;

  String get displayName {
    switch (this) {
      case NetworkRequirement.any:
        return 'Any Network';
      case NetworkRequirement.wiFiOnly:
        return 'Wi-Fi Only';
      case NetworkRequirement.unmetered:
        return 'Unmetered Only';
    }
  }
}

/// Download task with resume capability and scheduling
/// 
/// This model tracks all information needed for resumable downloads:
/// - Resume state (partial bytes, ETag validation)
/// - Scheduling (priority, network requirements, scheduled time)
/// - Progress tracking (status, retry count, timestamps)
/// - Archive metadata (for multi-file downloads)
class DownloadTask {
  /// Unique identifier for this download task
  final String id;

  /// Internet Archive identifier
  final String identifier;

  /// Direct download URL
  final String url;

  /// Full path where file will be saved
  final String savePath;

  /// File name (extracted from savePath)
  final String fileName;

  // Resume state

  /// Number of bytes already downloaded (for HTTP Range resume)
  final int partialBytes;

  /// ETag from server (for resume validation)
  final String? etag;

  /// Last-Modified header from server
  final String? lastModified;

  /// Total file size in bytes
  final int totalBytes;

  // Scheduling

  /// Download priority (affects queue order)
  final DownloadPriority priority;

  /// Network requirement for download
  final NetworkRequirement networkRequirement;

  /// Schedule download to start at specific time (null = start immediately)
  final DateTime? scheduledTime;

  // Metadata

  /// When task was created
  final DateTime createdAt;

  /// When download actually started (null if not started)
  final DateTime? startedAt;

  /// When download completed (null if not completed)
  final DateTime? completedAt;

  /// Number of retry attempts
  final int retryCount;

  /// Error message if status is error
  final String? errorMessage;

  /// Current download status
  final DownloadStatus status;

  // Archive-specific

  /// Archive metadata (for multi-file downloads)
  final ArchiveMetadata? metadata;

  /// Selected files from archive (null = all files)
  final List<String>? selectedFiles;

  DownloadTask({
    required this.id,
    required this.identifier,
    required this.url,
    required this.savePath,
    required this.fileName,
    this.partialBytes = 0,
    this.etag,
    this.lastModified,
    required this.totalBytes,
    this.priority = DownloadPriority.normal,
    this.networkRequirement = NetworkRequirement.any,
    this.scheduledTime,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.retryCount = 0,
    this.errorMessage,
    this.status = DownloadStatus.queued,
    this.metadata,
    this.selectedFiles,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate download progress (0.0 to 1.0)
  double get progress {
    if (totalBytes == 0) return 0.0;
    return partialBytes / totalBytes;
  }

  /// Calculate progress percentage (0 to 100)
  double get progressPercentage => progress * 100;

  /// Check if download is eligible to start based on scheduled time
  bool get isEligible {
    if (scheduledTime == null) return true;
    return DateTime.now().isAfter(scheduledTime!);
  }

  /// Check if download is active (downloading or paused)
  bool get isActive {
    return status == DownloadStatus.downloading || status == DownloadStatus.paused;
  }

  /// Check if download is completed
  bool get isCompleted => status == DownloadStatus.completed;

  /// Check if download has error
  bool get hasError => status == DownloadStatus.error;

  /// Check if download can be resumed
  bool get canResume {
    return (status == DownloadStatus.paused || status == DownloadStatus.error) &&
        partialBytes > 0 &&
        partialBytes < totalBytes;
  }

  /// Create a copy with updated fields
  DownloadTask copyWith({
    String? id,
    String? identifier,
    String? url,
    String? savePath,
    String? fileName,
    int? partialBytes,
    String? etag,
    String? lastModified,
    int? totalBytes,
    DownloadPriority? priority,
    NetworkRequirement? networkRequirement,
    DateTime? scheduledTime,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? retryCount,
    String? errorMessage,
    DownloadStatus? status,
    ArchiveMetadata? metadata,
    List<String>? selectedFiles,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      fileName: fileName ?? this.fileName,
      partialBytes: partialBytes ?? this.partialBytes,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      totalBytes: totalBytes ?? this.totalBytes,
      priority: priority ?? this.priority,
      networkRequirement: networkRequirement ?? this.networkRequirement,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'url': url,
      'save_path': savePath,
      'file_name': fileName,
      'partial_bytes': partialBytes,
      'etag': etag,
      'last_modified': lastModified,
      'total_bytes': totalBytes,
      'priority': priority.name,
      'network_requirement': networkRequirement.name,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'retry_count': retryCount,
      'error_message': errorMessage,
      'status': status.name,
      'metadata': metadata?.toJson(),
      'selected_files': selectedFiles?.join(','),
    };
  }

  /// Create from JSON (database row)
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      url: json['url'] as String,
      savePath: json['save_path'] as String,
      fileName: json['file_name'] as String,
      partialBytes: json['partial_bytes'] as int? ?? 0,
      etag: json['etag'] as String?,
      lastModified: json['last_modified'] as String?,
      totalBytes: json['total_bytes'] as int,
      priority: DownloadPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => DownloadPriority.normal,
      ),
      networkRequirement: NetworkRequirement.values.firstWhere(
        (e) => e.name == json['network_requirement'],
        orElse: () => NetworkRequirement.any,
      ),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      metadata: json['metadata'] != null
          ? ArchiveMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      selectedFiles: json['selected_files'] != null
          ? (json['selected_files'] as String).split(',')
          : null,
    );
  }

  @override
  String toString() {
    return 'DownloadTask(id: $id, fileName: $fileName, progress: ${progressPercentage.toStringAsFixed(1)}%, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
