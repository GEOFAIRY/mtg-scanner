import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../data/db/database.dart';
import '../../data/repositories/scans_repository.dart';
import 'perspective_correct.dart';
import 'scan_pipeline.dart';
import 'scanner_state.dart';
import 'stability_detector.dart';
import 'permission_gate.dart';

final appRouteObserver = RouteObserver<ModalRoute<void>>();

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

class _ScannerBodyState extends State<_ScannerBody>
    with WidgetsBindingObserver, RouteAware {
  CameraController? _controller;
  final _state = ScannerStateNotifier();
  final _tracker = StabilityTracker();
  final _forceFoil = ValueNotifier<bool>(false);
  bool _busy = false;
  DateTime? _lastCaptureAt;
  String? _lastLabel;
  bool _streamActive = false;
  bool _externallyPaused = false;
  bool _initializing = false;
  ModalRoute<void>? _modalRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r != _modalRoute) {
      if (_modalRoute != null) appRouteObserver.unsubscribe(this);
      _modalRoute = r;
      if (r != null) appRouteObserver.subscribe(this, r);
    }
  }

  @override
  void didPushNext() => _pauseStream();

  @override
  void didPopNext() => _resumeStreamIfNotPaused();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeStreamIfNotPaused();
    } else {
      _releaseCamera();
    }
  }

  Future<void> _pauseStream() async {
    _externallyPaused = true;
    final c = _controller;
    if (c == null || !c.value.isInitialized || !_streamActive) return;
    _streamActive = false;
    try {
      await c.stopImageStream();
    } catch (_) {}
  }

  Future<void> _resumeStreamIfNotPaused() async {
    if (_state.value.paused) return;
    _externallyPaused = false;
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      await _init();
      return;
    }
    if (_streamActive) return;
    _streamActive = true;
    try {
      await c.startImageStream(_onFrame);
    } catch (_) {
      _streamActive = false;
    }
  }

  Future<void> _releaseCamera() async {
    _externallyPaused = true;
    _streamActive = false;
    final c = _controller;
    if (c == null) return;
    _controller = null;
    if (mounted) setState(() {});
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _init() async {
    if (_initializing || _controller != null) return;
    _initializing = true;
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final c = CameraController(back, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      try {
        await c.initialize();
      } catch (_) {
        return;
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
      _streamActive = true;
      _externallyPaused = false;
      try {
        await c.startImageStream(_onFrame);
      } catch (_) {
        _streamActive = false;
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _state.value.paused || _externallyPaused) return;
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

      if (_externallyPaused || _state.value.paused) return;
      _state.toCapturing();
      final upright = warpToUpright(bytes, quad: rect.quad);
      _state.toProcessing();
      final res = await widget.pipeline
          .captureFromWarpedCrop(upright, forceFoil: _forceFoil.value);
      if (_externallyPaused || _state.value.paused) {
        await widget.scans.reject(res.id);
        return;
      }
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
    if (_modalRoute != null) appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _state.dispose();
    _forceFoil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      drawer: _ScannerDrawer(scans: widget.scans),
      onDrawerChanged: (open) {
        if (open) {
          _pauseStream();
        } else if (_modalRoute?.isCurrent ?? true) {
          _resumeStreamIfNotPaused();
        }
      },
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(c),
          ValueListenableBuilder<ScannerState>(
            valueListenable: _state,
            builder: (_, s, __) => _Overlay(state: s),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Builder(
              builder: (ctx) => _Chip(
                icon: Icons.menu,
                onTap: () async {
                  await _pauseStream();
                  if (!context.mounted) return;
                  Scaffold.of(ctx).openDrawer();
                },
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: StreamBuilder<List<Scan>>(
              stream: widget.scans.watchPending(),
              builder: (_, snap) {
                final n = snap.data?.length ?? 0;
                return _Chip(
                  label: '$n in queue',
                  onTap: () async {
                    await _pauseStream();
                    if (!context.mounted) return;
                    context.push('/queue');
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _forceFoil,
                  builder: (_, on, __) => _ToggleButton(
                    icon: Icons.auto_awesome,
                    label: 'Foil',
                    on: on,
                    onTap: () => _forceFoil.value = !_forceFoil.value,
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<ScannerState>(
                  valueListenable: _state,
                  builder: (_, s, __) => _ToggleButton(
                    icon: s.paused ? Icons.play_arrow : Icons.pause,
                    label: s.paused ? 'Resume' : 'Pause',
                    on: s.paused,
                    onTap: () async {
                      _state.togglePause();
                      if (_state.value.paused) {
                        await _pauseStream();
                      } else {
                        await _resumeStreamIfNotPaused();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<ScannerState>(
                  valueListenable: _state,
                  builder: (_, s, __) => _ToggleButton(
                    icon: Icons.flashlight_on,
                    label: 'Torch',
                    on: s.torchOn,
                    onTap: () async {
                      _state.toggleTorch();
                      await c.setFlashMode(
                          _state.value.torchOn ? FlashMode.torch : FlashMode.off);
                    },
                  ),
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

class _Chip extends StatelessWidget {
  const _Chip({this.icon, this.label, required this.onTap});
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: label == null ? 10 : 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, color: Colors.white, size: 22),
                if (icon != null && label != null) const SizedBox(width: 6),
                if (label != null)
                  Text(label!,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final bg = on
        ? const Color(0xFFECC460).withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.55);
    final fg = on ? Colors.black : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: fg, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerDrawer extends StatelessWidget {
  const _ScannerDrawer({required this.scans});
  final ScansRepository scans;
  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Review queue',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<Scan>>(
                  stream: scans.watchPending(),
                  builder: (_, snap) {
                    final items = snap.data ?? const [];
                    if (items.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No pending scans',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = items[i];
                        final title = s.matchedName ??
                            (s.rawName.trim().isEmpty
                                ? '(unmatched)'
                                : 'OCR: ${s.rawName}');
                        return ListTile(
                          dense: true,
                          title: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${(s.confidence * 100).toStringAsFixed(0)}%'),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push('/queue');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Open full review queue'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/queue');
                },
              ),
            ],
          ),
        ),
      );
}
