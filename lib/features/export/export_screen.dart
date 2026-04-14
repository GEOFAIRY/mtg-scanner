import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Export')));
}
