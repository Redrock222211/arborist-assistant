import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class DrawingSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String?> uploadBackgroundImage(String localPath, String userId, String siteId) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;
      final fileName = localPath.split('/').last;
      final ref = _storage.ref().child('drawings/$userId/$siteId/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<void> syncToCloud(String siteId, Map<String, dynamic> drawingData, String? bgImagePath, dynamic localKey) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String? bgUrl;
    if (bgImagePath != null && bgImagePath.isNotEmpty && !bgImagePath.startsWith('http')) {
      bgUrl = await uploadBackgroundImage(bgImagePath, user.uid, siteId);
      drawingData['bgUrl'] = bgUrl;
    }
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sites')
          .doc(siteId)
          .collection('drawings')
          .doc('main')
          .set(drawingData, SetOptions(merge: true));
      // TODO: Mark as synced locally (if using Hive for drawings)
    } catch (e) {
      // TODO: Mark as error locally
    }
  }

  static Future<Map<String, dynamic>?> syncFromCloud(String siteId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sites')
        .doc(siteId)
        .collection('drawings')
        .doc('main')
        .get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
