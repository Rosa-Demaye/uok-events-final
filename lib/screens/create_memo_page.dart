import 'package:flutter/material.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';

class CreateMemoPage extends StatefulWidget {
  const CreateMemoPage({super.key});

  @override
  State<CreateMemoPage> createState() => _CreateMemoPageState();
}

class _CreateMemoPageState extends State<CreateMemoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _postMemo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    try {
      final user = _authService.currentUser!;
      // Fetch the user's full name to store with the memo
      final UserModel userModel = await _firestoreService.getCurrentUserModel(user.uid);

      await _firestoreService.addMemo(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        authorName: userModel.fullName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memo posted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post memo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Memo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null, // Allows for multiline input
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Content cannot be empty' : null,
                ),
              ),
              const SizedBox(height: 24.0),
              if (_isPosting)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _postMemo,
                    child: const Text('POST MEMO'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
