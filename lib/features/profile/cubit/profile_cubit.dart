import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'profile_state.dart';

/// Кубит загрузки профиля и статистики обучения пользователя.
class ProfileCubit extends Cubit<ProfileState> {
  final ProgressRepository _progressRepository;
  final AuthRepository _authRepository;

  ProfileCubit(
    this._progressRepository,
    this._authRepository,
  ) : super(const ProfileLoading());

  /// Загружает статистику, прогресс слов, никнейм и email пользователя.
  Future<void> loadProfile() async {
    try {
      emit(const ProfileLoading());

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const ProfileError('Пользователь не авторизован'));
        return;
      }

      final stats = await _progressRepository.loadStats(uid);
      final progressMap = await _progressRepository.loadAllProgress(uid);

      final masteredCount = progressMap.values
          .where((item) => item.status == WordStatus.mastered)
          .length;
      final totalLearned = masteredCount > stats.totalWordsLearned
          ? masteredCount
          : stats.totalWordsLearned;

      final totalAnswers = stats.totalQuizCorrect + stats.totalQuizWrong;
      final accuracyPercent = totalAnswers > 0
          ? ((stats.totalQuizCorrect * 100) / totalAnswers).round()
          : 0;

      final rawName = _authRepository.currentDisplayName;
      final nickname = (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : 'Пользователь';
      final email = _authRepository.currentEmail ?? '';

      emit(
        ProfileLoaded(
          nickname: nickname,
          email: email,
          stats: stats.copyWith(totalWordsLearned: totalLearned),
          accuracyPercent: accuracyPercent,
        ),
      );
    } catch (e) {
      emit(ProfileError('Ошибка загрузки профиля: $e'));
    }
  }
}
