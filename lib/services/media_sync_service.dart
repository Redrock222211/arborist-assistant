import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import '../models/tree_entry.dart';

class MediaSyncService {
  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<String?> syncImage(String localPath, String siteId, String treeId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final file = File(localPath);
    if (!file.existsSync()) return null;
    final fileName = localPath.split('/').last;
    final ref = _storage.ref().child('tree_photos/${user.uid}/$siteId/$treeId/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    // Store in Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sites')
        .doc(siteId)
        .collection('trees')
        .doc(treeId)
        .set({'imageUrls': FieldValue.arrayUnion([url])}, SetOptions(merge: true));
    return url;
  }

  static Future<String?> syncAudio(String localPath, String siteId, String treeId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final file = File(localPath);
    if (!file.existsSync()) return null;
    final fileName = localPath.split('/').last;
    final ref = _storage.ref().child('voice_notes/${user.uid}/$siteId/$treeId/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    // Store in Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sites')
        .doc(siteId)
        .collection('trees')
        .doc(treeId)
        .set({'voiceAudioUrl': url}, SetOptions(merge: true));
    return url;
  }

  static Future<void> syncAllPending(String siteId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final box = Hive.box<TreeEntry>('tree_entries');
    final entries = box.toMap().entries.where((e) => e.value.siteId == siteId).toList();
    for (final e in entries) {
      final tree = e.value;
      // Sync images
      for (final path in tree.imageLocalPaths) {
        if (!tree.imageUrls.any((url) => url.contains(path.split('/').last))) {
          final url = await syncImage(path, siteId, tree.id);
          if (url != null) {
            final updated = tree.copyWith(
              imageUrls: [...tree.imageUrls, url],
            );
            await box.put(e.key, updated);
          }
        }
      }
      // Sync audio
      if (tree.voiceNoteAudioPath.isNotEmpty && (tree.voiceAudioUrl.isEmpty || !tree.voiceAudioUrl.contains(tree.voiceNoteAudioPath.split('/').last))) {
        final url = await syncAudio(tree.voiceNoteAudioPath, siteId, tree.id);
        if (url != null) {
          final updated = tree.copyWith(voiceAudioUrl: url);
          await box.put(e.key, updated);
        }
      }
    }
  }
}

extension TreeEntryCopyWithMedia on TreeEntry {
  TreeEntry copyWith({List<String>? imageUrls, String? voiceAudioUrl}) {
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
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      imageLocalPaths: imageLocalPaths,
      imageUrls: imageUrls ?? this.imageUrls,
      syncStatus: syncStatus,
    );
  }
}
