import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'pages/hymns_page.dart';
import 'package:obuyanzi_hymns/models/language_preference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/admin_create_hymn_page.dart';
import 'pages/hymn_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'services/hymn_service.dart';
import 'models/hymn.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatefulWidget {
  const SplashApp({super.key});
  @override
  State<SplashApp> createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> with SingleTickerProviderStateMixin {
  double _progress = 0;
  bool _initialized = false;
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    _startTime = DateTime.now();
    _startInit();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _startInit() async {
    // Simulate progress
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() {
        _progress = i / 10.0;
      });
    }
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
    // Ensure splash is visible for at least 1.5 seconds
    final elapsed = DateTime.now().difference(_startTime);
    if (elapsed < const Duration(milliseconds: 1500)) {
      await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
    }
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const ObuyanziHymnsApp();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2D1B0E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icons/Icon-512.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Obuyanzi Hymns',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.95),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFD4AF37),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ObuyanziHymnsApp extends StatefulWidget {
  const ObuyanziHymnsApp({super.key});

  @override
  State<ObuyanziHymnsApp> createState() => _ObuyanziHymnsAppState();
}

class _ObuyanziHymnsAppState extends State<ObuyanziHymnsApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        _themeMode = ThemeMode.light;
      } else if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Obuyanzi Hymns',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C), // warm brown
          brightness: Brightness.light,
          primary: const Color(0xFF8B5E3C),
          secondary: const Color(0xFFD4AF37), // gold
          background: const Color(0xFFFFF8E1), // cream
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
          brightness: Brightness.dark,
          primary: const Color(0xFFD4AF37), // gold as highlight
          secondary: const Color(0xFF8B5E3C), // brown as accent
          background: const Color(0xFF2D1B0E), // dark brown
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode,
      home: HomePageWithThemeToggle(onToggleTheme: _toggleThemeMode, themeMode: _themeMode),
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
                  onToggleTheme: _toggleThemeMode,
                  themeMode: _themeMode,
                ),
              ),
            );
          },
        ),
      },
    );
  }
}

class HomePageWithThemeToggle extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const HomePageWithThemeToggle({super.key, required this.onToggleTheme, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return HomePage(
      onToggleTheme: onToggleTheme,
      themeMode: themeMode,
    );
  }
}

class HomePage extends StatefulWidget {
  final User? firebaseUser;
  final String? userRole;
  final String? userName;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomePage({
    super.key,
    this.firebaseUser,
    this.userRole,
    this.userName,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isSideNavExpanded = true;
  int _selectedIndex = 0;
  String? _userId;
  User? _firebaseUser;
  String? _userRole;
  String? _userName;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Hymn> _allHymns = [];
  List<Hymn> _suggestions = [];
  bool _isSearching = false;
  final HymnService _hymnService = HymnService();

  @override
  void initState() {
    super.initState();
    _firebaseUser = widget.firebaseUser;
    _userRole = widget.userRole;
    _userName = widget.userName;
    if (_firebaseUser != null) {
      _userId = _firebaseUser!.uid;
    }
    // Initialize page transition animation
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    );
    // Start the animation so the first page is visible
    _pageController.value = 1.0;
    // Load all hymns for instant search
    _hymnService.getHymns().listen((hymns) {
      setState(() {
        _allHymns = hymns;
      });
      print('Loaded hymns: ${_allHymns.length}');
    });
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.forward(from: 0.0);
    }
  }

  void _onSearchFocusChanged() {
    // No overlay logic needed
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    print('Search changed: "$query"');
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final localResults = _allHymns.where((hymn) {
      final match = hymn.number.toLowerCase().contains(query.toLowerCase()) ||
          hymn.titleLuhya.toLowerCase().contains(query.toLowerCase()) ||
          (hymn.titleEnglish?.toLowerCase().contains(query.toLowerCase()) ?? false);
      if (match) print('Local match: ${hymn.number} - ${hymn.titleLuhya}');
      return match;
    }).toList();
    setState(() {
      _suggestions = localResults;
    });
    // No overlay logic needed
  }

