import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../app_settings.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import 'edit_scan_modal.dart';
import 'perspective_correct.dart';
import 'result_banner.dart';
import 'scan_pipeline.dart';
import 'scanner_state.dart';
import 'stability_detector.dart';
import 'permission_gate.dart';

final appRouteObserver = RouteObserver<ModalRoute<void>>();

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({
    required this.pipeline,
    required this.settings,
    required this.valuePlayer,
    required this.collection,
    required this.scry,
    super.key,
  });
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;
  final CollectionRepository collection;
  final ScryfallClient scry;

  @override
  Widget build(BuildContext context) => CameraPermissionGate(
        child: (ctx) => _ScannerBody(
          pipeline: pipeline,
          settings: settings,
          valuePlayer: valuePlayer,
          collection: collection,
          scry: scry,
        ),
      );
}

class _ScannerBody extends StatefulWidget {
  const _ScannerBody({
    required this.pipeline,
    required this.settings,
    required this.valuePlayer,
    required this.collection,
    required this.scry,
  });
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;
  final CollectionRepository collection;
  final ScryfallClient scry;
  @override
  State<_ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<_ScannerBody>
    with WidgetsBindingObserver, RouteAware {
  CameraController? _controller;
  final _state = ScannerStateNotifier();
  final _tracker = StabilityTracker();
  final _forceFoil = ValueNotifier<bool>(false);
  final _banner = ValueNotifier<BannerData?>(null);
  bool _busy = false;
  DateTime? _lastCaptureAt;
  // Re-arm only after a run of truly empty frames — a single rect-null flicker
  // (shadow, hand moving across the card) used to re-trigger capture and
  // produce duplicate scans of the same card.
  static const _emptyFramesToReArm = 6;
  int _emptyStreak = _emptyFramesToReArm;
  // Suppress re-capturing the same Scryfall card back-to-back.
  String? _lastMatchedCardId;
  DateTime? _lastMatchedAt;
  static const _duplicateWindow = Duration(seconds: 3);
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
        if (_emptyStreak < _emptyFramesToReArm) _emptyStreak++;
        return;
      }
      _tracker.push(rect.quad);
      _state.toTracking();
      if (!_tracker.isStable) return;
      if (_emptyStreak < _emptyFramesToReArm) return;

      final sinceLast = DateTime.now().difference(
          _lastCaptureAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (sinceLast.inMilliseconds < 500) return;

      if (_externallyPaused || _state.value.paused) return;
      _emptyStreak = 0;
      _state.toCapturing();
      final upright = warpToUpright(bytes, quad: rect.quad);
      _state.toMatching();
      final res = await widget.pipeline
          .captureFromWarpedCrop(upright, forceFoil: _forceFoil.value);
      _lastCaptureAt = DateTime.now();

      if (_externallyPaused || _state.value.paused) {
        _state.toSearching();
        _tracker.reset();
        return;
      }

      switch (res.outcome) {
        case CaptureOutcome.matched:
          final now = DateTime.now();
          final isDuplicate = res.card!.id == _lastMatchedCardId &&
              _lastMatchedAt != null &&
              now.difference(_lastMatchedAt!) < _duplicateWindow;
          if (isDuplicate) {
            // Same card matched again within the cooldown — the user almost
            // certainly hasn't swapped cards; undo the insertion the pipeline
            // just performed and keep the existing banner.
            await widget.collection.undoAdd(
                id: res.collectionId!, wasInsertion: res.wasInsertion);
            _lastMatchedAt = now;
            _state.toSearching();
            _tracker.reset();
            return;
          }
          _lastMatchedCardId = res.card!.id;
          _lastMatchedAt = now;
          _banner.value = BannerData(
            collectionId: res.collectionId!,
            card: res.card!,
            price: res.price,
            foil: res.foil,
            wasInsertion: res.wasInsertion,
          );
          _state.toSearching();
          if (res.price != null &&
              res.price! > widget.settings.valueAlertThreshold) {
            unawaited(_playValueAlert());
          }
          _tracker.reset();
          return;
        case CaptureOutcome.noMatch:
          _state.toNoMatch();
          break;
        case CaptureOutcome.offline:
          _state.toOffline();
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _state.toSearching();
      _tracker.reset();
    } finally {
      _busy = false;
    }
  }

  Future<void> _playValueAlert() async {
    try {
      await widget.valuePlayer.stop();
      await widget.valuePlayer.resume();
    } catch (_) {}
  }

  Future<void> _onDismissBanner() async {
    final d = _banner.value;
    if (d == null) return;
    _banner.value = null;
    await widget.collection
        .undoAdd(id: d.collectionId, wasInsertion: d.wasInsertion);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text('Dismissed ${d.card.name}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          final result = await widget.collection
              .addFromScryfall(d.card, foil: d.foil);
          if (!mounted) return;
          _banner.value = BannerData(
            collectionId: result.id,
            card: d.card,
            price: d.price,
            foil: d.foil,
            wasInsertion: result.wasInsertion,
          );
        },
      ),
    ));
  }

  Future<void> _onEditBanner() async {
    final d = _banner.value;
    if (d == null) return;
    await _pauseStream();
    final current = await (widget.collection.db.select(widget.collection.db.collection)
          ..where((t) => t.id.equals(d.collectionId)))
        .getSingleOrNull();
    if (!mounted) return;
    final currentCount = current?.count ?? 1;
    final result = await Navigator.of(context).push<EditScanResult>(
      MaterialPageRoute(
        builder: (_) => EditScanModal(
          initialCard: d.card,
          initialFoil: d.foil,
          initialCount: currentCount,
          collection: widget.collection,
          scry: widget.scry,
          collectionId: d.collectionId,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      _banner.value = BannerData(
        collectionId: d.collectionId,
        card: result.card,
        price: (result.foil
                ? result.card.prices.usdFoil
                : result.card.prices.usd) ??
            result.card.prices.usd ??
            result.card.prices.usdFoil,
        foil: result.foil,
        wasInsertion: d.wasInsertion,
      );
    }
    await _resumeStreamIfNotPaused();
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
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          (c == null || !c.value.isInitialized)
              ? const ColoredBox(color: Colors.black)
              : CameraPreview(c),
          ValueListenableBuilder<ScannerState>(
            valueListenable: _state,
            builder: (_, s, __) => _Overlay(state: s),
          ),
          Positioned(
            bottom: 196,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _forceFoil,
                builder: (_, on, __) => AnimatedOpacity(
                  opacity: on ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECC460),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.black, size: 14),
                        SizedBox(width: 4),
                        Text('FOIL MODE',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _forceFoil,
                  builder: (_, on, __) => _ToggleButton(
                    icon: Icons.auto_awesome,
                    label: on ? 'Foil ON' : 'Foil OFF',
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
                      try {
                        await c?.setFlashMode(
                            s.torchOn ? FlashMode.off : FlashMode.torch);
                      } catch (_) {}
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<BannerData?>(
              valueListenable: _banner,
              builder: (_, d, __) => ResultBanner(
                data: d,
                onDismiss: _onDismissBanner,
                onEdit: _onEditBanner,
              ),
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
    final (text, color) = switch (state.phase) {
      ScannerPhase.matching => ('Matching', Colors.white70),
      ScannerPhase.noMatch => ('\u2717 no match', Colors.redAccent),
      ScannerPhase.offline => ('\u26A0 offline', Colors.orangeAccent),
      _ => (null, Colors.white),
    };
    if (text == null) return const SizedBox.shrink();
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
          child: Text(text, style: TextStyle(color: color)),
        ),
      ),
    );
  }
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

