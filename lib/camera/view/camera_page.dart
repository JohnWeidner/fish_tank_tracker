import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// {@template camera_page}
/// A standalone camera page that captures a photo and pops with the file path.
/// {@endtemplate}
class CameraPage extends StatefulWidget {
  /// {@macro camera_page}
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }
      // Prefer rear camera.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      // Disable flash by default (reduces aquarium glass glare).
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'Camera error: $e');
    } on Exception catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final xFile = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/images');
      if (!imagesDir.existsSync()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${imagesDir.path}/$fileName';
      await File(xFile.path).copy(savedPath);

      if (mounted) {
        Navigator.of(context).pop(savedPath);
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = 'Capture failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 64),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(child: CameraPreview(_controller!)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FloatingActionButton.large(
              heroTag: null,
              onPressed: _capturePhoto,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ),
      ],
    );
  }
}