  void _onSuggestionTap(Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HymnDetailPage(
          hymnId: hymn.id,
          userId: _userId ?? '',
          onToggleTheme: widget.onToggleTheme,
          themeMode: widget.themeMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _isSideNavExpanded = !_isSideNavExpanded;
              });
              if (MediaQuery.of(context).size.width <= 900) {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            double searchWidth = 300;
            bool showSpacers = true;
            bool isMobile = constraints.maxWidth < 600;
            if (constraints.maxWidth < 500) {
              searchWidth = constraints.maxWidth * 0.9;
              showSpacers = false;
            } else if (constraints.maxWidth < 900) {
              searchWidth = 220;
            }
            return Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _navigateToPage(0);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          if (kIsWeb)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                'icons/logo.png',
                                height: 32,
                              ),
                            ),
                          const Text('Obuyanzi Hymns'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isMobile && showSpacers) const Spacer(),
                if (!isMobile)
                  Flexible(
                    child: SizedBox(
                      width: searchWidth,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search hymns...',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final result = await showDialog<Hymn>(
                            context: context,
                            builder: (context) => _SearchDialog(
                              allHymns: _allHymns,
                              onHymnTap: (hymn) {
                                Navigator.pop(context, hymn);
                              },
                            ),
                          );
                          if (result != null) {
                            _onSuggestionTap(result);
                          }
                        },
                      ),
                    ),
                  ),
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: () async {
                      final result = await showDialog<Hymn>(
                        context: context,
                        builder: (context) => _SearchDialog(
                          allHymns: _allHymns,
                          onHymnTap: (hymn) {
                            Navigator.pop(context, hymn);
                          },
                        ),
                      );
                      if (result != null) {
                        _onSuggestionTap(result);
                      }
                    },
                  ),
                if (!isMobile && showSpacers) const Spacer(),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.system
                  ? Icons.brightness_auto
                  : widget.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
            ),
            tooltip: widget.themeMode == ThemeMode.system
                ? 'System Theme'
                : widget.themeMode == ThemeMode.light
                    ? 'Light Theme'
                    : 'Dark Theme',
            onPressed: widget.onToggleTheme,
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
      drawer: MediaQuery.of(context).size.width <= 900
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _navigateToPage(0);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (kIsWeb)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.network(
                                    'icons/logo.png',
                                    height: 32,
                                  ),
                                ),
                              const Text('Obuyanzi Hymns', style: TextStyle(color: Colors.white, fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    selected: _selectedIndex == 0,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _navigateToPage(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Hymns'),
                    selected: _selectedIndex == 1,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _navigateToPage(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Favorites'),
                    selected: _selectedIndex == 2,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _navigateToPage(2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Recent'),
                    selected: _selectedIndex == 3,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _navigateToPage(3);
                      Navigator.pop(context);
                    },
                  ),
                  if (_userRole == 'admin')
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Create Hymn'),
                      selected: _selectedIndex == 4,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        _navigateToPage(4);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;
          return Row(
        children: [
              if (isLargeScreen)
          NavigationRail(
            extended: _isSideNavExpanded,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _navigateToPage,
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
          ),
              // Main content with animation
          Expanded(
                child: FadeTransition(
                  opacity: _pageAnimation,
                  child: _buildMainContent(isLargeScreen),
                ),
          ),
        ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(bool isLargeScreen) {
    if (_selectedIndex == 0) {
      // Landing page layout
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: isLargeScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WelcomeSection(userName: _userName),
                                const SizedBox(height: 24),
                                _ObjectivesSection(),
                                const SizedBox(height: 24),
                                _HymnPreviewCarousel(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right Column
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TodaysHymnSection(),
                                const SizedBox(height: 24),
                                _StatsCTASection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WelcomeSection(userName: _userName),
                          const SizedBox(height: 24),
                          _TodaysHymnSection(),
                          const SizedBox(height: 24),
                          _ObjectivesSection(),
                          const SizedBox(height: 24),
                          _StatsCTASection(),
                          const SizedBox(height: 24),
                          _HymnPreviewCarousel(),
                        ],
                      ),
              ),
            ),
          ),
          const _FooterSection(),
        ],
      );
    } else {
      // Other pages
      return _buildPageContent();
    }
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
        return HymnsPage(
          userId: _userId ?? '',
          onToggleTheme: widget.onToggleTheme,
          themeMode: widget.themeMode,
        );
      case 2:
        return const Center(child: Text('Favorites Page'));
      case 3:
        return const Center(child: Text('Recent Page'));
      case 4:
        if (_userRole == 'admin') {
          return AdminCreateHymnPage(
            userId: _userId ?? '',
            userRole: _userRole,
            userName: _userName,
            showAppBar: false,
            onToggleTheme: widget.onToggleTheme,
            themeMode: widget.themeMode,
          );
        }
        return const Center(child: Text('Access denied. Admins only.'));
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

