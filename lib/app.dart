import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_settings.dart';
import 'data/db/database.dart';
import 'data/repositories/collection_repository.dart';
import 'data/scryfall/scryfall_client.dart';
import 'features/collection/collection_detail_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/collection/manual_add_screen.dart';
import 'features/export/export_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'features/scanner/ocr_runner.dart';
import 'features/scanner/scan_debug_recorder.dart';
import 'features/scanner/scan_matcher.dart';
import 'features/scanner/scan_pipeline.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';

Future<void> _purgeLegacyScanThumbs() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory(p.join(dir.path, 'scan_thumbs'));
    if (await subdir.exists()) await subdir.delete(recursive: true);
  } catch (_) {
    // Best-effort — missing dir / permission issues are fine.
  }
}

class Deps {
  Deps._(this.db, this.scry, this.collection, this.pipeline, this.settings,
      this.valuePlayer, this.clickPlayer);
  final AppDatabase db;
  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;
  final AudioPlayer clickPlayer;

  static Future<Deps> create() async {
    final db = AppDatabase();
    final scry = ScryfallClient(http.Client());
    final collection = CollectionRepository(db, scry);
    final pipeline = ScanPipeline(
      ocr: MlKitOcrRunner(),
      matcher: ScanMatcher(scry: scry),
      collection: collection,
      debugRecorder: kDebugMode ? ScanDebugRecorder() : null,
    );
    // One-time cleanup for the legacy scan_thumbs directory. Older builds
    // wrote a PNG to this dir on every successful scan with no reader and
    // no retention policy.
    unawaited(_purgeLegacyScanThumbs());
    final settings = await AppSettings.load();
    final valuePlayer = AudioPlayer();
    await valuePlayer.setSource(AssetSource('sounds/cash_register.mp3'));
    await valuePlayer.setReleaseMode(ReleaseMode.stop);
    // Short synthesized blip for low-value scan confirmations — generated
    // once at startup so we don't need an extra asset.
    final clickPlayer = AudioPlayer();
    await clickPlayer.setSource(BytesSource(_generateClickWav()));
    await clickPlayer.setReleaseMode(ReleaseMode.stop);
    return Deps._(
        db, scry, collection, pipeline, settings, valuePlayer, clickPlayer);
  }
}

/// Build a tiny 16-bit mono WAV — a 90ms 1200Hz-to-900Hz downsweep with a
/// short exponential decay. Keeps it distinct from the cash register.
Uint8List _generateClickWav() {
  const sampleRate = 22050;
  const durationMs = 90;
  const startHz = 1200.0;
  const endHz = 900.0;
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final dataBytes = ByteData(sampleCount * 2);
  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleCount;
    final freq = startHz + (endHz - startHz) * t;
    final envelope = (1 - t) * (1 - t); // fast decay
    final sample = envelope * 0.4 * sin(2 * pi * freq * i / sampleRate);
    dataBytes.setInt16(i * 2, (sample * 32767).round(), Endian.little);
  }
  final data = dataBytes.buffer.asUint8List();
  final totalSize = 36 + data.length;
  final header = BytesBuilder()
    ..add(ascii.encode('RIFF'))
    ..add(_le32(totalSize))
    ..add(ascii.encode('WAVE'))
    ..add(ascii.encode('fmt '))
    ..add(_le32(16))
    ..add(_le16(1)) // PCM
    ..add(_le16(1)) // mono
    ..add(_le32(sampleRate))
    ..add(_le32(sampleRate * 2)) // byte rate
    ..add(_le16(2)) // block align
    ..add(_le16(16)) // bits per sample
    ..add(ascii.encode('data'))
    ..add(_le32(data.length));
  return Uint8List.fromList([...header.toBytes(), ...data]);
}

List<int> _le16(int v) => [v & 0xff, (v >> 8) & 0xff];
List<int> _le32(int v) =>
    [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];

class MtgScannerApp extends StatefulWidget {
  const MtgScannerApp({super.key});
  @override
  State<MtgScannerApp> createState() => _MtgScannerAppState();
}

class _MtgScannerAppState extends State<MtgScannerApp> {
  Deps? _deps;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    Deps.create().then((d) {
      if (!mounted) return;
      setState(() {
        _deps = d;
        _router = _buildRouter(d);
      });
    });
  }

  GoRouter _buildRouter(Deps deps) => GoRouter(
        initialLocation: '/scan',
        routes: [
          ShellRoute(
            observers: [appRouteObserver],
            builder: (ctx, state, child) =>
                AppShell(location: state.matchedLocation, child: child),
            routes: [
              GoRoute(
                path: '/scan',
                builder: (_, __) => ScannerScreen(
                  pipeline: deps.pipeline,
                  settings: deps.settings,
                  valuePlayer: deps.valuePlayer,
                  clickPlayer: deps.clickPlayer,
                  collection: deps.collection,
                  scry: deps.scry,
                ),
              ),
              GoRoute(
                path: '/collection',
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => ManualAddScreen(
                        scry: deps.scry, collection: deps.collection),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (ctx, st) => CollectionDetailScreen(
                      id: int.parse(st.pathParameters['id']!),
                      repo: deps.collection,
                      scry: deps.scry
                    ),
                  ),
                ],
                builder: (_, __) => CollectionScreen(repo: deps.collection),
              ),
              GoRoute(
                path: '/export',
                builder: (_, __) => ExportScreen(repo: deps.collection),
              ),
              GoRoute(
                path: '/settings',
                builder: (_, __) => SettingsScreen(
                    repo: deps.collection, settings: deps.settings),
              ),
            ],
          ),
        ],
      );

  @override
  void dispose() {
    _deps?.db.close();
    _deps?.valuePlayer.dispose();
    _deps?.clickPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return AnimatedBuilder(
      animation: _deps!.settings,
      builder: (_, __) => MaterialApp.router(
        title: 'MTG Scanner',
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: _deps!.settings.themeMode,
        routerConfig: router,
      ),
    );
  }
}

