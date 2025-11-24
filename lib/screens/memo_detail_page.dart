import 'package:flutter/material.dart';

class MemoDetailPage extends StatelessWidget {
  final String memoId;

  const MemoDetailPage({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Details'),
      ),
      body: Center(
        child: Text('Details for Memo ID: $memoId'),
      ),
    );
  }
}
