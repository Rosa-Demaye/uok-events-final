import 'package:flutter/material.dart';
import 'package:uok_events/auth/login_page.dart';
import 'package:uok_events/auth/signup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Initially, show the login page
  bool _showLoginPage = true;

  // Toggle between login and register pages
  void _togglePages() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      return LoginPage(onRegisterTap: _togglePages);
    } else {
      return SignUpPage(onLoginTap: _togglePages);
    }
  }
}
