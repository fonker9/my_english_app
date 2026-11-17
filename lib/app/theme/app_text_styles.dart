import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Текстовые стили приложения.
class AppTextStyles {
  AppTextStyles._();

  /// Семейства шрифтов из pubspec.yaml.
  static const String fontProstoOne = 'Prosto One';
  static const String fontDaysOne = 'Days One';
  static const String fontSfPro = 'SF Pro Display';

  // --- Заголовки ---

  /// Крупный заголовок экранов авторизации («Вход», «Регистрация»).
  static const TextStyle authTitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Подзаголовок экрана входа («Рады видеть Вас снова!»).
  static const TextStyle authSubtitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 26,
    color: AppColors.primary,
  );

  /// Заголовок экрана («Словарь»).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Заголовок экрана с кнопкой назад («Уровень A1»).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Заголовок приветствия на экране обучения.
  static const TextStyle greetingTitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 20,
    color: AppColors.primary,
  );

  /// Заголовок секции в словаре и подсказка под заголовком авторизации.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Обычный текст в стиле Prosto One (18).
  static const TextStyle prostoBodyLarge = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 18,
    color: AppColors.primary,
  );

  /// Кликабельная ссылка в стиле Prosto One («Зарегистрируйтесь», «Войдите»).
  static const TextStyle authLink = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 18,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  /// Подпись поля ввода и подзаголовок (16, Prosto One).
  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 16,
    color: AppColors.primary,
  );

  /// Подзаголовок экрана словаря.
  static const TextStyle screenSubtitle = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // --- Кнопки и акценты (Days One) ---

  /// Крупная кнопка («Войти»).
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontDaysOne,
    fontSize: 24,
    color: AppColors.background,
  );

  /// Стандартная кнопка («Зарегистрироваться», «Выйти из аккаунта»).
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontDaysOne,
    fontSize: 16,
    color: AppColors.background,
  );

  /// Заголовок карточки уровня и слова в списке словаря.
  static const TextStyle daysOneTitle = TextStyle(
    fontFamily: fontDaysOne,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // --- Карточки обучения и интерфейс (SF Pro Display) ---

  /// Слово на свайп-карточке.
  static const TextStyle flashcardWord = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Бейдж уровня на свайп-карточке.
  static const TextStyle flashcardLevel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Счётчик прогресса за день («Изучено сегодня: ...»).
  static const TextStyle dailyCounter = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
  );

  /// Текст кнопки на карточке обучения («Знаю» / «Учу»).
  static const TextStyle cardActionButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  /// Бейдж уровня в словаре.
  static const TextStyle levelBadge = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  /// Текст ввода в поиске словаря.
  static const TextStyle searchInput = TextStyle(
    fontFamily: fontSfPro,
    color: AppColors.primary,
  );

  /// Подсказка в поиске словаря.
  static const TextStyle searchHint = TextStyle(
    fontFamily: fontSfPro,
    color: AppColors.primaryMuted,
  );

  /// Подсказка в полях авторизации.
  static const TextStyle inputHint = TextStyle(
    color: AppColors.hintText,
  );

  /// Перевод слова в списке словаря.
  static const TextStyle wordTranslation = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 14,
    color: AppColors.subtitleText,
  );

  /// Текст пустого списка в словаре.
  static const TextStyle emptyList = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 14,
    color: AppColors.primaryMuted,
  );

  /// Текст ошибки или пустого экрана.
  static const TextStyle statusMessage = TextStyle(
    fontSize: 18,
    color: AppColors.primary,
  );

  /// Текст завершения сессии обучения.
  static const TextStyle finishedMessage = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );

  /// Сообщение об отсутствии новых слов.
  static const TextStyle emptyLearningMessage = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Выбранная вкладка переключателя («По уровням» / «По темам»).
  static const TextStyle segmentSelected = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.background,
  );

  /// Невыбранная вкладка переключателя («По уровням» / «По темам»).
  static const TextStyle segmentUnselected = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 14,
    color: AppColors.primary,
  );

  /// Мелкая мета-информация карточки (прогресс уровня, часть речи, транскрипция).
  static const TextStyle cardMeta = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 12,
    color: AppColors.subtitleText,
  );

  /// Заголовок карточки статистики в профиле.
  static const TextStyle profileStatLabel = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 14,
    color: AppColors.subtitleText,
  );

  /// Значение статистики в профиле.
  static const TextStyle profileStatValue = TextStyle(
    fontFamily: fontDaysOne,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Крупный заголовок приветствия на главном дашборде.
  static const TextStyle homeGreeting = TextStyle(
    fontFamily: fontProstoOne,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Текст кнопки варианта ответа в квизе.
  static const TextStyle quizOption = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Текст кнопки варианта ответа в квизе на цветном фоне (выбранный).
  static const TextStyle quizOptionSelected = TextStyle(
    fontFamily: fontSfPro,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}
