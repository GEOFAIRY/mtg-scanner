import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'app_settings.dart';
import 'data/db/database.dart';
import 'data/repositories/collection_repository.dart';
import 'data/scryfall/scryfall_client.dart';
import 'features/collection/collection_detail_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/collection/manual_add_screen.dart';
import 'features/export/export_screen.dart';
import 'features/scanner/ocr_runner.dart';
import 'features/scanner/scan_matcher.dart';
import 'features/scanner/scan_pipeline.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/scanner/thumbnail_storage.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';

class Deps {
  Deps._(this.db, this.scry, this.collection, this.pipeline, this.settings,
      this.valuePlayer);
  final AppDatabase db;
  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;

  static Future<Deps> create() async {
    final db = AppDatabase();
    final scry = ScryfallClient(http.Client());
    final collection = CollectionRepository(db, scry);
    final pipeline = ScanPipeline(
      ocr: MlKitOcrRunner(),
      storage: ThumbnailStorage(),
      matcher: ScanMatcher(scry: scry),
      collection: collection,
    );
    final settings = await AppSettings.load();
    final valuePlayer = AudioPlayer();
    await valuePlayer.setSource(AssetSource('sounds/cash_register.mp3'));
    await valuePlayer.setReleaseMode(ReleaseMode.stop);
    return Deps._(db, scry, collection, pipeline, settings, valuePlayer);
  }
}

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
    return MaterialApp.router(
      title: 'MTG Scanner',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      routerConfig: router,
    );
  }
}
