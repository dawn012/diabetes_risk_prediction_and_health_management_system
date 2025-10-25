import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../../utils/helpers/media_helper.dart';
import '../../../controllers/post_controller.dart';
import 'video_player_widget.dart';

class MediaGalleryViewer extends StatefulWidget {
  const MediaGalleryViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
  });

  final List<String> mediaUrls;
  final int initialIndex;

  @override
  State<MediaGalleryViewer> createState() => _MediaGalleryViewerState();
}

class _MediaGalleryViewerState extends State<MediaGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final postController = PostController.instance;

  // 视频控制器缓存
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 预加载当前和相邻的视频
    _preloadVideos(_currentIndex);
  }

  void _preloadVideos(int currentIndex) {
    // 预加载当前、前一个和后一个视频
    final indicesToPreload = [
      currentIndex,
      if (currentIndex > 0) currentIndex - 1,
      if (currentIndex < widget.mediaUrls.length - 1) currentIndex + 1,
    ];

    for (final index in indicesToPreload) {
      final mediaUrl = widget.mediaUrls[index];
      if (MediaUtils.getMediaType(mediaUrl) == 'video' &&
          !_videoControllers.containsKey(index)) {
        _initializeVideo(index, mediaUrl);
      }
    }
  }

  void _initializeVideo(int index, String videoUrl) {
    if (_videoControllers.containsKey(index)) return;

    print('🎬 Pre-loading video at index $index');

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;
    _videoInitialized[index] = false;

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _videoInitialized[index] = true;
      });
      print('✅ Video at index $index initialized');

      // 如果是当前显示的视频，自动播放
      if (index == _currentIndex) {
        controller.play();
      }
    }).catchError((error) {
      print('❌ Video at index $index failed to load: $error');
    });
  }

  void _onPageChanged(int index) {
    // 暂停之前的视频
    final prevController = _videoControllers[_currentIndex];
    if (prevController != null && prevController.value.isPlaying) {
      prevController.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    // 播放当前视频
    final currentController = _videoControllers[index];
    if (currentController != null && _videoInitialized[index] == true) {
      currentController.play();
    }

    // 预加载相邻视频
    _preloadVideos(index);
  }

  @override
  void dispose() {
    _pageController.dispose();

    // 清理所有视频控制器
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();

    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.mediaUrls.length,
            itemBuilder: (context, index) {
              final mediaUrl = widget.mediaUrls[index];
              final isVideo = MediaUtils.getMediaType(mediaUrl) == 'video';

              return Center(
                child: isVideo
                    ? _buildCachedVideoPlayer(index, mediaUrl)
                    : InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    mediaUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${_currentIndex + 1} of ${widget.mediaUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: const Icon(
                          Icons.share,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom indicator dots
          if (widget.mediaUrls.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.mediaUrls.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCachedVideoPlayer(int index, String videoUrl) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;

    if (controller == null || !isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return VideoPlayerWidget(
      videoUrl: videoUrl,
      autoPlay: index == _currentIndex,
      showControls: true,
      controller: controller, // 传入已初始化的控制器
    );
  }
}