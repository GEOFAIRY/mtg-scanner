import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({required this.id, required this.repo, super.key});
  final int id;
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Card $id')));
}
