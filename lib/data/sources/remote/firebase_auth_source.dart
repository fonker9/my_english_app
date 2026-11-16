import 'package:firebase_auth/firebase_auth.dart';

/// Удалённый источник данных для операций Firebase Authentication.
class FirebaseAuthSource {
  final FirebaseAuth? _customAuth;

  FirebaseAuthSource({FirebaseAuth? firebaseAuth})
      : _customAuth = firebaseAuth;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Авторизация по email и паролю. Возвращает `uid` пользователя.
  Future<String> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return credential.user!.uid;
  }

  /// Регистрация нового пользователя и сохранение никнейма. Возвращает `uid`.
  Future<String> signUp(String email, String password, String nickname) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final trimmedNickname = nickname.trim();
    if (trimmedNickname.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmedNickname);
    }

    return credential.user!.uid;
  }

  /// Выход из текущего аккаунта.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Поток изменений состояния авторизации (`uid` или `null`).
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  /// Идентификатор текущего авторизованного пользователя.
  String? get currentUid => _auth.currentUser?.uid;

  /// Никнейм текущего авторизованного пользователя.
  String? get currentDisplayName => _auth.currentUser?.displayName;

  /// Email текущего авторизованного пользователя.
  String? get currentEmail => _auth.currentUser?.email;
}
