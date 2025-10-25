import 'dart:io';

class PostMediaItem {
  final String id;
  final File? file;  // 可空，因为下载可能失败
  final String type; // 'image' or 'video'
  final File? thumbnail; // For video thumbnails
  final Duration? duration; // For videos
  final bool isProcessing;
  final String? error;
  final String? existingUrl; // For editing existing posts
  final bool isDownloaded; // 标记是否已下载

  const PostMediaItem({
    required this.id,
    this.file,
    required this.type,
    this.thumbnail,
    this.duration,
    this.isProcessing = false,
    this.error,
    this.existingUrl,
    this.isDownloaded = false, // 默认未下载
  });

  /// Check if this is an image
  bool get isImage => type == 'image';

  /// Check if this is a video
  bool get isVideo => type == 'video';

  /// Check if there's an error
  bool get hasError => error != null;

  /// Check if processing is complete
  bool get isReady => !isProcessing && !hasError && file != null;

  /// Check if this is an existing media item (from editing)
  bool get isExisting => existingUrl != null;

  /// Check if file is available locally
  bool get hasLocalFile => file != null && file!.existsSync();

  /// Check if successfully downloaded (for existing items)
  bool get isDownloadedSuccessfully => isExisting && isDownloaded && hasLocalFile;

  /// Check if download failed
  bool get isDownloadFailed => isExisting && !isDownloaded && hasError;

  /// Check if currently downloading
  bool get isDownloading => isExisting && isProcessing;

  /// Get display thumbnail (for videos, use thumbnail; for images, use the file itself)
  File? get displayThumbnail {
    if (thumbnail != null) return thumbnail;
    if (file != null && file!.existsSync()) return file;
    return null;
  }

  String? get displayUrl => existingUrl;

  /// Create a copy with updated fields
  PostMediaItem copyWith({
    String? id,
    File? file,
    String? type,
    File? thumbnail,
    Duration? duration,
    bool? isProcessing,
    String? error,
    String? existingUrl,
    bool? isDownloaded,
  }) {
    return PostMediaItem(
      id: id ?? this.id,
      file: file ?? this.file,
      type: type ?? this.type,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      existingUrl: existingUrl ?? this.existingUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  /// Get file size in MB
  double get fileSizeMB {
    try {
      if (file != null && file!.existsSync()) {
        return file!.lengthSync() / (1024 * 1024);
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get formatted file size
  String get formattedFileSize {
    final sizeMB = fileSizeMB;
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeMB.toStringAsFixed(1)} MB';
  }

  /// Get formatted duration for videos
  String get formattedDuration {
    if (duration == null) return '';

    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  String toString() {
    return 'PostMediaItem{id: $id, type: $type, isProcessing: $isProcessing, hasError: $hasError, isExisting: $isExisting, isDownloaded: $isDownloaded}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostMediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}