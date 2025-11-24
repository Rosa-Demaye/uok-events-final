import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/services/firestore_service.dart';

class EditEventPage extends StatefulWidget {
  final Event event;
  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _categoryController;
  late DateTime _selectedDateTime;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _categoryController = TextEditingController(text: widget.event.category);
    _selectedDateTime = widget.event.dateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedEvent = Event(
        id: widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _categoryController.text.trim(),
        dateTime: _selectedDateTime,
        mediaUrl: widget.event.mediaUrl,
        mediaType: widget.event.mediaType,
        organizer: widget.event.organizer,
        organizerId: widget.event.organizerId,
        attendees: widget.event.attendees,
        likes: widget.event.likes,
        commentCount: widget.event.commentCount,
      );

      await _firestoreService.updateEvent(updatedEvent);

      if (mounted) {
        // Pop back to the event details page, which will now be updated
        Navigator.of(context).pop(); 
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
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
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'Category is required' : null),
              const SizedBox(height: 24),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date & Time'),
                subtitle: Text(DateFormat("EEE, MMM d, yyyy 'at' h:mm a").format(_selectedDateTime)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 32),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveChanges,
                  child: const Text('SAVE CHANGES'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
