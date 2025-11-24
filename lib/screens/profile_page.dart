import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/services/storage_service.dart';
import 'package:uok_events/widgets/small_event_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final File imageFile = File(image.path);
        final String downloadUrl = await _storageService.uploadProfilePicture(user.uid, imageFile);
        await _firestoreService.updateUserProfilePicture(user.uid, downloadUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load user data.'));
          }

          final userModel = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildProfileHeader(context, userModel),
              ),
              const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('My Booked Events', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 16.0),
              _buildHorizontalEventsList(_firestoreService.getEventsForUser(user.uid)),
              if (userModel.role == 'staff') ...[
                const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('My Posted Events', style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16.0),
                _buildHorizontalEventsList(_firestoreService.getPostedEventsForUser(user.uid)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel userModel) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: userModel.profilePictureUrl.isNotEmpty
                  ? NetworkImage(userModel.profilePictureUrl)
                  : null,
              child: userModel.profilePictureUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            if (_isUploading)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0))
            else
              Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: _pickAndUploadImage,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              )
          ],
        ),
        const SizedBox(height: 16.0),
        Text(userModel.fullName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4.0),
        Text(userModel.email, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12.0),
        Chip(
          label: Text(userModel.role.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])),
          backgroundColor: Colors.grey[200],
          side: BorderSide(color: Colors.grey.shade400),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 24.0),
        if (userModel.role == 'student')
          _buildInfoRow(Icons.school, 'Faculty', userModel.faculty)
        else if (userModel.role == 'staff' && userModel.position != null)
          _buildInfoRow(Icons.work_outline, 'Position', userModel.position!),

        _buildInfoRow(Icons.business_center, 'Department', userModel.department),
        
        if (userModel.role == 'student' && userModel.registrationNumber != null)
          _buildInfoRow(Icons.app_registration, 'Reg No', userModel.registrationNumber!)
        else if (userModel.role == 'staff' && userModel.staffCode != null)
          _buildInfoRow(Icons.badge, 'Staff Code', userModel.staffCode!),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16.0),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8.0),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildHorizontalEventsList(Stream<List<Event>> stream) {
    return Container(
      height: 200, // Constrain height for horizontal list
      child: StreamBuilder<List<Event>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No events found.'),
            ));
          }
          final events = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: events.length,
            itemBuilder: (context, index) => SmallEventCard(event: events[index]),
          );
        },
      ),
    );
  }
}
