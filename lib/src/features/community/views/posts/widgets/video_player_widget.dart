import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.controller, // 可选的外部控制器
  });

  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final VideoPlayerController? controller; // 外部传入的控制器

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _internalController;
  VideoPlayerController get _controller =>
      widget.controller ?? _internalController!;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0;
  bool _useExternalController = false;

  @override
  void initState() {
    super.initState();
    _useExternalController = widget.controller != null;

    if (_useExternalController) {
      // 使用外部控制器
      _setupExternalController();
    } else {
      // 创建内部控制器
      _initializeVideo();
    }
  }

  void _setupExternalController() {
    final controller = widget.controller!;

    if (controller.value.isInitialized) {
      setState(() {
        _isInitialized = true;
        _totalDuration = controller.value.duration.inMilliseconds.toDouble();
        _isPlaying = controller.value.isPlaying;
      });

      if (widget.autoPlay && !controller.value.isPlaying) {
        controller.play();
      }
    }

    controller.addListener(_videoListener);
  }

  void _initializeVideo() {
    print('🎬 Initializing video player for: ${widget.videoUrl}');

    _internalController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _internalController!.initialize().then((_) {
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _totalDuration = _internalController!.value.duration.inMilliseconds.toDouble();
      });

      print('✅ Video initialized successfully');
      print('   Duration: ${_formatDuration(_internalController!.value.duration)}');
      print('   Size: ${_internalController!.value.size}');

      if (widget.autoPlay) {
        _internalController!.play();
        setState(() => _isPlaying = true);
      }

      _internalController!.addListener(_videoListener);
    }).catchError((error) {
      print('❌ Video initialization failed: $error');
    });
  }

  void _videoListener() {
    if (!mounted) return;

    final isPlaying = _controller.value.isPlaying;
    final position = _controller.value.position.inMilliseconds.toDouble();

    if (isPlaying != _isPlaying || position != _currentPosition) {
      setState(() {
        _isPlaying = isPlaying;
        _currentPosition = position;
      });
    }

    // Auto hide controls after 3 seconds of playing
    if (_isPlaying && _showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _showControls = true;
      }
    });
  }

  void _toggleControls() {
    if (!widget.showControls) return;

    setState(() {
      _showControls = !_showControls;
    });
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: value.toInt());
    _controller.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    if (!_isInitialized) {
      return Container(
        color: isDark ? TColors.darkGrey : TColors.lightGrey,
        child: const Center(child: CircularLoader(message: 'Loading video...')),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Controls overlay
            if (widget.showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildControls(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Play/Pause button (center)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // Progress bar and time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Progress slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: TColors.primary,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: TColors.primary,
                    overlayColor: TColors.primary.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: _currentPosition.clamp(0.0, _totalDuration),
                    min: 0.0,
                    max: _totalDuration,
                    onChanged: (value) {
                      setState(() => _currentPosition = value);
                    },
                    onChangeEnd: (value) {
                      _seekTo(value);
                    },
                  ),
                ),

                // Time display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(milliseconds: _currentPosition.toInt())),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(_controller.value.duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);

    // 只有内部控制器才需要 dispose
    if (!_useExternalController && _internalController != null) {
      _internalController!.dispose();
      print('🗑️ Video player disposed');
    }

    super.dispose();
  }
}