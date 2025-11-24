import 'package:flutter/material.dart';
import 'package:uok_events/auth/login_page.dart';
import 'package:uok_events/auth/signup_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Initially, show the login page
  bool _showLoginPage = true;

  // Toggle between login and sign up pages
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
