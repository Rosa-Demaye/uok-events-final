import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

enum MediaType { image, video }

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _authService = AuthService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();

  DateTime? _selectedDateTime;
  File? _selectedMediaFile;
  MediaType _selectedMediaType = MediaType.image;
  bool _isPosting = false;
  VideoPlayerController? _videoController;

  Future<void> _pickMedia() async {
    XFile? pickedFile;
    if (_selectedMediaType == MediaType.image) {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    } else {
      pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      await _videoController?.dispose();
      _videoController = null;

      final file = File(pickedFile.path);

      if (_selectedMediaType == MediaType.video) {
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
      }

      setState(() {
        _selectedMediaFile = file;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _postEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null || _selectedMediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date, time, and media file.')));
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = _authService.currentUser!;
      final userModel = await _firestoreService.getCurrentUserModel(user.uid);

      final mediaUrl = await _storageService.uploadProfilePicture(user.uid, _selectedMediaFile!); // Re-using storage method

      final newEvent = Event(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        mediaUrl: mediaUrl,
        mediaType: _selectedMediaType == MediaType.image ? 'image' : 'video',
        category: _categoryController.text.trim(),
        dateTime: _selectedDateTime!,
        organizer: userModel.fullName,
        organizerId: user.uid,
        attendees: [],
        likes: [],
        commentCount: 0,
      );

      await _firestoreService.addEvent(newEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Posted Successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post event: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'Title is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 5, validator: (v) => v!.trim().isEmpty ? 'Description is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location / Venue', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'Location is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category (e.g., Workshop, Seminar)', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'Category is required' : null),
              const SizedBox(height: 24),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date & Time'),
                subtitle: Text(_selectedDateTime != null ? DateFormat('EEE, MMM d, yyyy h:mm a').format(_selectedDateTime!) : 'Not Set'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              SegmentedButton<MediaType>(
                segments: const <ButtonSegment<MediaType>>[
                  ButtonSegment<MediaType>(value: MediaType.image, label: Text('Image'), icon: Icon(Icons.photo)),
                  ButtonSegment<MediaType>(value: MediaType.video, label: Text('Video'), icon: Icon(Icons.videocam)),
                ],
                selected: <MediaType>{_selectedMediaType},
                onSelectionChanged: (Set<MediaType> newSelection) {
                  setState(() {
                    _selectedMediaType = newSelection.first;
                    _selectedMediaFile = null;
                    _videoController?.dispose();
                    _videoController = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                leading: _selectedMediaType == MediaType.image ? const Icon(Icons.image) : const Icon(Icons.video_library),
                title: Text(_selectedMediaType == MediaType.image ? 'Event Image' : 'Event Video'),
                subtitle: Text(_selectedMediaFile?.path.split('/').last ?? 'Not Set'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickMedia,
              ),
              if (_selectedMediaFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: _selectedMediaType == MediaType.image
                        ? Image.file(_selectedMediaFile!, height: 180, fit: BoxFit.cover, width: double.infinity)
                        : (_videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Container(height: 180, color: Colors.black, child: const Center(child: CircularProgressIndicator()))),
                  ),
                ),
              const SizedBox(height: 32),
              if (_isPosting)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _postEvent,
                  child: const Text('POST EVENT'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
