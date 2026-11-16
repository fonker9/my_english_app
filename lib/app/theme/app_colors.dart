import 'package:flutter/material.dart';

/// Палитра цветов приложения.
class AppColors {
  AppColors._();

  /// Основной фон экранов (кремовый).
  static const Color background = Color(0xFFFFFAE9);

  /// Основной акцентный цвет (бордовый).
  static const Color primary = Color(0xFFA43032);

  /// Полупрозрачный основной цвет (подсказки поиска, пустые списки).
  static const Color primaryMuted = Color(0x88A43032);

  /// Вторичный акцентный цвет (оливково-зелёный: активные элементы, кнопка «Учу»).
  static const Color secondary = Color(0xFF828700);

  /// Поверхность карточек, полей ввода и нижней панели (песочный).
  static const Color surface = Color(0xFFF2D9A4);

  /// Цвет текста подсказок в полях ввода.
  static const Color hintText = Color(0xFF7B7A7A);

  /// Цвет второстепенного текста (переводы слов в словаре).
  static const Color subtitleText = Color(0xFF5A1E20);

  /// Цвет карточки свайпа по умолчанию.
  static const Color cardDefault = Color(0xFFD2E5C5);

  /// Цвет карточки при свайпе вправо («Учу»).
  static const Color cardSwipeRight = Color(0xFFB4B55D);

  /// Цвет карточки при свайпе влево («Знаю»).
  static const Color cardSwipeLeft = Color(0xFFC8817B);

  /// Белый цвет для текста на цветных кнопках и бейджах.
  static const Color white = Colors.white;

  /// Базовый цвет тени.
  static const Color shadow = Colors.black;

  /// Цвета бейджей уровней английского языка (CEFR).
  static const Color levelA1 = Color(0xFF04826B);
  static const Color levelA2 = Color(0xFF4B7C0C);
  static const Color levelB1 = Color(0xFFA48C0E);
  static const Color levelB2 = Color(0xFFA44D0E);
  static const Color levelC1 = Color(0xFFDC401D);
  static const Color levelC2 = Color(0xFFDC1D62);

  /// Возвращает цвет бейджа по названию уровня (A1–C2).
  static Color levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return levelA1;
      case 'A2':
        return levelA2;
      case 'B1':
        return levelB1;
      case 'B2':
        return levelB2;
      case 'C1':
        return levelC1;
      case 'C2':
        return levelC2;
      default:
        return primary;
    }
  }
}
