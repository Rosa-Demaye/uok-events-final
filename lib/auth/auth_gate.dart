import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uok_events/auth/auth_page.dart';
import 'package:uok_events/main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not signed in
        if (!snapshot.hasData) {
          return const AuthPage(); // Use the new AuthPage toggle
        }

        // User is signed in, show home page
        return const HomePage();
      },
    );
  }
}
