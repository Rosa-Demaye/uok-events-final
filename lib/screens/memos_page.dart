import 'package:flutter/material.dart';
import 'package:uok_events/models/memo_model.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/widgets/memo_card.dart';

class MemosPage extends StatelessWidget {
  const MemosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos & Announcements'),
      ),
      body: StreamBuilder<List<Memo>>(
        stream: firestoreService.getMemosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No memos found.'));
          }

          final memos = snapshot.data!;
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              return MemoCard(memo: memos[index]);
            },
          );
        },
      ),
    );
  }
}
