import 'dart:io';

class PostMediaItem {
  final String id;
  final File file;
  final String type; // 'image' or 'video'
  final File? thumbnail; // For video thumbnails
  final Duration? duration; // For videos
  final bool isProcessing;
  final String? error;
  final String? existingUrl; // For editing existing posts

  const PostMediaItem({
    required this.id,
    required this.file,
    required this.type,
    this.thumbnail,
    this.duration,
    this.isProcessing = false,
    this.error,
    this.existingUrl,
  });

  /// Check if this is an image
  bool get isImage => type == 'image';

  /// Check if this is a video
  bool get isVideo => type == 'video';

  /// Check if there's an error
  bool get hasError => error != null;

  /// Check if processing is complete
  bool get isReady => !isProcessing && !hasError;

  /// Get display thumbnail (for videos, use thumbnail; for images, use the file itself)
  File get displayThumbnail => thumbnail ?? file;

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
    );
  }

  /// Get file size in MB
  double get fileSizeMB {
    try {
      return file.lengthSync() / (1024 * 1024);
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
    return 'PostMediaItem{id: $id, type: $type, isProcessing: $isProcessing, hasError: $hasError}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostMediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}