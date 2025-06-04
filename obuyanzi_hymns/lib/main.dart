import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'pages/hymns_page.dart';
import 'package:obuyanzi_hymns/models/language_preference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/admin_create_hymn_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD842SBt1afZVC5AOuSSYcd9OdMiGepX4k",
      authDomain: "obuyanzi-hymns.firebaseapp.com",
      projectId: "obuyanzi-hymns",
      storageBucket: "obuyanzi-hymns.firebasestorage.app",
      messagingSenderId: "939816131988",
      appId: "1:939816131988:web:babe49ec07690c3b1a0381",
    ),
  );
  runApp(const ObuyanziHymnsApp());
}

class ObuyanziHymnsApp extends StatelessWidget {
  const ObuyanziHymnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obuyanzi Hymns',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/login': (context) => LoginPage(
          onLogin: (user, role) async {
            String? name;
            if (role == 'admin') {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              name = doc.data()?['name'] as String?;
            }
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(
                  firebaseUser: user,
                  userRole: role,
                  userName: name,
                ),
              ),
            );
          },
        ),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final User? firebaseUser;
  final String? userRole;
  final String? userName;

  const HomePage({super.key, this.firebaseUser, this.userRole, this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSideNavExpanded = true;
  int _selectedIndex = 0;
  String _userId = 'default_user'; // Temporary user ID for testing
  User? _firebaseUser;
  String? _userRole;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _firebaseUser = widget.firebaseUser;
    _userRole = widget.userRole;
    _userName = widget.userName;
    if (_firebaseUser != null) {
      _userId = _firebaseUser!.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Obuyanzi Hymns'),
            if (_userRole == 'admin' && _userName != null) ...[
              const SizedBox(width: 16),
              Text('Admin: $_userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Donate',
            onPressed: () {
              // TODO: Implement donation functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: _isSideNavExpanded,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  _isSideNavExpanded = !_isSideNavExpanded;
                });
              },
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.book),
                label: Text('Hymns'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.favorite),
                label: Text('Favorites'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('Recent'),
              ),
              if (_userRole == 'admin')
                const NavigationRailDestination(
                  icon: Icon(Icons.add),
                  label: Text('Create Hymn'),
                ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              // If admin and last destination, open AdminCreateHymnPage
              if (_userRole == 'admin' && index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminCreateHymnPage(
                      userId: _userId,
                      userRole: _userRole,
                      userName: _userName,
                    ),
                  ),
                );
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Obuyanzi Hymns',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Introduction',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Obuyanzi Hymns is a digital collection of traditional hymns and spiritual songs. '
                'Our mission is to preserve and share these beautiful melodies and lyrics that have '
                'been passed down through generations.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const Text(
                'Objectives',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildObjectiveCard(
                icon: Icons.music_note,
                title: 'Preserve Heritage',
                description: 'Maintain and document traditional hymns for future generations.',
              ),
              const SizedBox(height: 16),
              _buildObjectiveCard(
                icon: Icons.share,
                title: 'Share Knowledge',
                description: 'Make hymns accessible to everyone through our digital platform.',
              ),
              const SizedBox(height: 16),
              _buildObjectiveCard(
                icon: Icons.people,
                title: 'Build Community',
                description: 'Connect people through shared musical heritage and spiritual songs.',
              ),
            ],
          ),
        );
      case 1:
        return HymnsPage(userId: _userId);
      case 2:
        return const Center(child: Text('Favorites Page'));
      case 3:
        return const Center(child: Text('Recent Page'));
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildObjectiveCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final void Function(User user, String role) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user != null) {
        // Fetch user role from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = doc.data()?['role'] ?? 'user';
        widget.onLogin(user, role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful! Welcome, $role.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
