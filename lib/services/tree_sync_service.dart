import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tree_entry.dart';
import 'package:hive/hive.dart';

class TreeSyncService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> syncToCloud(TreeEntry entry, String siteId, dynamic localKey) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sites')
          .doc(siteId)
          .collection('trees')
          .doc(entry.id)
          .set(entry.toMap(), SetOptions(merge: true));
      // Mark as synced locally
      final box = Hive.box<TreeEntry>('tree_entries');
      final updated = TreeEntry(
        // ... all fields copied from entry ...
        id: entry.id,
        species: entry.species,
        dsh: entry.dsh,
        height: entry.height,
        condition: entry.condition,
        comments: entry.comments,
        permitRequired: entry.permitRequired,
        latitude: entry.latitude,
        longitude: entry.longitude,
        srz: entry.srz,
        nrz: entry.nrz,
        ageClass: entry.ageClass,
        retentionValue: entry.retentionValue,
        riskRating: entry.riskRating,
        locationDescription: entry.locationDescription,
        habitatValue: entry.habitatValue,
        recommendedWorks: entry.recommendedWorks,
        healthForm: entry.healthForm,
        diseasesPresent: entry.diseasesPresent,
        canopySpread: entry.canopySpread,
        clearanceToStructures: entry.clearanceToStructures,
        origin: entry.origin,
        // significance: entry.significance, // Removed field
        pastManagement: entry.pastManagement,
        pestPresence: entry.pestPresence,
        notes: entry.notes,
        // retentionJustification: entry.retentionJustification, // Removed field
        // removalJustification: entry.removalJustification, // Removed field
        // treeTag: entry.treeTag, // Removed field
        siteId: entry.siteId,
        targetOccupancy: entry.targetOccupancy,
        defectsObserved: entry.defectsObserved,
        likelihoodOfFailure: entry.likelihoodOfFailure,
        likelihoodOfImpact: entry.likelihoodOfImpact,
        consequenceOfFailure: entry.consequenceOfFailure,
        overallRiskRating: entry.overallRiskRating,
        vtaNotes: entry.vtaNotes,
        vtaDefects: entry.vtaDefects,
        inspectionDate: entry.inspectionDate,
        inspectorName: entry.inspectorName,
        voiceNotes: entry.voiceNotes,
        voiceNoteAudioPath: entry.voiceNoteAudioPath,
        voiceAudioUrl: entry.voiceAudioUrl,
        imageLocalPaths: entry.imageLocalPaths,
        imageUrls: entry.imageUrls,
        syncStatus: 'synced',
      );
      await box.put(localKey, updated);
    } catch (e) {
      // Mark as error
      final box = Hive.box<TreeEntry>('tree_entries');
      final updated = entry.copyWith(syncStatus: 'error');
      await box.put(localKey, updated);
    }
  }

  static Future<void> syncFromCloud(String siteId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final box = Hive.box<TreeEntry>('tree_entries');
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sites')
        .doc(siteId)
        .collection('trees')
        .get();
    for (final doc in snapshot.docs) {
      final entry = TreeEntry.fromMap(doc.data());
      // Find local key by id
      final localKey = box.keys.firstWhere((k) => box.get(k)?.id == entry.id, orElse: () => null);
      if (localKey != null) {
        await box.put(localKey, entry.copyWith(syncStatus: 'synced'));
      } else {
        await box.add(entry.copyWith(syncStatus: 'synced'));
      }
    }
  }

  static Future<void> syncAll(String siteId) async {
    final box = Hive.box<TreeEntry>('tree_entries');
    final entries = box.toMap().entries.where((e) => e.value.siteId == siteId).toList();
    for (final e in entries) {
      if (e.value.syncStatus != 'synced') {
        await syncToCloud(e.value, siteId, e.key);
      }
    }
    await syncFromCloud(siteId);
  }
}

extension TreeEntryCopyWith on TreeEntry {
  TreeEntry copyWith({String? syncStatus}) {
    return TreeEntry(
      // ... all fields ...
      id: id,
      species: species,
      dsh: dsh,
      height: height,
      condition: condition,
      comments: comments,
      permitRequired: permitRequired,
      latitude: latitude,
      longitude: longitude,
      srz: srz,
      nrz: nrz,
      ageClass: ageClass,
      retentionValue: retentionValue,
      riskRating: riskRating,
      locationDescription: locationDescription,
      habitatValue: habitatValue,
      recommendedWorks: recommendedWorks,
      healthForm: healthForm,
      diseasesPresent: diseasesPresent,
      canopySpread: canopySpread,
      clearanceToStructures: clearanceToStructures,
      origin: origin,
      // significance: significance, // Removed field
      pastManagement: pastManagement,
      pestPresence: pestPresence,
      notes: notes,
      // retentionJustification: retentionJustification, // Removed field
      // removalJustification: removalJustification, // Removed field
      // treeTag: treeTag, // Removed field
      siteId: siteId,
      targetOccupancy: targetOccupancy,
      defectsObserved: defectsObserved,
      likelihoodOfFailure: likelihoodOfFailure,
      likelihoodOfImpact: likelihoodOfImpact,
      consequenceOfFailure: consequenceOfFailure,
      overallRiskRating: overallRiskRating,
      vtaNotes: vtaNotes,
      vtaDefects: vtaDefects,
      inspectionDate: inspectionDate,
      inspectorName: inspectorName,
      voiceNotes: voiceNotes,
      voiceNoteAudioPath: voiceNoteAudioPath,
      voiceAudioUrl: voiceAudioUrl,
      imageLocalPaths: imageLocalPaths,
      imageUrls: imageUrls,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
