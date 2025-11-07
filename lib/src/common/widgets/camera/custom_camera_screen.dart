import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../utils/constants/colors.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final controller = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    await _controller?.dispose();
    await _setupCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      setState(() {
        _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      });
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(tempDir.path, fileName);

      final imageFile = File(image.path);
      final savedFile = await imageFile.copy(filePath);

      Get.back(result: savedFile);
    } catch (e) {
      _showError('Failed to capture photo: $e');
      setState(() => _isCapturing = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white, size: 28),
                    ),

                    Text(
                      'Take Meal Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Flash toggle
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Guide overlay
          if (_isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: CameraGuidePainter(),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tips
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '📸 Frame your meal within the guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // Camera controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch camera
                        if (_cameras != null && _cameras!.length > 1)
                          _controlButton(
                            icon: Icons.flip_camera_ios,
                            onTap: _switchCamera,
                          )
                        else
                          SizedBox(width: 60),

                        // Capture button
                        GestureDetector(
                          onTap: _isCapturing ? null : _capturePhoto,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: _isCapturing
                                ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 60), // Spacer for symmetry
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Custom painter for camera guide overlay
class CameraGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final guideRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.width * 0.8,
    );

    // Draw rounded rectangle guide
    final rrect = RRect.fromRectAndRadius(
      guideRect,
      Radius.circular(16),
    );
    canvas.drawRRect(rrect, paint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = TColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(guideRect.left, guideRect.top + cornerLength),
      Offset(guideRect.left, guideRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.left, guideRect.top),
      Offset(guideRect.left + cornerLength, guideRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(guideRect.right - cornerLength, guideRect.top),
      Offset(guideRect.right, guideRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.right, guideRect.top),
      Offset(guideRect.right, guideRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(guideRect.left, guideRect.bottom - cornerLength),
      Offset(guideRect.left, guideRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.left, guideRect.bottom),
      Offset(guideRect.left + cornerLength, guideRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(guideRect.right - cornerLength, guideRect.bottom),
      Offset(guideRect.right, guideRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.right, guideRect.bottom - cornerLength),
      Offset(guideRect.right, guideRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}