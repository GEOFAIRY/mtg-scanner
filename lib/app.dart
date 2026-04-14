import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'data/db/database.dart';
import 'data/scryfall/scryfall_client.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/scans_repository.dart';
import 'features/shell/app_shell.dart';
import 'features/scanner/ocr_runner.dart';
import 'features/scanner/scan_matcher.dart';
import 'features/scanner/scan_pipeline.dart';
import 'features/scanner/scan_writer.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/scanner/thumbnail_storage.dart';
import 'features/review_queue/review_queue_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/collection/manual_add_screen.dart';
import 'features/collection/collection_detail_screen.dart';
import 'features/export/export_screen.dart';
import 'features/settings/settings_screen.dart';

class Deps {
  Deps._(this.db, this.scry, this.collection, this.scans, this.pipeline);
  final AppDatabase db;
  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScansRepository scans;
  final ScanPipeline pipeline;

  factory Deps.create() {
    final db = AppDatabase();
    final scry = ScryfallClient(http.Client());
    final collection = CollectionRepository(db, scry);
    final scans = ScansRepository(db);
    final pipeline = ScanPipeline(
      ocr: MlKitOcrRunner(),
      writer: ScanWriter(db),
      storage: ThumbnailStorage(),
      matcher: ScanMatcher(
        scry: scry,
        collection: collection,
        scans: scans,
        db: db,
      ),
    );
    return Deps._(db, scry, collection, scans, pipeline);
  }
}

class MtgScannerApp extends StatefulWidget {
  const MtgScannerApp({super.key});
  @override
  State<MtgScannerApp> createState() => _MtgScannerAppState();
}

class _MtgScannerAppState extends State<MtgScannerApp> {
  late final Deps deps = Deps.create();
  late final GoRouter _router = GoRouter(
    initialLocation: '/collection',
    routes: [
      ShellRoute(
        builder: (ctx, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
              path: '/scan',
              builder: (_, __) =>
                  ScannerScreen(scans: deps.scans, pipeline: deps.pipeline)),
          GoRoute(
              path: '/queue',
              builder: (_, __) => ReviewQueueScreen(
                  scans: deps.scans, collection: deps.collection, scry: deps.scry)),
          GoRoute(path: '/collection', routes: [
            GoRoute(
                path: 'add',
                builder: (_, __) => ManualAddScreen(
                    scry: deps.scry, collection: deps.collection)),
            GoRoute(
                path: ':id',
                builder: (ctx, st) => CollectionDetailScreen(
                    id: int.parse(st.pathParameters['id']!),
                    repo: deps.collection)),
          ], builder: (_, __) => CollectionScreen(repo: deps.collection)),
          GoRoute(path: '/export', builder: (_, __) => ExportScreen(repo: deps.collection)),
          GoRoute(path: '/settings', builder: (_, __) => SettingsScreen(repo: deps.collection)),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    deps.db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'MTG Scanner',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        routerConfig: _router,
      );
}
