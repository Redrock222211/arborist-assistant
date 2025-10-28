import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'pages/map_page.dart';
import 'pages/tree_list_page.dart';
// Drawing feature removed - import 'pages/simple_drawing_page_minimal.dart';
import 'pages/site_files_page.dart';
import 'pages/export_sync_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/user_management_page.dart';
import 'pages/login_page.dart';
import 'pages/loading_screen.dart';
import 'pages/dashboard_page.dart';
import 'services/site_storage_service.dart';
import 'services/tree_storage_service.dart';
import 'services/app_state_service.dart';
import 'services/auth_service.dart';
import 'services/branding_service.dart';
import 'services/firebase_service.dart';
import 'services/site_file_service.dart';
import 'services/drawing_storage_service.dart';
import 'services/planning_ai_service.dart';
// Removed unused import
import 'widgets/app_logo.dart';
import 'models/site.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Initialize Crashlytics and Analytics
    if (!kIsWeb) {
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      
      print('Crashlytics initialized');
    }
    
    // Initialize Analytics
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    print('Analytics initialized');
    
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('This will prevent Firebase authentication from working');
    // Continue without Firebase for now
  }
  
  await SiteStorageService.init();
  await TreeStorageService.init();
  await AppStateService.init();
  await BrandingService.init();
  await AuthService.init();
  await FirebaseService.init();
  await SiteFileService.init();
  await DrawingStorageService.init();
  
  // Initialize Hive boxes for app settings
  await Hive.openBox('app_settings');
  runApp(const ArboristAssistantApp());
}

class ArboristAssistantApp extends StatelessWidget {
  const ArboristAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arborist Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      onUnknownRoute: (settings) {
        // Handle unknown routes by redirecting to home
        return MaterialPageRoute(
          builder: (context) => const AppInitializer(),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate loading time for services
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }
    return const AuthGate();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final firebaseUser = snapshot.data;
        
        if (firebaseUser == null) {
          return const LoginPage();
        }
        
        return const AppWithAuth();
      },
    );
  }
}

class AppWithAuth extends StatelessWidget {
  const AppWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return ArboristMainApp();
  }
}

class ArboristMainApp extends StatefulWidget {
  const ArboristMainApp({super.key});

  @override
  State<ArboristMainApp> createState() => _ArboristMainAppState();
}

class _ArboristMainAppState extends State<ArboristMainApp> {
  Site? _selectedSite;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadLastSite();
  }

  void _loadLastSite() {
    final lastSite = AppStateService.getLastSite();
    if (lastSite != null) {
      setState(() {
        _selectedSite = lastSite;
      });
    }
  }

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _logout() async {
    await AuthService.logout();
    // The AuthGate will automatically redirect to login page
    // when Firebase auth state changes
  }

  @override
  Widget build(BuildContext context) {
    final pages = _selectedSite != null ? [
      const DashboardPage(),
      MapPage(site: _selectedSite!),
      TreeListPage(site: _selectedSite!),
      SiteFilesPage(site: _selectedSite!),
      ExportSyncPage(site: _selectedSite!),
    ] : [
      const DashboardPage(),
      const Center(child: Text('Select a site to view map')),
      const Center(child: Text('Select a site to view trees')),
      const Center(child: Text('Select a site to access files')),
      const Center(child: Text('Select a site to export data')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Arborist Assistant - ${_selectedSite?.name ?? "No Site"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Change Site',
            onPressed: () => setState(() => _selectedSite = null),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(
                    size: 60,
                    showText: false,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text('Arb Assistant', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Professional Tree Management', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedSite = null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _openProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            if (AuthService.getCurrentUser()?.role == 'admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserManagementPage()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: const Text('For support, contact your admin or visit the Arborist Assistant website.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Tree List',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: 'Files',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sync),
                  label: 'Export/Sync',
                ),
              ],
              currentIndex: _selectedTab,
              selectedItemColor: Colors.green[700],
              onTap: (index) => setState(() => _selectedTab = index),
              type: BottomNavigationBarType.fixed,
            ),
    );
  }
}

// Pages are imported from their respective files
