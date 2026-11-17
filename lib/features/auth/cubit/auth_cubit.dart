import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';

/// Кубит управления аутентификацией пользователя через [AuthRepository].
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  /// Проверяет текущую сессию пользователя при старте приложения.
  void checkAuth() {
    final uid = _authRepository.currentUid;
    debugPrint('Проверка авторизации, uid=$uid');

    if (uid != null) {
      emit(AuthSuccess(uid));
    } else {
      emit(const AuthInitial());
    }
  }

  /// Выполняет вход по email и паролю.
  Future<void> signIn(String email, String password) async {
    try {
      emit(const AuthLoading());
      final uid = await _authRepository.signIn(email, password);
      emit(AuthSuccess(uid));
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка входа Firebase: ${e.code} / ${e.message}');
      emit(AuthFailure('Firebase error: ${e.code}\n${e.message}'));
    } catch (e) {
      emit(AuthFailure('Неизвестная ошибка: $e'));
    }
  }

  /// Регистрирует нового пользователя с никнеймом.
  Future<void> signUp(String email, String password, String nickname) async {
    try {
      emit(const AuthLoading());
      final uid = await _authRepository.signUp(email, password, nickname);
      emit(AuthSuccess(uid));
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка регистрации Firebase: ${e.code} / ${e.message}');
      emit(AuthFailure('Firebase error: ${e.code}\n${e.message}'));
    } catch (e) {
      emit(AuthFailure('Неизвестная ошибка: $e'));
    }
  }

  /// Выполняет выход из текущего аккаунта.
  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AuthInitial());
  }
}
