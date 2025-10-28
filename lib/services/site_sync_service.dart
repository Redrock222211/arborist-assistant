import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/site.dart';
import 'package:hive/hive.dart';

class SiteSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> syncToCloud(Site site, dynamic localKey) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sites')
          .doc(site.id)
          .set(site.toMap(), SetOptions(merge: true));
      // Mark as synced locally
      final box = Hive.box<Site>('sites');
      final updated = site.copyWith(syncStatus: 'synced');
      await box.put(localKey, updated);
    } catch (e) {
      // Mark as error
      final box = Hive.box<Site>('sites');
      final updated = site.copyWith(syncStatus: 'error');
      await box.put(localKey, updated);
    }
  }

  static Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final box = Hive.box<Site>('sites');
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sites')
        .get();
    for (final doc in snapshot.docs) {
      final site = Site.fromMap(doc.data());
      // Find local key by id
      final localKey = box.keys.firstWhere((k) => box.get(k)?.id == site.id, orElse: () => null);
      if (localKey != null) {
        await box.put(localKey, site.copyWith(syncStatus: 'synced'));
      } else {
        await box.add(site.copyWith(syncStatus: 'synced'));
      }
    }
  }

  static Future<void> syncAll() async {
    final box = Hive.box<Site>('sites');
    final entries = box.toMap().entries.toList();
    for (final e in entries) {
      if (e.value.syncStatus != 'synced') {
        await syncToCloud(e.value, e.key);
      }
    }
    await syncFromCloud();
  }
}

extension SiteCopyWith on Site {
  Site copyWith({String? syncStatus}) {
    return Site(
      id: id,
      name: name,
      address: address,
      notes: notes,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
