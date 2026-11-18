import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'dictionary_state.dart';

/// Кубит управления словарём: загрузка слов, прогресса и фильтрация по уровням/темам.
class DictionaryCubit extends Cubit<DictionaryState> {
  static const List<String> cefrLevels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;
  final AuthRepository _authRepository;

  StreamSubscription<String>? _cloudUpdatesSub;
  String? _pendingLevel;
  String? _pendingTopic;

  DictionaryCubit(
    this._wordsRepository,
    this._progressRepository, [
    AuthRepository? authRepository,
  ])  : _authRepository = authRepository ?? sl<AuthRepository>(),
        super(const DictionaryLoading()) {
    _cloudUpdatesSub = _progressRepository.cloudUpdates.listen((updatedUid) {
      if (isClosed || updatedUid != _authRepository.currentUid) return;
      if (state is DictionaryLoaded) {
        final currentState = state as DictionaryLoaded;
        final updatedProgress = Map<int, WordProgress>.from(
          _progressRepository.getLocalProgress(updatedUid),
        );
        emit(currentState.copyWith(progressMap: updatedProgress));
      }
    });
  }

  /// Загружает слова из assets, список тем и прогресс текущего пользователя.
  Future<void> loadWords() async {
    try {
      emit(const DictionaryLoading());

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const DictionaryError('Пользователь не авторизован'));
        return;
      }

      final words = await _wordsRepository.getAllWords();
      final topics = _wordsRepository.getAvailableTopics();
      final progressMap = await _progressRepository.loadAllProgress(uid);

      emit(
        DictionaryLoaded(
          allWords: words,
          progressMap: progressMap,
          availableTopics: topics,
          selectedLevel: _pendingLevel,
          selectedTopic: _pendingTopic,
        ),
      );
    } catch (e) {
      emit(DictionaryError('Ошибка загрузки словаря: $e'));
    }
  }

  /// Обновляет прогресс слов при возврате на экран словаря.
  Future<void> refreshWords() async {
    if (state is! DictionaryLoaded) {
      await loadWords();
      return;
    }

    final currentState = state as DictionaryLoaded;
    try {
      final uid = _authRepository.currentUid;
      if (uid == null) return;

      final progressMap = await _progressRepository.loadAllProgress(uid);
      emit(currentState.copyWith(progressMap: progressMap));
    } catch (e) {
      emit(DictionaryError('Ошибка обновления словаря: $e'));
    }
  }

  /// Переключает режим отображения словаря («По уровням» / «По темам»).
  void setFilterMode(DictionaryFilterMode mode) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(filterMode: mode));
    }
  }

  /// Выбирает уровень (A1–C2) для просмотра слов (работает и до завершения загрузки).
  void selectLevel(String level) {
    _pendingLevel = level;
    _pendingTopic = null;

    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(
        currentState.copyWith(
          selectedLevel: level,
          selectedTopic: null,
          searchQuery: '',
        ),
      );
    }
  }

  /// Выбирает тему для просмотра слов (работает и до завершения загрузки).
  void selectTopic(String topic) {
    _pendingLevel = null;
    _pendingTopic = topic;

    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(
        currentState.copyWith(
          selectedLevel: null,
          selectedTopic: topic,
          searchQuery: '',
        ),
      );
    }
  }

  /// Определяет по строковому параметру маршрута, это уровень или тема, и применяет фильтр.
  void selectCategory(String category) {
    final normalized = category.trim().toLowerCase();
    if (cefrLevels.contains(normalized)) {
      selectLevel(normalized.toUpperCase());
    } else {
      selectTopic(category);
    }
  }

  /// Фильтрует слова в выбранном уровне/теме по строке поиска.
  void searchWords(String query) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  /// Сбрасывает состояние кубита при выходе из аккаунта.
  void reset() {
    _pendingLevel = null;
    _pendingTopic = null;
    emit(const DictionaryLoading());
  }

  @override
  Future<void> close() async {
    await _cloudUpdatesSub?.cancel();
    return super.close();
  }
}
