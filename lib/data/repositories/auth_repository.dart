import '../sources/remote/firebase_auth_source.dart';

/// Репозиторий аутентификации пользователя.
abstract class AuthRepository {
  /// Вход по email и паролю. Возвращает `uid`.
  Future<String> signIn(String email, String password);

  /// Регистрация нового пользователя. Возвращает `uid`.
  Future<String> signUp(String email, String password, String nickname);

  /// Выход из аккаунта.
  Future<void> signOut();

  /// Поток изменений авторизации (`uid` или `null`).
  Stream<String?> authStateChanges();

  /// Идентификатор текущего пользователя.
  String? get currentUid;

  /// Никнейм текущего пользователя.
  String? get currentDisplayName;

  /// Email текущего пользователя.
  String? get currentEmail;
}

/// Реализация [AuthRepository] поверх [FirebaseAuthSource].
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthSource _authSource;

  AuthRepositoryImpl(this._authSource);

  @override
  Future<String> signIn(String email, String password) {
    return _authSource.signIn(email, password);
  }

  @override
  Future<String> signUp(String email, String password, String nickname) {
    return _authSource.signUp(email, password, nickname);
  }

  @override
  Future<void> signOut() {
    return _authSource.signOut();
  }

  @override
  Stream<String?> authStateChanges() {
    return _authSource.authStateChanges();
  }

  @override
  String? get currentUid => _authSource.currentUid;

  @override
  String? get currentDisplayName => _authSource.currentDisplayName;

  @override
  String? get currentEmail => _authSource.currentEmail;
}
