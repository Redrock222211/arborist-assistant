import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:typed_data';
import '../models/user.dart' as app_user;
import '../models/site.dart';
import '../models/tree_entry.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static User? get currentUser => _auth.currentUser;
  static bool get isOnline => _isOnline;
  static bool _isOnline = false;
  
  static Timer? _syncTimer;
  static Timer? _connectivityTimer;
  
  // Collections
  static const String usersCollection = 'users';
  static const String sitesCollection = 'sites';
  static const String treesCollection = 'trees';
  
  /// Initialize Firebase service
  static Future<void> init() async {
    // Listen to connectivity changes
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectivity();
    });
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('User signed in: ${user.email}');
        _startSyncTimer();
      } else {
        print('User signed out');
        _stopSyncTimer();
      }
    });
    
    // Initial connectivity check
    await _checkConnectivity();
  }
  
  /// Check connectivity status
  static Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        print('Connection restored - starting sync');
        await _syncData();
      } else if (wasOnline && !_isOnline) {
        print('Connection lost - stopping sync');
        _stopSyncTimer();
      }
    } catch (e) {
      print('Connectivity check failed: $e');
      _isOnline = false;
    }
  }
  
  /// Start sync timer (every 10 minutes)
  static void _startSyncTimer() {
    _stopSyncTimer();
    _syncTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_isOnline && currentUser != null) {
        _promptForSync();
      }
    });
  }
  
  /// Stop sync timer
  static void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  /// Prompt user for sync
  static void _promptForSync() {
    // This will be called from UI components
    print('Prompting for sync...');
  }
  
  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Sign in failed: $e');
      rethrow;
    }
  }
  
  /// Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('User creation failed: $e');
      rethrow;
    }
    }
  
  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Sync data to Firebase
  static Future<void> _syncData() async {
    if (!_isOnline || currentUser == null) return;
    
    try {
      print('Starting data sync...');
      
      // Sync sites
      await _syncSites();
      
      // Sync trees
      await _syncTrees();
      
      print('Data sync completed');
    } catch (e) {
      print('Data sync failed: $e');
    }
  }
  
  /// Sync sites to Firebase
  static Future<void> _syncSites() async {
    // TODO: Implement site sync logic
    print('Syncing sites...');
  }
  
  /// Sync trees to Firebase
  static Future<void> _syncTrees() async {
    // TODO: Implement tree sync logic
    print('Syncing trees...');
  }
  
  /// Get user data from Firestore
  static Future<app_user.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Failed to get user data: $e');
      return null;
    }
  }
  
  /// Save user data to Firestore
  static Future<void> saveUserData(app_user.User user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id).set(user.toFirestore());
    } catch (e) {
      print('Failed to save user data: $e');
      rethrow;
    }
  }
  
  /// Get sites from Firestore
  static Stream<List<Site>> getSitesStream() {
    if (currentUser == null) return Stream.value([]);
    
    return _firestore
        .collection(sitesCollection)
        .where('userId', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Site.fromFirestore(doc))
            .toList());
  }
  
  /// Save site to Firestore
  static Future<void> saveSite(Site site) async {
    try {
      await _firestore.collection(sitesCollection).doc(site.id).set(site.toFirestore());
    } catch (e) {
      print('Failed to save site: $e');
      rethrow;
    }
  }
  
  /// Get trees from Firestore
  static Stream<List<TreeEntry>> getTreesStream(String siteId) {
    if (currentUser == null) return Stream.value([]);
    
    return _firestore
        .collection(treesCollection)
        .where('siteId', isEqualTo: siteId)
        .where('userId', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TreeEntry.fromFirestore(doc))
            .toList());
  }
  
  /// Save tree to Firestore
  static Future<void> saveTree(TreeEntry tree) async {
    try {
      await _firestore.collection(treesCollection).doc(tree.id).set(tree.toFirestore());
    } catch (e) {
      print('Failed to save tree: $e');
      rethrow;
    }
  }
  
  /// Upload file to Firebase Storage
  static Future<String> uploadFile(String path, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('File upload failed: $e');
      rethrow;
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
  }
}
