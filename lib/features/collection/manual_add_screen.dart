import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/repositories/collection_repository.dart';

class ManualAddScreen extends StatelessWidget {
  const ManualAddScreen({required this.scry, required this.collection, super.key});
  final ScryfallClient scry;
  final CollectionRepository collection;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Manual Add')));
}
