import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../data/repositories/scans_repository.dart';
import 'perspective_correct.dart';
import 'scan_pipeline.dart';
import 'scanner_state.dart';
import 'stability_detector.dart';
import 'permission_gate.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({required this.scans, required this.pipeline, super.key});
  final ScansRepository scans;
  final ScanPipeline pipeline;

  @override
  Widget build(BuildContext context) => CameraPermissionGate(
        child: (ctx) => _ScannerBody(scans: scans, pipeline: pipeline),
      );
}

class _ScannerBody extends StatefulWidget {
  const _ScannerBody({required this.scans, required this.pipeline});
  final ScansRepository scans;
  final ScanPipeline pipeline;
  @override
  State<_ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<_ScannerBody> {
  CameraController? _controller;
  final _state = ScannerStateNotifier();
  final _tracker = StabilityTracker();
  bool _busy = false;
  DateTime? _lastCaptureAt;
  String? _lastLabel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first);
    final c = CameraController(back, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
    await c.initialize();
    if (!mounted) return;
    setState(() => _controller = c);
    await c.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _state.value.paused) return;
    _busy = true;
    try {
      final bytes = _bgrJpegFromFrame(img);
      if (bytes == null) return;
      final rect = detectCardRect(bytes);
      if (rect == null) {
        _tracker.reset();
        _state.toSearching();
        return;
      }
      _tracker.push(rect.quad);
      _state.toTracking();
      if (!_tracker.isStable) return;

      final sinceLast = DateTime.now().difference(
          _lastCaptureAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (sinceLast.inMilliseconds < 500) return;

      _state.toCapturing();
      final upright = warpToUpright(bytes, quad: rect.quad);
      _state.toProcessing();
      final res = await widget.pipeline.captureFromWarpedCrop(upright);
      _lastCaptureAt = DateTime.now();

      if (_lastLabel != null && _lastLabel == res.label) return;
      _lastLabel = res.label;
      _state.toDone(res.label, _state.value.inQueue + 1);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _state.toSearching();
      _tracker.reset();
    } finally {
      _busy = false;
    }
  }

  Uint8List? _bgrJpegFromFrame(CameraImage img) {
    if (img.format.group != ImageFormatGroup.yuv420) return null;
    final w = img.width;
    final h = img.height;
    if (w <= 0 || h <= 0 || img.planes.length < 3) return null;
    final yP = img.planes[0];
    final uP = img.planes[1];
    final vP = img.planes[2];

    final halfW = w ~/ 2;
    final halfH = h ~/ 2;
    final i420 = Uint8List(w * h + halfW * halfH * 2);
    var o = 0;
    for (var row = 0; row < h; row++) {
      i420.setRange(o, o + w, yP.bytes, row * yP.bytesPerRow);
      o += w;
    }
    final uPs = uP.bytesPerPixel ?? 1;
    for (var row = 0; row < halfH; row++) {
      final base = row * uP.bytesPerRow;
      for (var col = 0; col < halfW; col++) {
        i420[o++] = uP.bytes[base + col * uPs];
      }
    }
    final vPs = vP.bytesPerPixel ?? 1;
    for (var row = 0; row < halfH; row++) {
      final base = row * vP.bytesPerRow;
      for (var col = 0; col < halfW; col++) {
        i420[o++] = vP.bytes[base + col * vPs];
      }
    }

    final mat =
        cv.Mat.fromList(h + halfH, w, cv.MatType.CV_8UC1, i420);
    final bgr = cv.cvtColor(mat, cv.COLOR_YUV2BGR_I420);
    final (_, jpg) = cv.imencode('.jpg', bgr);
    mat.dispose();
    bgr.dispose();
    return jpg;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(c),
          ValueListenableBuilder<ScannerState>(
            valueListenable: _state,
            builder: (_, s, __) => _Overlay(state: s),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder<ScannerState>(
              valueListenable: _state,
              builder: (_, s, __) => _QueueBadge(inQueue: s.inQueue),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    _state.togglePause();
                    if (_state.value.paused) {
                      await c.stopImageStream();
                    } else {
                      await c.startImageStream(_onFrame);
                    }
                  },
                  icon: const Icon(Icons.pause_circle_outline,
                      size: 48, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    _state.toggleTorch();
                    await c.setFlashMode(
                        _state.value.torchOn ? FlashMode.torch : FlashMode.off);
                  },
                  icon: const Icon(Icons.flashlight_on,
                      size: 36, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});
  final ScannerState state;
  @override
  Widget build(BuildContext context) {
    if (state.phase == ScannerPhase.done && state.lastCardLabel != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 72),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('\u2713 ${state.lastCardLabel}',
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({required this.inQueue});
  final int inQueue;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text('$inQueue in queue',
            style: const TextStyle(color: Colors.white)),
      );
}
