import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/data/models/user_settings.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/settings_repository.dart';
import 'profile_state.dart';

/// Кубит загрузки профиля и статистики обучения пользователя.
class ProfileCubit extends Cubit<ProfileState> {
  final ProgressRepository _progressRepository;
  final AuthRepository _authRepository;
  final SettingsRepository? _settingsRepository;

  StreamSubscription<String>? _cloudUpdatesSub;

  ProfileCubit(
    this._progressRepository,
    this._authRepository, [
    SettingsRepository? settingsRepository,
  ])  : _settingsRepository = settingsRepository ??
            (sl.isRegistered<SettingsRepository>()
                ? sl<SettingsRepository>()
                : null),
        super(const ProfileLoading()) {
    _cloudUpdatesSub = _progressRepository.cloudUpdates.listen((updatedUid) {
      if (isClosed || updatedUid != _authRepository.currentUid) return;
      unawaited(_loadProfileInternal(triggerSync: false));
    });
  }

  /// Загружает статистику, прогресс слов, цели и данные пользователя.
  Future<void> loadProfile() => _loadProfileInternal(triggerSync: true);

  Future<void> _loadProfileInternal({required bool triggerSync}) async {
    try {
      if (state is! ProfileLoaded) {
        emit(const ProfileLoading());
      }

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const ProfileError('Пользователь не авторизован'));
        return;
      }

      var stats = triggerSync
          ? await _progressRepository.loadStats(uid)
          : _progressRepository.getLocalStats(uid);
      final now = DateTime.now();

      // Сбрасываем дневные счётчики при наступлении нового календарного дня.
      final resetStats = SrsEngine.resetDailyCountersIfNeeded(stats, now);
      if (resetStats != stats) {
        stats = resetStats;
        await _progressRepository.updateStats(uid, stats);
      }

      final progressMap = triggerSync
          ? await _progressRepository.loadAllProgress(uid)
          : _progressRepository.getLocalProgress(uid);
      final dueWords = await _progressRepository.getWordsDueForReview(uid);
      final settings = _settingsRepository != null
          ? await _settingsRepository.loadSettings()
          : UserSettings.defaults();

      final masteredCount = progressMap.values
          .where((item) => item.status == WordStatus.mastered)
          .length;
      final totalLearned = masteredCount > stats.totalWordsLearned
          ? masteredCount
          : stats.totalWordsLearned;

      final dueCount = dueWords.isNotEmpty
          ? dueWords.length
          : progressMap.values
              .where((p) => ProgressRepositoryImpl.isWordDueForReview(p, now))
              .length;

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
          dailyGoal: settings.dailyNewWordsGoal,
          dueReviewsCount: dueCount,
        ),
      );
    } catch (e) {
      emit(ProfileError('Ошибка загрузки профиля: $e'));
    }
  }

  /// Сбрасывает состояние профиля при выходе из аккаунта.
  void reset() {
    emit(const ProfileLoading());
  }

  @override
  Future<void> close() async {
    await _cloudUpdatesSub?.cancel();
    return super.close();
  }
}
