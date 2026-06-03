import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';


class AuthCubit extends Cubit<AuthState>{
  // Получаем доступ к инструментам авторизации firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // В конструкторе базовому классу cubit обязательно отдаем стартовое состояние
  AuthCubit() : super(AuthInitial());

  void checkAuth(){
    final user = _auth.currentUser;
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

      emit(AuthSuccess(credential.user!.uid));
    } on FirebaseAuthException catch (e){
      // Если случилась специфическая ошибка firebase 
      emit(AuthFailure(e.message ?? 'Произошла ошибка при входе.'));
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

      emit(AuthSuccess(credential.user!.uid));
    } on FirebaseAuthException catch (e){
      emit(AuthFailure(e.message ?? 'Произошла ошибка при регистрации.'));
    } catch (e) {
      emit(AuthFailure('Неизвестная ошибка: $e'));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthInitial()); // Возвращаем экран в начальное состояние
  }

}