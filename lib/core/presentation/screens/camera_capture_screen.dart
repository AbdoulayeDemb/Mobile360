import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _isInitializing = false;
  bool _isTakingPhoto = false;
  bool _retryAfterInitialization = false;
  int _cameraSession = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiserCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSession++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initialiserCamera();
    } else {
      _libererCamera();
    }
  }

  Future<void> _initialiserCamera() async {
    if (_controller?.value.isInitialized == true) return;
    if (_isInitializing) {
      _retryAfterInitialization = true;
      return;
    }

    final session = ++_cameraSession;
    _isInitializing = true;
    if (mounted) setState(() => _error = null);

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted || session != _cameraSession) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'Aucune caméra disponible sur cet appareil.');
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted || session != _cameraSession) {
        await controller.dispose();
        return;
      }
      setState(() {});
    } catch (error) {
      if (session == _cameraSession && mounted) {
        debugPrint('Erreur initialisation caméra : $error');
        setState(() => _error = 'Impossible d’ouvrir la caméra.');
      }
      if (controller != null && !controller.value.isInitialized) {
        await controller.dispose();
        if (identical(_controller, controller)) _controller = null;
      }
    } finally {
      _isInitializing = false;
      if (_retryAfterInitialization && mounted) {
        _retryAfterInitialization = false;
        await _initialiserCamera();
      }
    }
  }

  Future<void> _libererCamera() async {
    _cameraSession++;
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _prendrePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPhoto) {
      return;
    }

    setState(() => _isTakingPhoto = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(photo.path);
    } catch (error) {
      debugPrint('Erreur prise de photo : $error');
      if (mounted) {
        setState(() => _error = 'La photo n’a pas pu être prise. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (controller?.value.isInitialized == true)
              Center(
                child: AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              )
            else
              Center(
                child: _error == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _initialiserCamera,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Fermer la caméra',
              ),
            ),
            if (controller?.value.isInitialized == true)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _isTakingPhoto ? null : _prendrePhoto,
                    iconSize: 76,
                    color: Colors.white,
                    icon: Icon(
                      _isTakingPhoto
                          ? Icons.hourglass_top_rounded
                          : Icons.camera_rounded,
                    ),
                    tooltip: 'Prendre une photo',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
