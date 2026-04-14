import 'package:flutter/material.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({required this.scans, required this.collection, required this.scry, super.key});
  final ScansRepository scans;
  final CollectionRepository collection;
  final ScryfallClient scry;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Queue')));
}
