import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/utils/theme.dart';

enum UserRole { student, staff }

class SignUpPage extends StatefulWidget {
  final VoidCallback onLoginTap;
  const SignUpPage({super.key, required this.onLoginTap});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _staffCodeController = TextEditingController();
  final _facultyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    print("--- Starting Sign Up Process ---");

    try {
      print("Attempting to create user in Firebase Auth...");
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential?.user != null) {
        print("Firebase Auth user created successfully. UID: ${userCredential!.user!.uid}");

        print("Attempting to save user data to Firestore...");
        await _firestoreService.saveUserData(
          uid: userCredential.user!.uid,
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          role: _selectedRole == UserRole.student ? 'student' : 'staff',
          faculty: _facultyController.text.trim(),
          department: _departmentController.text.trim(),
          regNo: _selectedRole == UserRole.student ? _regNoController.text.trim() : null,
          staffCode: _selectedRole == UserRole.staff ? _staffCodeController.text.trim() : null,
          position: _selectedRole == UserRole.staff ? _positionController.text.trim() : null,
        );
        print("User data saved successfully to Firestore.");
      } else {
        print("Firebase Auth user creation failed, user object is null.");
      }
    } catch (e) {
      print("!!! AN ERROR OCCURRED DURING SIGN UP: ${e.toString()} !!!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.accentRed),
        );
      }
    } finally {
      print("--- Sign Up Process Finished ---");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... build method is unchanged ...
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30.0),
                        Image.asset('assets/uok_logo.png', height: 80),
                        const SizedBox(height: 24.0),
                        Text('Create an Account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 24.0),
                        _buildRoleSelector(),
                        const SizedBox(height: 24.0),
                        _buildTextField(_fullNameController, 'Full Name', Icons.person_outline),
                        const SizedBox(height: 16.0),
                        _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                        const SizedBox(height: 16.0),
                        _buildTextField(_facultyController, 'Faculty', Icons.school_outlined),
                        const SizedBox(height: 16.0),
                        _buildTextField(_departmentController, 'Department', Icons.business_center_outlined),
                        const SizedBox(height: 16.0),
                        if (_selectedRole == UserRole.student)
                          _buildTextField(_regNoController, 'Registration Number', Icons.app_registration, validator: _validateRegNo)
                        else
                          _buildTextField(_staffCodeController, 'Staff Code', Icons.badge_outlined, validator: _validateStaffCode),
                        const SizedBox(height: 16.0),
                        if (_selectedRole == UserRole.staff)
                          _buildTextField(_positionController, 'Position', Icons.work_outline),
                        if (_selectedRole == UserRole.staff) const SizedBox(height: 16.0),
                        _buildTextField(
                          _passwordController, 'Password', Icons.lock_outline, obscureText: !_isPasswordVisible,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _buildTextField(
                          _confirmPasswordController, 'Confirm Password', Icons.lock_outline, obscureText: !_isConfirmPasswordVisible,
                          validator: _validateConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: widget.onLoginTap,
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() { return Container(decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12.0)), child: LayoutBuilder(builder: (context, constraints) { return ToggleButtons(isSelected: [_selectedRole == UserRole.student, _selectedRole == UserRole.staff], onPressed: (index) { setState(() { _selectedRole = index == 0 ? UserRole.student : UserRole.staff; }); }, borderRadius: BorderRadius.circular(12.0), selectedColor: AppTheme.white, fillColor: AppTheme.primaryBlue, color: AppTheme.primaryBlue, constraints: BoxConstraints.expand(width: (constraints.maxWidth / 2) - 2, height: 48), children: const [Center(child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))), Center(child: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold)))]); })); }
  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator, Widget? suffixIcon}) { return TextFormField(controller: controller, obscureText: obscureText, keyboardType: keyboardType, decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(icon), suffixIcon: suffixIcon), validator: validator ?? (value) => (value == null || value.isEmpty) ? 'This field cannot be empty' : null); }
  String? _validateEmail(String? value) { if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) { return 'Please enter a valid email address'; } return null; }
  String? _validatePassword(String? value) { if (value == null || value.length < 6) { return 'Password must be at least 6 characters long'; } return null; }
  String? _validateConfirmPassword(String? value) { if (value != _passwordController.text) { return 'Passwords do not match'; } return null; }
  String? _validateRegNo(String? value) { if (value == null || value.isEmpty) return 'Registration number cannot be empty'; final regExp = RegExp(r'^\d{10}$'); if (!regExp.hasMatch(value)) { return 'Invalid Registration Number format (e.g., 2301000552)'; } return null; }
  String? _validateStaffCode(String? value) { if (value == null || value.isEmpty) return 'Staff code cannot be empty'; final regExp = RegExp(r'^[A-Z]{4}\d{8}$'); if (!regExp.hasMatch(value)) { return 'Invalid Staff Code format (e.g., BBIT23010020)'; } return null; }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _regNoController.dispose();
    _staffCodeController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
