import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String? registrationNumber;
  final String? staffCode;
  final String faculty;
  final String department;
  final String? position;
  final String profilePictureUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.registrationNumber,
    this.staffCode,
    required this.faculty,
    required this.department,
    this.position,
    required this.profilePictureUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // This check prevents the app from crashing if the user document doesn't exist.
    if (!doc.exists || doc.data() == null) {
      throw StateError('Cannot create a UserModel from a document that does not exist.');
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'student',
      registrationNumber: data['registrationNumber'],
      staffCode: data['staffCode'],
      faculty: data['faculty'] ?? '',
      department: data['department'] ?? '',
      position: data['position'],
      profilePictureUrl: data['profilePictureUrl'] ?? '',
    );
  }
}
