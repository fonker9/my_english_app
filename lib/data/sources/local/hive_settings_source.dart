import 'package:hive/hive.dart';
import '../../models/user_settings.dart';

/// Локальный источник данных (Hive) для настроек пользователя.
class HiveSettingsSource {
  static const String userSettingsBoxName = 'user_settings';
  static const String _settingsKey = 'default';

  final Box<UserSettings>? _customBox;

  HiveSettingsSource({Box<UserSettings>? box}) : _customBox = box;

  Box<UserSettings> get _box =>
      _customBox ?? Hive.box<UserSettings>(userSettingsBoxName);

  /// Читает текущие настройки из Hive или возвращает значения по умолчанию.
  UserSettings getSettings() {
    return _box.get(_settingsKey) ?? UserSettings.defaults();
  }

  /// Сохраняет настройки в Hive.
  Future<void> saveSettings(UserSettings settings) async {
    await _box.put(_settingsKey, settings);
  }
}