class _WelcomeSection extends StatelessWidget {
  final String? userName;
  const _WelcomeSection({this.userName});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${userName != null ? ', $userName' : ''}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Obuyanzi Hymns is a digital collection of traditional hymns and spiritual songs.\nOur mission is to preserve and share these beautiful melodies and lyrics that have been passed down through generations.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectivesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objectives', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ObjectiveCard(
              icon: Icons.music_note,
              title: 'Preserve Heritage',
              description: 'Maintain and document traditional hymns for future generations.',
            ),
            _ObjectiveCard(
              icon: Icons.share,
              title: 'Share Knowledge',
              description: 'Make hymns accessible to everyone through our digital platform.',
            ),
            _ObjectiveCard(
              icon: Icons.people,
              title: 'Build Community',
              description: 'Connect people through shared musical heritage and spiritual songs.',
            ),
          ],
        ),
      ],
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _ObjectiveCard({required this.icon, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
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

class _TodaysHymnSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Hymn No. C150', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              'Obulalilo bwa Nyasaye',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('The Grace of God', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('Theme: Grace Salvation'),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Read Translation'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'In Loving Memory of\nMama Ruth Milenja Okwomi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'A dedicated church member and choir singer, Mama Ruth was passionate about preserving Luhya cultural heritage.',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCTASection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stats & Call to Action', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  children: const [
                    Text('150+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Hymns'),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  children: const [
                    Text('20+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Themes'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Contribute a Hymn'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HymnPreviewCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 180,
        child: Center(
          child: Text('Hymn Preview Carousel (Coming Soon)', style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Text('Obuyanzi Hymns © 2025'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HoverLink(
                text: 'www.mwando.co.ke',
                url: 'https://www.mwando.co.ke',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 16),
              _HoverLink(
                text: 'hello@mwando.co.ke',
                url: 'mailto:hello@mwando.co.ke',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIconLink(
                icon: FontAwesomeIcons.linkedin,
                url: 'https://ke.linkedin.com/in/mwandotheboss',
                tooltip: 'LinkedIn',
              ),
              const SizedBox(width: 12),
              _SocialIconLink(
                icon: FontAwesomeIcons.facebook,
                url: 'https://www.facebook.com/mwandotheboss/',
                tooltip: 'Facebook',
              ),
              const SizedBox(width: 12),
              _SocialIconLink(
                icon: FontAwesomeIcons.instagram,
                url: 'https://www.instagram.com/mwandotheboss/',
                tooltip: 'Instagram',
              ),
              const SizedBox(width: 12),
              _SocialIconLink(
                icon: FontAwesomeIcons.tiktok,
                url: 'https://www.tiktok.com/@mwandotheboss',
                tooltip: 'TikTok',
              ),
              const SizedBox(width: 12),
              _SocialIconLink(
                icon: FontAwesomeIcons.xTwitter,
                url: 'https://twitter.com/mwandotheboss',
                tooltip: 'X (Twitter)',
              ),
              const SizedBox(width: 16),
              const Text('Social: @mwandotheboss', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoverLink extends StatefulWidget {
  final String text;
  final String url;
  final TextStyle? style;
  const _HoverLink({required this.text, required this.url, this.style});
  @override
  State<_HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<_HoverLink> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    final color = _hovering ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () async {
          if (widget.url.startsWith('mailto:')) {
            await launchUrl(
              Uri.parse(widget.url),
              webOnlyWindowName: '_blank',
            );
          } else {
            await launchUrl(
              Uri.parse(widget.url),
              mode: LaunchMode.externalApplication,
              webOnlyWindowName: '_blank',
            );
          }
        },
        child: Text(
          widget.text,
          style: widget.style?.copyWith(
            color: color,
            decoration: TextDecoration.underline,
          ) ?? TextStyle(
            color: color,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _SocialIconLink extends StatelessWidget {
  final IconData icon;
  final String url;
  final String tooltip;
  const _SocialIconLink({required this.icon, required this.url, required this.tooltip});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FaIcon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final List<Hymn> allHymns;
  final void Function(Hymn) onHymnTap;
  const _SearchDialog({required this.allHymns, required this.onHymnTap});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Hymn> _suggestions = [];

  void _onChanged() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = widget.allHymns.where((hymn) {
        return hymn.number.toLowerCase().contains(query) ||
            hymn.titleLuhya.toLowerCase().contains(query) ||
            (hymn.titleEnglish?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.7;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = isMobile ? double.infinity : 600.0;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : (MediaQuery.of(context).size.width - dialogWidth) / 2,
        vertical: isMobile ? 0 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search hymns...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_suggestions.isEmpty && _controller.text.isNotEmpty)
              const Text('No results found', style: TextStyle(color: Colors.grey)),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final hymn = _suggestions[index];
                      return ListTile(
                        title: Text('Hymn ${hymn.number}: ${hymn.titleLuhya}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: hymn.titleEnglish != null ? Text(hymn.titleEnglish!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                        onTap: () => Navigator.pop(context, hymn),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
