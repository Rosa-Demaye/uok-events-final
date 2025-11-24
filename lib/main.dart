import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uok_events/auth/auth_gate.dart';
import 'package:uok_events/firebase_options.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/screens/create_event_page.dart';
import 'package:uok_events/screens/create_memo_page.dart';
import 'package:uok_events/screens/events_page.dart';
import 'package:uok_events/screens/memos_page.dart';
import 'package:uok_events/screens/profile_page.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/services/notification_service.dart';
import 'package:uok_events/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UoK Events',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = [
    const EventsPage(),
    const MemosPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Correctly initialize notifications after login
    final user = _authService.currentUser;
    if (user != null) {
      _notificationService.initNotifications(user.uid);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    // --- CRITICAL FIX ---
    // Safely handle the case where the user is null during initialization
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    // --------------------

    return StreamBuilder<UserModel>(
      stream: _firestoreService.getUserStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Show a loading indicator while user data is being fetched
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final userRole = snapshot.data?.role;
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Memos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
          floatingActionButton: _buildFab(userRole),
        );
      },
    );
  }

  Widget? _buildFab(String? userRole) {
    if (userRole != 'staff') return null;

    if (_selectedIndex == 0) { // Events Tab
      return FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateEventPage())),
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      );
    } else if (_selectedIndex == 1) { // Memos Tab
      return FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateMemoPage())),
        tooltip: 'Create Memo',
        child: const Icon(Icons.add_comment),
      );
    }
    return null;
  }
}
