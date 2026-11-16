import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_stats.dart';
import '../../models/word_progress.dart';

/// Удалённый источник данных (Cloud Firestore) для прогресса и статистики.
class FirestoreProgressSource {
  static const String _collectionName = 'users_progress';
  static const String _wordsSubcollection = 'words';
  static const int _maxBatchSize = 450;

  final FirebaseFirestore? _customFirestore;

  FirestoreProgressSource({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(_collectionName).doc(uid);

  CollectionReference<Map<String, dynamic>> _wordsCollection(String uid) =>
      _userDoc(uid).collection(_wordsSubcollection);

  /// Загружает прогресс по всем словам пользователя [uid] из Firestore.
  Future<Map<int, WordProgress>> fetchAllProgress(String uid) async {
    final snapshot = await _wordsCollection(uid).get();
    final result = <int, WordProgress>{};

    for (final doc in snapshot.docs) {
      final wordId = int.tryParse(doc.id);
      if (wordId != null) {
        result[wordId] = WordProgress.fromFirestore(wordId, doc.data());
      }
    }

    return result;
  }

  /// Сохраняет прогресс по одному слову в Firestore.
  Future<void> setWordProgress(String uid, WordProgress progress) async {
    await _wordsCollection(uid)
        .doc(progress.wordId.toString())
        .set(progress.toFirestore(), SetOptions(merge: true));
  }

  /// Пакетно сохраняет список записей прогресса слов в Firestore.
  Future<void> setBatchWordProgress(
    String uid,
    List<WordProgress> items,
  ) async {
    if (items.isEmpty) return;

    for (var i = 0; i < items.length; i += _maxBatchSize) {
      final end =
          (i + _maxBatchSize < items.length) ? i + _maxBatchSize : items.length;
      final chunk = items.sublist(i, end);

      final batch = _firestore.batch();
      for (final item in chunk) {
        final ref = _wordsCollection(uid).doc(item.wordId.toString());
        batch.set(ref, item.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  /// Загружает статистику пользователя [uid] из Firestore.
  Future<UserStats?> fetchStats(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['stats'] == null) return null;

    return UserStats.fromFirestore(data['stats'] as Map<String, dynamic>?);
  }

  /// Сохраняет статистику пользователя [uid] в поле `stats` документа Firestore.
  Future<void> setStats(String uid, UserStats stats) async {
    await _userDoc(uid).set(
      {'stats': stats.toFirestore()},
      SetOptions(merge: true),
    );
  }
}
