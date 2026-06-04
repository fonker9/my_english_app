import 'package:cloud_firestore/cloud_firestore.dart';

import 'progress_model.dart';

class ProgressRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<ProgressModel> loadProgress(
    String uid,
  ) async {
    final doc = await _firestore
        .collection('users_progress')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return ProgressModel.empty();
    }

    return ProgressModel.fromFirestore(
      doc.data(),
    );
  }

  Future<void> saveProgress(
    String uid,
    ProgressModel progress,
  ) async {
    await _firestore
        .collection('users_progress')
        .doc(uid)
        .set(
          progress.toFirestore(),
          SetOptions(merge: true),
        );
  }
}