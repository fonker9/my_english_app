import 'package:equatable/equatable.dart';

/// Базовое состояние аутентификации.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (пользователь не авторизован).
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Состояние загрузки при выполнении входа или регистрации.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Состояние успешной аутентификации.
class AuthSuccess extends AuthState {
  final String uid;

  const AuthSuccess(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Состояние ошибки аутентификации.
class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}
