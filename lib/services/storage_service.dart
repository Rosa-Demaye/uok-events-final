import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create a unique path for the image
      String filePath = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the file
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(imageFile);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // It's good practice to log the error for debugging
      print('Error uploading profile picture: $e');
      rethrow; // Rethrow the error to be handled by the UI
    }
  }
}
