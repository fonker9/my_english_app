import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import '../../progress/data/progress_repository.dart';
import '../../progress/data/progress_model.dart';

class AuthCubit extends Cubit<AuthState>{
  // Получаем доступ к инструментам авторизации firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ProgressRepository _progressRepository =
    ProgressRepository();
  
  // В конструкторе базовому классу cubit обязательно отдаем стартовое состояние
  AuthCubit() : super(AuthInitial()) {
  _auth.authStateChanges().listen((user) {
    debugPrint(
      'AUTH STATE CHANGED: ${user?.email} uid=${user?.uid}',
    );
  });
}

  void checkAuth(){
    final user = _auth.currentUser;

    debugPrint('Current user: ${user?.email}');
    debugPrint('UID: ${user?.uid}');

    if (user != null){
      //  Если пользователь найден в системе (т.е он уже логинился с этого устройства) отдаем его uid в состояние успеха
      emit(AuthSuccess(user.uid));
    } else {
      // Если никого нет, оставляем начальное состояние
      emit(AuthInitial());
    }
  }
  // Метод Входа
  Future<void> signIn(String email, String password) async {
    try{
      // Как только вызвали метод, принудительно показываем загрузку
      emit(AuthLoading());

      // Ждем ответа от сервера firebase
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim(),
      );

      await _ensureUserProgress(
        credential.user!.uid,
      );

      emit(AuthSuccess(
        credential.user!.uid,
      ));
    } on FirebaseAuthException catch (e){
      debugPrint('========== SIGN IN ERROR ==========');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('===================================');

      emit(
        AuthFailure(
          'Firebase error: ${e.code}\n${e.message}',
        ),
      );
    } catch (e) {
      emit(AuthFailure('Неизвестная ошибка: $e'));
    }
  }
  // Метод регистрации
  Future<void> signUp(String email, String password, String nickname) async {
    try {
      emit(AuthLoading());

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim(),
      );

      // Сохраняем никнейм в поле displayName в firebase auth
      if (nickname.trim().isNotEmpty){
        await credential.user?.updateDisplayName(nickname.trim());
      }

      await _ensureUserProgress(
        credential.user!.uid,
      );

      emit(AuthSuccess(
        credential.user!.uid,
      ));
    } on FirebaseAuthException catch (e){
      debugPrint('========== SIGN UP ERROR ==========');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('email: ${e.email}');
      debugPrint('credential: ${e.credential}');
      debugPrint('===================================');
      emit(
        AuthFailure(
          'Firebase error: ${e.code}\n${e.message}',
        ),
      );
    } catch (e) {
      emit(AuthFailure('Неизвестная ошибка: $e'));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthInitial()); // Возвращаем экран в начальное состояние
  }

  Future<void> _ensureUserProgress( String uid, ) async {
  final progress =
      await _progressRepository.loadProgress(uid);

  final isEmpty =
      progress.learnedWords.isEmpty &&
      progress.learningWords.isEmpty;

  if (isEmpty) {
    await _progressRepository.saveProgress(
      uid,
      ProgressModel.empty(),
    );

    debugPrint(
      'Created empty progress document',
    );
  } else {
    debugPrint(
      'Progress loaded successfully',
    );
  }
}

}